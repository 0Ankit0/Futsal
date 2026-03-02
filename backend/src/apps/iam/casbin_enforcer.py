from typing import Optional
import casbin
from casbin_async_sqlalchemy_adapter import Adapter as AsyncAdapter
from sqlalchemy.ext.asyncio import AsyncEngine
from pathlib import Path

_GLOBAL = "global"  # default domain for non-tenant policies


class CasbinEnforcer:
    """
    Casbin Enforcer singleton for managing authorization policies.
    Supports domain-based RBAC (tenant-aware): (sub, domain, obj, act).
    All methods accept an optional `domain` argument; it defaults to ``"global"``
    for backwards-compatible, non-tenant usage.
    """

    _enforcer: Optional[casbin.AsyncEnforcer] = None

    @classmethod
    async def get_enforcer(cls, engine: AsyncEngine) -> casbin.AsyncEnforcer:
        if cls._enforcer is None:
            model_path = Path(__file__).parent / "casbin_model.conf"
            adapter = AsyncAdapter(engine, db_class=None)
            cls._enforcer = casbin.AsyncEnforcer(str(model_path), adapter)
            await cls._enforcer.load_policy()
        return cls._enforcer

    # ── Policy management ─────────────────────────────────────────────────

    @classmethod
    async def add_policy(cls, sub: str, obj: str, act: str, domain: str = _GLOBAL) -> bool:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return await cls._enforcer.add_policy(sub, domain, obj, act)

    @classmethod
    async def remove_policy(cls, sub: str, obj: str, act: str, domain: str = _GLOBAL) -> bool:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return await cls._enforcer.remove_policy(sub, domain, obj, act)

    # ── Role / grouping management ────────────────────────────────────────

    @classmethod
    async def add_role_for_user(cls, user: str, role: str, domain: str = _GLOBAL) -> bool:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return await cls._enforcer.add_role_for_user_in_domain(user, role, domain)

    @classmethod
    async def remove_role_for_user(cls, user: str, role: str, domain: str = _GLOBAL) -> bool:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return await cls._enforcer.delete_roles_for_user_in_domain(user, role, domain)

    @classmethod
    async def get_roles_for_user(cls, user: str, domain: str = _GLOBAL) -> list[str]:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return cls._enforcer.get_roles_for_user_in_domain(user, domain)

    @classmethod
    async def get_users_for_role(cls, role: str, domain: str = _GLOBAL) -> list[str]:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return cls._enforcer.get_users_for_role_in_domain(role, domain)

    # ── Permission checking ───────────────────────────────────────────────

    @classmethod
    async def enforce(cls, sub: str, obj: str, act: str, domain: str = _GLOBAL) -> bool:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return cls._enforcer.enforce(sub, domain, obj, act)

    @classmethod
    async def get_permissions_for_user(cls, user: str, domain: str = _GLOBAL) -> list[list[str]]:
        if cls._enforcer is None:
            raise RuntimeError("Enforcer not initialized. Call get_enforcer first.")
        return cls._enforcer.get_permissions_for_user_in_domain(user, domain)

