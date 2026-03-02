from fastapi import APIRouter
from .gateway import router as gateway_router
from .records import router as records_router

payout_router = APIRouter(prefix="/payout-mgmt")
payout_router.include_router(gateway_router)
payout_router.include_router(records_router)
