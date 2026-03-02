from fastapi import APIRouter
from . import login, signup, password, token, otp, social

__all__ = ["router"]

router = APIRouter()

# Include all sub-routers
router.include_router(login.router)
router.include_router(signup.router)
router.include_router(password.router)
router.include_router(token.router)
router.include_router(otp.router)
router.include_router(social.router)
