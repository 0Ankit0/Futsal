from fastapi import APIRouter
from .subscriptions import router as sub_router
from .staff import router as staff_router, accept_router

subscription_router = APIRouter()
subscription_router.include_router(sub_router)
subscription_router.include_router(staff_router)
subscription_router.include_router(accept_router)

__all__ = ["subscription_router"]
