from typing import Optional
from fastapi import Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import select
from src.db.session import get_session
from src.apps.iam.models import User, Role, UserRole, Permission, RolePermission
from src.apps.iam.casbin_enforcer import CasbinEnforcer

_GLOBAL = "global"


async def get_user_roles(user_id: int, session: AsyncSession) -> list[Role]:
    statement = (
        select(Role)
        .join(UserRole)
        .where(UserRole.user_id == user_id)
    )
    result = await session.execute(statement)
    return list(result.scalars().all())


async def get_role_permissions(role_id: int, session: AsyncSession) -> list[Permission]:
    statement = (
        select(Permission)
        .join(RolePermission)
        .where(RolePermission.role_id == role_id)
    )
    result = await session.execute(statement)
    return list(result.scalars().all())


async def assign_role_to_user(
    user_id: int,
    role_id: int,
    session: AsyncSession,
    domain: str = _GLOBAL,
) -> UserRole:
    user = await session.get(User, user_id)
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    role = await session.get(Role, role_id)
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    existing = (await session.execute(
        select(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == role_id)
    )).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Role already assigned to user")

    user_role = UserRole(user_id=user_id, role_id=role_id)
    session.add(user_role)
    await session.commit()
    await session.refresh(user_role)

    await CasbinEnforcer.add_role_for_user(str(user_id), role.name, domain)
    return user_role


async def remove_role_from_user(
    user_id: int,
    role_id: int,
    session: AsyncSession,
    domain: str = _GLOBAL,
) -> bool:
    user_role = (await session.execute(
        select(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == role_id)
    )).scalar_one_or_none()
    if not user_role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not assigned to user")

    role = await session.get(Role, role_id)
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    await session.delete(user_role)
    await session.commit()

    await CasbinEnforcer.remove_role_for_user(str(user_id), role.name, domain)
    return True


async def assign_permission_to_role(
    role_id: int,
    permission_id: int,
    session: AsyncSession,
    domain: str = _GLOBAL,
) -> RolePermission:
    role = await session.get(Role, role_id)
    if not role:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role not found")

    permission = await session.get(Permission, permission_id)
    if not permission:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Permission not found")

    existing = (await session.execute(
        select(RolePermission).where(
            RolePermission.role_id == role_id,
            RolePermission.permission_id == permission_id,
        )
    )).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Permission already assigned to role")

    role_permission = RolePermission(role_id=role_id, permission_id=permission_id)
    session.add(role_permission)
    await session.commit()
    await session.refresh(role_permission)

    await CasbinEnforcer.add_policy(role.name, permission.resource, permission.action, domain)
    return role_permission


async def remove_permission_from_role(
    role_id: int,
    permission_id: int,
    session: AsyncSession,
    domain: str = _GLOBAL,
) -> bool:
    role_permission = (await session.execute(
        select(RolePermission).where(
            RolePermission.role_id == role_id,
            RolePermission.permission_id == permission_id,
        )
    )).scalar_one_or_none()
    if not role_permission:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Permission not assigned to role")

    role = await session.get(Role, role_id)
    permission = await session.get(Permission, permission_id)
    if not role or not permission:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Role or permission not found")

    await session.delete(role_permission)
    await session.commit()

    await CasbinEnforcer.remove_policy(role.name, permission.resource, permission.action, domain)
    return True


async def check_permission(
    user_id: int,
    resource: str,
    action: str,
    session: AsyncSession,
    domain: str = _GLOBAL,
) -> bool:
    return await CasbinEnforcer.enforce(str(user_id), resource, action, domain)

