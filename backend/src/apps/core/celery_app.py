from celery import Celery
from src.apps.core.config import settings

celery_app = Celery(
    "Futsal",
    broker=settings.CELERY_BROKER_URL,
    backend=settings.CELERY_RESULT_BACKEND,
    include=[
        'src.apps.core.tasks',
        'src.apps.iam.tasks',
        'src.apps.notification.tasks',
        'src.apps.futsal.tasks',
        'src.apps.payout.tasks',
        'src.apps.subscription.tasks',
    ]
)

celery_app.conf.update(
    task_serializer='json',
    accept_content=['json'],
    result_serializer='json',
    timezone='UTC',
    enable_utc=True,
    task_track_started=True,
    task_time_limit=30 * 60,
    result_expires=3600,
    # In development, run tasks inline (no worker / broker needed)
    task_always_eager=settings.DEBUG,
    task_eager_propagates=settings.DEBUG,
)

if __name__ == '__main__':
    celery_app.start()
