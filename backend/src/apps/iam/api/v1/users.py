"""
User management endpoints with caching and pagination
"""
import os
import uuid
from fastapi import APIRouter, Depends, HTTPException, status, Query, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from sqlmodel import select, func, or_, col
from typing import Optional
from src.apps.iam.api.deps import get_current_user, get_current_active_superuser, get_db
from src.apps.iam.models.user import User
from src.apps.iam.schemas.user import UserResponse, UserUpdate
from src.apps.iam.utils.hashid import decode_id_or_404
from src.apps.core.schemas import PaginatedResponse
from src.apps.core.cache import RedisCache
from src.apps.core.config import settings

router = APIRouter(prefix="/users")


@router.get("/", response_model=PaginatedResponse[UserResponse])
async def list_users(
    skip: int = Query(default=0, ge=0, description="Number of items to skip"),
    limit: int = Query(default=10, ge=1, le=100, description="Number of items to return"),
    search: Optional[str] = Query(default=None, description="Search by email or name"),
    is_active: Optional[bool] = Query(default=None, description="Filter by active status"),
    current_user: User = Depends(get_current_active_superuser),
    db: AsyncSession = Depends(get_db)
):
    """
    List all users with pagination and optional filters (admin only)
    """
    # Create cache key including filters
    cache_key = f"users:list:{skip}:{limit}:{search}:{is_active}"
    
    # Try cache
    cached = await RedisCache.get(cache_key)
    if cached:
        return cached
    
    
    # Build query
    query = select(User).options(selectinload(User.profile)) # type: ignore
    count_query = select(func.count(col(User.id)))
    
    # Apply filters
    if search:
        search_filter = or_(
            col(User.email).ilike(f"%{search}%"),
            col(User.username).ilike(f"%{search}%")
        )
        query = query.where(search_filter)
        count_query = count_query.where(search_filter)
    
    if is_active is not None:
        query = query.where(User.is_active == is_active)
        count_query = count_query.where(User.is_active == is_active)
    
    # Get total count
    count_result = await db.execute(count_query)
    total = count_result.scalar_one()
    
    # Get paginated data
    query = query.offset(skip).limit(limit).order_by(col(User.id))
    result = await db.execute(query)
    items = result.scalars().all()
    items_response = [UserResponse.model_validate(user) for user in items]
    
    # Create response
    response = PaginatedResponse[UserResponse].create(
        items=items_response,
        total=total,
        skip=skip,
        limit=limit
    )
    
    # Cache for 2 minutes (users data changes frequently)
    await RedisCache.set(cache_key, response.model_dump(), ttl=120)
    
    return response


@router.get("/me", response_model=UserResponse)
async def get_current_user_profile(
    current_user: User = Depends(get_current_user)
):
    """
    Get current user's profile
    """
    cache_key = f"user:profile:{current_user.id}"
    
    # Try cache
    cached = await RedisCache.get(cache_key)
    if cached:
        return UserResponse(**cached)
    
    profile = current_user.profile
    cache_data = {
        'id': current_user.id,
        'username': current_user.username,
        'email': current_user.email,
        'is_active': current_user.is_active,
        'is_superuser': current_user.is_superuser,
        'is_confirmed': current_user.is_confirmed,
        'otp_enabled': current_user.otp_enabled,
        'otp_verified': current_user.otp_verified,
        'first_name': profile.first_name if profile else None,
        'last_name': profile.last_name if profile else None,
        'phone': profile.phone if profile else None,
        'image_url': profile.image_url if profile else None,
        'bio': profile.bio if profile else None,
        'roles': [],
    }
    # Cache for 5 minutes
    await RedisCache.set(cache_key, cache_data, ttl=300)
    
    return current_user


@router.post("/me/avatar", response_model=UserResponse)
async def upload_avatar(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Upload or replace the current user's avatar image."""
    ALLOWED_TYPES = {"image/jpeg", "image/png", "image/gif", "image/webp"}
    MAX_SIZE = settings.MAX_AVATAR_SIZE_MB * 1024 * 1024

    if file.content_type not in ALLOWED_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Unsupported file type: {file.content_type}. Allowed: jpeg, png, gif, webp",
        )

    contents = await file.read()
    if len(contents) > MAX_SIZE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"File too large. Maximum size is {settings.MAX_AVATAR_SIZE_MB} MB",
        )

    ext = file.filename.rsplit(".", 1)[-1].lower() if file.filename and "." in file.filename else "jpg"
    filename = f"{current_user.id}_{uuid.uuid4().hex[:8]}.{ext}"
    avatars_dir = os.path.join(settings.MEDIA_DIR, "avatars")
    os.makedirs(avatars_dir, exist_ok=True)
    file_path = os.path.join(avatars_dir, filename)

    # Delete old avatar file if it exists locally
    if current_user.profile and current_user.profile.image_url:
        old_url = current_user.profile.image_url
        old_relative = old_url.replace(settings.SERVER_HOST, "").lstrip("/")
        old_path = os.path.join(settings.MEDIA_DIR, *old_relative.split("/")[1:])
        if os.path.isfile(old_path):
            os.remove(old_path)

    with open(file_path, "wb") as f:
        f.write(contents)

    image_url = f"{settings.SERVER_HOST}{settings.MEDIA_URL}/avatars/{filename}"

    if current_user.profile:
        current_user.profile.image_url = image_url
        db.add(current_user.profile)
    else:
        from src.apps.iam.models.user import UserProfile
        profile = UserProfile(user_id=current_user.id, image_url=image_url)
        db.add(profile)
        current_user.profile = profile

    await db.commit()
    await db.refresh(current_user)
    if current_user.profile:
        await db.refresh(current_user.profile)

    await RedisCache.delete(f"user:profile:{current_user.id}")

    return current_user


