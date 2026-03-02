from datetime import timedelta, datetime, timezone
from typing import Any
from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession
from jose import jwt
from slowapi import Limiter
from slowapi.util import get_remote_address
from src.apps.core.config import settings
from src.apps.core import security
from src.apps.core.security import TokenType
from src.apps.core.cache import RedisCache
from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.iam.models.login_attempt import LoginAttempt
from src.apps.iam.models.token_tracking import TokenTracking
from src.apps.iam.schemas.token import Token
from src.apps.iam.schemas.user import LoginRequest

from src.apps.iam.utils.ip_access import revoke_tokens_for_ip, get_client_ip

router = APIRouter()
limiter = Limiter(key_func=get_remote_address)


@router.post("/login/")
@limiter.limit("5/minute")
async def login_access_token(
    request: Request,
    response: Response,
    set_cookie: bool,
    login_data: LoginRequest,
    db: AsyncSession = Depends(get_db)
) -> Token | dict[str, Any]:
    """
    OAuth2 compatible token login, get an access token for future requests
    """
    ip_address = get_client_ip(request)
    user_agent = request.headers.get("user-agent", "unknown")
    user = None
    
    try:
        result = await db.execute(
            select(User).where(User.username == login_data.username)
        )
        user = result.scalars().first()

        if not user:
            login_attempt = LoginAttempt(
                user_id=0,
                ip_address=ip_address,
                user_agent=user_agent,
                success=False,
                failure_reason="User not found"
            )
            db.add(login_attempt)
            await db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Incorrect username or password"
            )
        
        if not user.hashed_password:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"This account uses {user.social_provider or 'social'} login. Please sign in with your social provider."
            )
        
        if not security.verify_password(login_data.password, user.hashed_password):
            login_attempt = LoginAttempt(
                user_id=user.id,
                ip_address=ip_address,
                user_agent=user_agent,
                success=False,
                failure_reason="Incorrect password"
            )
            db.add(login_attempt)
            await db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Incorrect username or password"
            )
        
        if not user.is_active:
            login_attempt = LoginAttempt(
                user_id=user.id,
                ip_address=ip_address,
                user_agent=user_agent,
                success=False,
                failure_reason="User account is inactive"
            )
            db.add(login_attempt)
            await db.commit()
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Inactive user"
            )
        
        # Check if OTP is enabled for this user
        if user.otp_enabled and user.otp_verified:
            temp_token = security.create_temp_auth_token(user.id)
            return {
                "requires_otp": True,
                "temp_token": temp_token,
                "message": "Please provide OTP code"
            }
        
        # Successful login
        login_attempt = LoginAttempt(
            user_id=user.id,
            ip_address=ip_address,
            user_agent=user_agent,
            success=True,
            failure_reason=""
        )
        db.add(login_attempt)
        
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = security.create_access_token(
            user.id, expires_delta=access_token_expires
        )
        refresh_token = security.create_refresh_token(user.id)
        
        # Decode tokens to get JTI
        access_payload = jwt.decode(access_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])
        refresh_payload = jwt.decode(refresh_token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])

        # Revoke any existing active tokens for this user+IP before issuing new ones
        await revoke_tokens_for_ip(db, user.id, ip_address)

        # Track access token
        access_token_tracking = TokenTracking(
            user_id=user.id,
            token_jti=access_payload["jti"],
            token_type=TokenType.ACCESS,
            ip_address=ip_address,
            user_agent=user_agent,
            expires_at=datetime.fromtimestamp(access_payload["exp"], tz=timezone.utc)
        )
        db.add(access_token_tracking)
        
        # Track refresh token
        refresh_token_tracking = TokenTracking(
            user_id=user.id,
            token_jti=refresh_payload["jti"],
            token_type=TokenType.REFRESH,
            ip_address=ip_address,
            user_agent=user_agent,
            expires_at=datetime.fromtimestamp(refresh_payload["exp"], tz=timezone.utc)
        )
        db.add(refresh_token_tracking)
        await db.commit()
        
        if set_cookie:
            response.set_cookie(
                key=settings.ACCESS_TOKEN_COOKIE,
                value=access_token,
                httponly=True,
                secure=settings.SECURE_COOKIES,
                samesite="lax",
                max_age=settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60
            )
            return {"message": "Logged in successfully"}
        
        return Token(
            access=access_token,
            refresh=refresh_token,
            token_type=TokenType.BEARER.value
        )
    except HTTPException:
        raise
    except Exception as ex:
        login_attempt = LoginAttempt(
            user_id=user.id if user else 0,
            ip_address=ip_address,
            user_agent=user_agent,
            success=False,
            failure_reason=f"Server error: {str(ex)}"
        )
        db.add(login_attempt)
        await db.commit()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during login"
        )


@router.post("/logout/")
async def logout(
    request: Request,
    response: Response,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> dict[str, str]:
    """
    Logout user by clearing cookies and revoking current session token only
    """
    try:
        # Get the current token
        auth_header = request.headers.get("Authorization")
        token = None
        
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ")[1]
        else:
            token = request.cookies.get(settings.ACCESS_TOKEN_COOKIE)
        
        if token:
            # Decode to get JTI
            try:
                payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[security.ALGORITHM])
                jti = payload.get("jti")
                ip_address = get_client_ip(request)
                
                if jti:
                    # Revoke only tokens from current IP/device
                    result = await db.execute(
                        select(TokenTracking).where(
                            TokenTracking.user_id == current_user.id,
                            TokenTracking.ip_address == ip_address,
                            TokenTracking.is_active
                        )
                    )
                    tokens = result.scalars().all()
                    
                    for token_tracking in tokens:
                        token_tracking.is_active = False
                        token_tracking.revoked_at = datetime.now(timezone.utc)
                        token_tracking.revoke_reason = "User logout from this device"
                    
                    await db.commit()
                    # Invalidate cached token list so revoked tokens are not served from cache
                    await RedisCache.clear_pattern(f"tokens:active:{current_user.id}:*")
            except Exception:
                pass
        
        response.delete_cookie(key=settings.ACCESS_TOKEN_COOKIE)
        response.delete_cookie(key=settings.REFRESH_TOKEN_COOKIE)
        return {"message": "Successfully logged out from this device"}
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred during logout"
        )
