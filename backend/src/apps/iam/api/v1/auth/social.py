"""Social OAuth2 login endpoints — thin router, all logic delegated to utils and config."""
from datetime import datetime, timedelta, timezone
from typing import Any, Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.responses import RedirectResponse
from jose import jwt
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from urllib.parse import urlencode

from src.apps.core import security
from src.apps.core.config import OAUTH_PROVIDERS, settings
from src.apps.core.security import TokenType
from src.apps.core.analytics import analytics
from src.apps.iam.api.deps import get_db
from src.apps.iam.models.token_tracking import TokenTracking
from src.apps.iam.schemas.token import Token
from src.apps.iam.utils.ip_access import revoke_tokens_for_ip, get_client_ip
from src.apps.iam.utils.social import (
    extract_user_info,
    find_or_create_social_user,
    get_callback_url,
    get_provider_credentials,
)

router = APIRouter()


class MobileGoogleTokenRequest(BaseModel):
    id_token: str


@router.post(
    "/social/google/mobile",
    response_model=Token,
    summary="Mobile Google Sign-In",
    description=(
        "Accepts a Google ID token obtained by the mobile app via the native "
        "Google Sign-In SDK. Verifies the token with Google, then finds or "
        "creates a user account and returns JWT access + refresh tokens."
    ),
)
async def mobile_google_login(
    payload: MobileGoogleTokenRequest,
    request: Request,
    db: AsyncSession = Depends(get_db),
) -> Token:
    """Verify a Google ID token from the mobile Google Sign-In SDK."""
    # Verify the Google ID token by calling Google's tokeninfo endpoint
    async with httpx.AsyncClient(timeout=10) as http:
        try:
            resp = await http.get(
                "https://oauth2.googleapis.com/tokeninfo",
                params={"id_token": payload.id_token},
            )
            resp.raise_for_status()
            token_info: dict[str, Any] = resp.json()
        except httpx.HTTPStatusError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid Google ID token",
            )

    # Verify audience matches our client ID (if configured)
    google_client_id = settings.GOOGLE_CLIENT_ID if hasattr(settings, "GOOGLE_CLIENT_ID") else None
    if google_client_id and token_info.get("aud") != google_client_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Google token audience mismatch",
        )

    email: Optional[str] = token_info.get("email")
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account has no email address",
        )

    if not token_info.get("email_verified", False):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Google account email is not verified",
        )

    social_id: str = token_info.get("sub", "")
    given_name: str = token_info.get("given_name", "")
    family_name: str = token_info.get("family_name", "")
    display_name: str = f"{given_name} {family_name}".strip() or email.split("@")[0]

    user = await find_or_create_social_user(db, "google", social_id, email, display_name)

    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This account has been deactivated.",
        )

    ip_address = get_client_ip(request)
    user_agent = request.headers.get("user-agent", "unknown")

    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(user.id, expires_delta=access_token_expires)
    refresh_token = security.create_refresh_token(user.id)

    access_payload = jwt.decode(access_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])
    refresh_payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])

    await revoke_tokens_for_ip(db, user.id, ip_address)

    db.add(TokenTracking(
        user_id=user.id,
        token_jti=access_payload["jti"],
        token_type=TokenType.ACCESS,
        ip_address=ip_address,
        user_agent=user_agent,
        expires_at=datetime.fromtimestamp(access_payload["exp"], tz=timezone.utc),
    ))
    db.add(TokenTracking(
        user_id=user.id,
        token_jti=refresh_payload["jti"],
        token_type=TokenType.REFRESH,
        ip_address=ip_address,
        user_agent=user_agent,
        expires_at=datetime.fromtimestamp(refresh_payload["exp"], tz=timezone.utc),
    ))
    await db.commit()

    analytics.identify(distinct_id=str(user.id), properties={"email": user.email})
    analytics.track(distinct_id=str(user.id), event="user_login", properties={"method": "google_mobile"})

    return Token(
        access=access_token,
        refresh=refresh_token,
        token_type=TokenType.BEARER.value,
    )


def _provider_enabled(provider: str) -> bool:
    """Return True if the given social provider is enabled in settings."""
    return {
        "google": settings.GOOGLE_LOGIN_ENABLED,
        "github": settings.GITHUB_LOGIN_ENABLED,
        "facebook": settings.FACEBOOK_LOGIN_ENABLED,
    }.get(provider, False)


@router.get(
    "/social/providers",
    summary="List enabled social login providers",
    description="Returns which social OAuth2 providers are currently enabled.",
)
async def list_social_providers() -> dict[str, list[str]]:
    enabled = [p for p in OAUTH_PROVIDERS if _provider_enabled(p)]
    return {"providers": enabled}


@router.get(
    "/social/{provider}/",
    summary="Initiate social login",
    description="Redirects the browser to the OAuth2 provider's login page. Supported: google, github, facebook.",
)
async def social_login(provider: str) -> RedirectResponse:
    if provider not in OAUTH_PROVIDERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Provider '{provider}' is not supported. Supported: {list(OAUTH_PROVIDERS.keys())}",
        )
    if not _provider_enabled(provider):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Social login via '{provider}' is currently disabled.",
        )
    config = OAUTH_PROVIDERS[provider]
    client_id, _ = get_provider_credentials(provider)
    params: dict[str, Any] = {
        "client_id": client_id,
        "redirect_uri": get_callback_url(provider),
        "scope": config["scope"],
        "state": security.create_oauth_state(provider),
        **config.get("extra_params", {}),
    }
    return RedirectResponse(url=f"{config['authorize_url']}?{urlencode(params)}")


