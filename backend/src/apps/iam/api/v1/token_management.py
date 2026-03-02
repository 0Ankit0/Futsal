from typing import Sequence
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlmodel import select, desc, func, col
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime, timezone
from src.apps.iam.api.deps import get_current_user, get_db
from src.apps.iam.models.user import User
from src.apps.iam.models.token_tracking import TokenTracking
from src.apps.iam.schemas.token_tracking import TokenTrackingResponse
from src.apps.iam.utils.hashid import decode_id_or_404
from src.apps.core.schemas import PaginatedResponse
from src.apps.core.cache import RedisCache

router = APIRouter()


@router.get("/", response_model=PaginatedResponse[TokenTrackingResponse])
async def list_active_tokens(
    skip: int = Query(default=0, ge=0, description="Number of items to skip"),
    limit: int = Query(default=10, ge=1, le=100, description="Number of items to return"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get all active tokens for the current user with pagination
    """
    try:
        cache_key = f"tokens:active:{current_user.id}:{skip}:{limit}"
        
        # Try cache
        cached = await RedisCache.get(cache_key)
        if cached:
            return cached
        
        # Get total count
        count_result = await db.execute(
            select(func.count(col(TokenTracking.id))).where(
                TokenTracking.user_id == current_user.id,
                TokenTracking.is_active
            )
        )
        total = count_result.scalar_one()
        
        # Get paginated data
        result = await db.execute(
            select(TokenTracking).where(
                TokenTracking.user_id == current_user.id,
                TokenTracking.is_active
            ).order_by(desc(col(TokenTracking.created_at)))
            .offset(skip)
            .limit(limit)
        )
        items = result.scalars().all()
        items_response = [TokenTrackingResponse.model_validate(item) for item in items]
        
        # Create response
        response = PaginatedResponse[TokenTrackingResponse].create(
            items=items_response,
            total=total,
            skip=skip,
            limit=limit
        )
        
        # Cache for 1 minute (short TTL since tokens can be revoked)
        await RedisCache.set(cache_key, response.model_dump(), ttl=60)
        
        return response
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred fetching active tokens"
        )


@router.post("/revoke/{token_id}")
async def revoke_token(
    token_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> dict[str, str]:
    """
    Revoke a specific token
    """
    try:
        tid = decode_id_or_404(token_id)
        result = await db.execute(
            select(TokenTracking).where(
                TokenTracking.id == tid,
                TokenTracking.user_id == current_user.id
            )
        )
        token_tracking = result.scalars().first()
        
        if not token_tracking:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Token not found"
            )
        
        if not token_tracking.is_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Token is already revoked"
            )
        
        token_tracking.is_active = False
        token_tracking.revoked_at = datetime.now(timezone.utc)
        token_tracking.revoke_reason = "Revoked by user"
        await db.commit()
        
        # Invalidate cache
        await RedisCache.clear_pattern(f"tokens:active:{current_user.id}:*")
        
        return {"message": "Token revoked successfully"}
    except HTTPException:
        raise
    except Exception:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred revoking token"
        )


@router.post("/revoke-all")
async def revoke_all_tokens(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> dict[str, str]:
    """
    Revoke all active tokens for the current user
    """
    try:
        result = await db.execute(
            select(TokenTracking).where(
                TokenTracking.user_id == current_user.id,
                TokenTracking.is_active
            )
        )
        tokens = result.scalars().all()
        
        for token_tracking in tokens:
            token_tracking.is_active = False
            token_tracking.revoked_at = datetime.now(timezone.utc)
            token_tracking.revoke_reason = "All tokens revoked by user"
        
        await db.commit()
        
        # Invalidate cache
        await RedisCache.clear_pattern(f"tokens:active:{current_user.id}:*")
        
        return {"message": f"Revoked {len(tokens)} active token(s)"}
    except Exception:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="An error occurred revoking tokens"
        )