@router.get("/{user_id}", response_model=UserResponse)
async def get_user(
    user_id: str,
    current_user: User = Depends(get_current_active_superuser),
    db: AsyncSession = Depends(get_db)
):
    """
    Get user by ID (admin only)
    """
    uid = decode_id_or_404(user_id)
    cache_key = f"user:profile:{uid}"
    
    # Try cache
    cached = await RedisCache.get(cache_key)
    if cached:
        return UserResponse(**cached)
    
    result = await db.execute(select(User).options(selectinload(User.profile)).where(User.id == uid)) # type: ignore
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    profile = user.profile
    cache_data = {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'is_active': user.is_active,
        'is_superuser': user.is_superuser,
        'is_confirmed': user.is_confirmed,
        'otp_enabled': user.otp_enabled,
        'otp_verified': user.otp_verified,
        'first_name': profile.first_name if profile else None,
        'last_name': profile.last_name if profile else None,
        'phone': profile.phone if profile else None,
        'image_url': profile.image_url if profile else None,
        'bio': profile.bio if profile else None,
        'roles': [],
    }
    # Cache for 5 minutes
    await RedisCache.set(cache_key, cache_data, ttl=300)
    
    return user


@router.patch("/me", response_model=UserResponse)
async def update_current_user(
    user_update: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Update current user's profile
    """
    # Update user fields
    if user_update.email is not None:
        # Check if email is already taken
        result = await db.execute(
            select(User).where(
                User.email == user_update.email,
                User.id != current_user.id
            )
        )
        if result.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        current_user.email = user_update.email
        current_user.is_confirmed = False  # Re-verify email

    # Update profile fields
    if current_user.profile:
        if user_update.first_name is not None:
            current_user.profile.first_name = user_update.first_name
        if user_update.last_name is not None:
            current_user.profile.last_name = user_update.last_name
        if user_update.phone is not None:
            current_user.profile.phone = user_update.phone
    
    db.add(current_user)
    await db.commit()
    await db.refresh(current_user)
    if current_user.profile:
        await db.refresh(current_user.profile)
    
    # Invalidate caches
    await RedisCache.delete(f"user:profile:{current_user.id}")
    await RedisCache.clear_pattern("users:list:*")
    
    return current_user


@router.patch("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: str,
    user_update: UserUpdate,
    current_user: User = Depends(get_current_active_superuser),
    db: AsyncSession = Depends(get_db)
):
    """
    Update user by ID (admin only)
    """
    uid = decode_id_or_404(user_id)
    result = await db.execute(select(User).options(selectinload(User.profile)).where(User.id == uid)) # type: ignore
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Update fields
    if user_update.email is not None:
        # Check if email is already taken
        result = await db.execute(
            select(User).where(
                User.email == user_update.email,
                User.id != uid
            )
        )
        if result.scalars().first():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered"
            )
        user.email = user_update.email
    # if user_update.is_active is not None:
    #     user.is_active = user_update.is_active

    # Update profile fields
    if user.profile:
        if user_update.first_name is not None:
            user.profile.first_name = user_update.first_name
        if user_update.last_name is not None:
            user.profile.last_name = user_update.last_name
        if user_update.phone is not None:
            user.profile.phone = user_update.phone
    
    db.add(user)
    await db.commit()
    await db.refresh(user)
    if user.profile:
        await db.refresh(user.profile)
    
    # Invalidate caches
    await RedisCache.delete(f"user:profile:{uid}")
    await RedisCache.clear_pattern("users:list:*")
    await RedisCache.clear_pattern(f"user:{uid}:*")
    
    return user


@router.delete("/{user_id}")
async def delete_user(
    user_id: str,
    current_user: User = Depends(get_current_active_superuser),
    db: AsyncSession = Depends(get_db)
):
    """
    Delete user by ID (admin only)
    """
    uid = decode_id_or_404(user_id)

    if uid == current_user.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot delete your own account"
        )
    
    result = await db.execute(select(User).where(User.id == uid))
    user = result.scalars().first()
    
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    await db.delete(user)
    await db.commit()
    
    # Invalidate caches
    await RedisCache.delete(f"user:profile:{uid}")
    await RedisCache.clear_pattern("users:list:*")
    await RedisCache.clear_pattern(f"user:{uid}:*")
    await RedisCache.delete(f"casbin:roles:{uid}")
    await RedisCache.delete(f"casbin:permissions:{uid}")
    
    return {"message": "User deleted successfully"}
