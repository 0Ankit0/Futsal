from fastapi import APIRouter
from .grounds import router as grounds_router
from .bookings import router as bookings_router
from .reviews import router as reviews_router
from .favourites import router as favourites_router
from .loyalty import router as loyalty_router
from .analytics import router as analytics_router

futsal_router = APIRouter(prefix="/futsal")
futsal_router.include_router(grounds_router)
futsal_router.include_router(bookings_router)
futsal_router.include_router(reviews_router)
futsal_router.include_router(favourites_router)
futsal_router.include_router(loyalty_router)
futsal_router.include_router(analytics_router)
