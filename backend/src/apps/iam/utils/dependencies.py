from typing import Callable
from functools import wraps
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from src.db.session import get_session
from src.apps.iam.utils.rbac import check_permission


def require_permission(resource: str, action: str):
    """
    Dependency factory for checking user permissions.
    
    Usage:
        @router.get("/users", dependencies=[Depends(require_permission("users", "read"))])
        async def list_users():
            ...
    
    Args:
        resource: Resource identifier (e.g., "users", "posts")
        action: Action to perform (e.g., "read", "write", "delete")
        
    Returns:
        Callable: Dependency function
    """
    async def permission_checker(
        current_user_id: int,  # This should come from your auth dependency
        session: AsyncSession = Depends(get_session)
    ):
        has_permission = await check_permission(
            user_id=current_user_id,
            resource=resource,
            action=action,
            session=session
        )
        
        if not has_permission:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Permission denied: {action} on {resource}"
            )
        
        return True
    
    return permission_checker


def require_role(role_name: str):
    """
    Dependency factory for checking user roles.
    
    Usage:
        @router.get("/admin", dependencies=[Depends(require_role("admin"))])
        async def admin_panel():
            ...
    
    Args:
        role_name: Name of the required role
        
    Returns:
        Callable: Dependency function
    """
    async def role_checker(
        current_user_id: int,  # This should come from your auth dependency
        session: AsyncSession = Depends(get_session)
    ):
        from src.apps.iam.casbin_enforcer import CasbinEnforcer
        
        roles = await CasbinEnforcer.get_roles_for_user(str(current_user_id))
        
        if role_name not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Role required: {role_name}"
            )
        
        return True
    
    return role_checker