@router.get(
    "/social/{provider}/callback",
    summary="Handle OAuth2 callback",
    description=(
        "Exchanges the authorization code for tokens, retrieves user info, "
        "and issues JWT access/refresh tokens. Pass set_cookie=true to receive "
        "tokens via HttpOnly cookie instead of JSON."
    ),
)
async def social_callback(
    provider: str,
    code: str,
    state: str,
    request: Request,
    set_cookie: bool = False,
    db: AsyncSession = Depends(get_db),
) -> RedirectResponse:
    if provider not in OAUTH_PROVIDERS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Provider '{provider}' is not supported",
        )
    if not _provider_enabled(provider):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Social login via '{provider}' is currently disabled.",
        )

    if not security.verify_oauth_state(state, provider):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid or expired OAuth state. Please try again.",
        )

    config = OAUTH_PROVIDERS[provider]
    client_id, client_secret = get_provider_credentials(provider)
    callback_url = get_callback_url(provider)

    async with httpx.AsyncClient() as http:
        # Exchange authorization code for provider access token
        try:
            token_resp = await http.post(
                config["token_url"],
                data={
                    "client_id": client_id,
                    "client_secret": client_secret,
                    "code": code,
                    "redirect_uri": callback_url,
                    "grant_type": "authorization_code",
                },
                headers={"Accept": "application/json"},
                timeout=10,
            )
            token_resp.raise_for_status()
        except httpx.HTTPStatusError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Failed to obtain access token from {provider}",
            )

        provider_token: Optional[str] = token_resp.json().get("access_token")
        if not provider_token:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"No access token returned by {provider}",
            )

        # Fetch user profile from provider
        try:
            info_resp = await http.get(
                config["userinfo_url"],
                headers={
                    "Authorization": f"Bearer {provider_token}",
                    "Accept": "application/json",
                    "User-Agent": "FastAPI-Template/1.0",
                },
                timeout=10,
            )
            info_resp.raise_for_status()
            user_info: dict[str, Any] = info_resp.json()
        except httpx.HTTPStatusError:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Failed to fetch user info from {provider}",
            )

        # GitHub may keep email private — fetch it from the dedicated emails endpoint
        if provider == "github" and not user_info.get("email"):
            try:
                emails_resp = await http.get(
                    config["emails_url"],
                    headers={
                        "Authorization": f"Bearer {provider_token}",
                        "Accept": "application/json",
                        "User-Agent": "FastAPI-Template/1.0",
                    },
                    timeout=10,
                )
                emails_resp.raise_for_status()
                primary = next(
                    (e["email"] for e in emails_resp.json() if e.get("primary") and e.get("verified")),
                    None,
                )
                if primary:
                    user_info["email"] = primary
            except Exception:
                pass

    social_id, email, display_name = extract_user_info(provider, user_info)

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not retrieve email from {provider}. Please grant email permission and try again.",
        )

    user = await find_or_create_social_user(db, provider, social_id, email, display_name)

    if not user.is_active:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="This account has been deactivated.")

    # Whitelist the current IP — social login is already authenticated by the provider
    ip_address = get_client_ip(request)
    user_agent = request.headers.get("user-agent", "unknown")

    # Issue application JWT tokens
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = security.create_access_token(user.id, expires_delta=access_token_expires)
    refresh_token = security.create_refresh_token(user.id)

    access_payload = jwt.decode(access_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])
    refresh_payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])

    # Revoke any existing active tokens for this user+IP before issuing new ones
    await revoke_tokens_for_ip(db, user.id, ip_address)

    db.add(TokenTracking(
        user_id=user.id,
        token_jti=access_payload["jti"],
        token_type=TokenType.ACCESS,
        ip_address=ip_address,
        user_agent=user_agent,
        expires_at=datetime.fromtimestamp(access_payload["exp"], tz=timezone.utc),
    ))
    db.add(TokenTracking(
        user_id=user.id,
        token_jti=refresh_payload["jti"],
        token_type=TokenType.REFRESH,
        ip_address=ip_address,
        user_agent=user_agent,
        expires_at=datetime.fromtimestamp(refresh_payload["exp"], tz=timezone.utc),
    ))
    await db.commit()

    analytics.identify(distinct_id=str(user.id), properties={"email": user.email})
    analytics.track(distinct_id=str(user.id), event="user_login", properties={"method": f"social_{provider}"})

    # Redirect the popup back to the frontend auth-callback page with tokens as
    # query params. The /auth-callback page stores the tokens and continues the flow.
    frontend_callback = f"{settings.FRONTEND_URL}/auth-callback"

    if set_cookie:
        redirect_resp = RedirectResponse(url=frontend_callback, status_code=302)
        redirect_resp.set_cookie(
            key=settings.ACCESS_TOKEN_COOKIE,
            value=access_token,
            httponly=True,
            secure=settings.SECURE_COOKIES,
            samesite="lax",
            max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        )
        return redirect_resp

    return RedirectResponse(
        url=f"{frontend_callback}?access={access_token}&refresh={refresh_token}",
        status_code=302,
    )

