from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool, AsyncAdaptedQueuePool
from sqlmodel import SQLModel
from src.apps.core.config import settings

if not settings.DATABASE_URL:
    raise ValueError("DATABASE_URL is not set in the configuration")

_is_sqlite = settings.DATABASE_URL.startswith("sqlite")

engine = create_async_engine(
    url=settings.DATABASE_URL,
    echo=True,
    future=True,
    poolclass=NullPool if _is_sqlite else AsyncAdaptedQueuePool,
)

async_session_factory = async_sessionmaker(engine, expire_on_commit=False)

async def init_db():
    # Import all models so SQLModel.metadata knows about every table
    import src.apps.iam.models  # noqa: F401
    import src.apps.notification.models  # noqa: F401
    import src.apps.multitenancy.models  # noqa: F401
    import src.apps.finance.models  # noqa: F401
    import src.apps.websocket.models  # noqa: F401
    import src.apps.futsal.models  # noqa: F401
    import src.apps.payout.models  # noqa: F401
    import src.apps.subscription.models  # noqa: F401

    async with engine.begin() as conn:
        await conn.run_sync(SQLModel.metadata.create_all)

async def get_session() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session