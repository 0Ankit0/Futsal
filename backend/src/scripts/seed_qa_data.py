"""Seed deterministic QA data for end-to-end manual testing.

Run:
  cd backend
  source .venv/bin/activate
  python -m src.scripts.seed_qa_data
"""

from __future__ import annotations

import asyncio
from datetime import date, datetime, time, timedelta

from sqlalchemy import select

# Import model packages so SQLAlchemy relationship targets are registered.
import src.apps.finance.models  # noqa: F401
import src.apps.futsal.models  # noqa: F401
import src.apps.iam.models  # noqa: F401
import src.apps.multitenancy.models  # noqa: F401
import src.apps.notification.models  # noqa: F401
import src.apps.payout.models  # noqa: F401
import src.apps.subscription.models  # noqa: F401

from src.apps.core.security import get_password_hash
from src.apps.futsal.models.booking import Booking, BookingStatus
from src.apps.futsal.models.favourite import FavouriteGround
from src.apps.futsal.models.ground import FutsalGround, GroundType
from src.apps.futsal.models.ground_image import GroundImage
from src.apps.futsal.models.loyalty import (
    LoyaltyAccount,
    LoyaltyTransaction,
    LoyaltyTransactionType,
)
from src.apps.futsal.models.review import Review
from src.apps.iam.models.user import User, UserProfile
from src.apps.notification.models.notification import Notification, NotificationType
from src.apps.payout.models.owner_gateway import GatewayProvider, OwnerPaymentGateway
from src.apps.payout.models.payout_ledger import PayoutLedger
from src.apps.payout.models.payout_record import PayoutRecord, PayoutStatus
from src.apps.payout.services.encryption import encrypt_credentials
from src.apps.subscription.models.ground_staff import GroundStaff, StaffRole
from src.apps.subscription.models.plan import SubscriptionPlan
from src.apps.subscription.models.subscription import OwnerSubscription, SubscriptionStatus
from src.db.session import async_session_factory


QA_PASSWORD = "QaPass123"


async def _get_or_create_user(
    *,
    username: str,
    email: str,
    first_name: str,
    last_name: str,
    phone: str,
    is_superuser: bool = False,
) -> User:
    async with async_session_factory() as db:
        result = await db.execute(select(User).where(User.username == username))
        user = result.scalar_one_or_none()

        if not user:
            user = User(
                username=username,
                email=email,
                hashed_password=get_password_hash(QA_PASSWORD),
                is_superuser=is_superuser,
                is_active=True,
                is_confirmed=True,
            )
            db.add(user)
            await db.flush()
        else:
            user.email = email
            user.hashed_password = get_password_hash(QA_PASSWORD)
            user.is_superuser = is_superuser
            user.is_active = True
            user.is_confirmed = True

        profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user.id))
        profile = profile_result.scalar_one_or_none()
        if not profile:
            profile = UserProfile(
                user_id=user.id,
                first_name=first_name,
                last_name=last_name,
                phone=phone,
                image_url="",
                bio=f"QA seeded profile for {username}",
            )
            db.add(profile)
        else:
            profile.first_name = first_name
            profile.last_name = last_name
            profile.phone = phone

        await db.commit()
        await db.refresh(user)
        return user


async def seed() -> None:
    today = date.today()

    admin = await _get_or_create_user(
        username="qa_admin",
        email="qa_admin@example.com",
        first_name="QA",
        last_name="Admin",
        phone="+9779800000001",
        is_superuser=True,
    )
    owner = await _get_or_create_user(
        username="qa_owner",
        email="qa_owner@example.com",
        first_name="QA",
        last_name="Owner",
        phone="+9779800000002",
        is_superuser=False,
    )
    player = await _get_or_create_user(
        username="qa_player",
        email="qa_player@example.com",
        first_name="QA",
        last_name="Player",
        phone="+9779800000003",
        is_superuser=False,
    )
    staff = await _get_or_create_user(
        username="qa_staff",
        email="qa_staff@example.com",
        first_name="QA",
        last_name="Staff",
        phone="+9779800000004",
        is_superuser=False,
    )

    async with async_session_factory() as db:
        plan_result = await db.execute(select(SubscriptionPlan).where(SubscriptionPlan.slug == "qa-pro"))
        plan = plan_result.scalar_one_or_none()
        if not plan:
            plan = SubscriptionPlan(
                name="QA Pro",
                slug="qa-pro",
                description="Plan for QA regression testing",
                price_monthly=999.0,
                max_grounds=5,
                max_staff=10,
                trial_days=0,
                features='["priority-support","advanced-analytics","team-management"]',
                is_active=True,
                is_public=True,
            )
            db.add(plan)
            await db.flush()

        sub_result = await db.execute(
            select(OwnerSubscription).where(OwnerSubscription.owner_id == owner.id)
        )
        owner_sub = sub_result.scalar_one_or_none()
        if not owner_sub:
            owner_sub = OwnerSubscription(
                owner_id=owner.id,
                plan_id=plan.id,
                status=SubscriptionStatus.ACTIVE,
                current_period_start=today - timedelta(days=1),
                current_period_end=today + timedelta(days=29),
            )
            db.add(owner_sub)
        else:
            owner_sub.plan_id = plan.id
            owner_sub.status = SubscriptionStatus.ACTIVE
            owner_sub.current_period_start = today - timedelta(days=1)
            owner_sub.current_period_end = today + timedelta(days=29)

        ground_slug = "qa-arena-kathmandu"
        ground_result = await db.execute(select(FutsalGround).where(FutsalGround.slug == ground_slug))
        ground = ground_result.scalar_one_or_none()
        if not ground:
            ground = FutsalGround(
                name="QA Arena Kathmandu",
                slug=ground_slug,
                owner_id=owner.id,
                location="Kathmandu",
                latitude=27.7172,
                longitude=85.3240,
                description="Primary QA ground for booking journey tests",
                ground_type=GroundType.OUTDOOR,
                price_per_hour=1800,
                weekend_price_per_hour=2200,
                open_time=time(6, 0),
                close_time=time(22, 0),
                slot_duration_minutes=60,
                is_active=True,
                is_verified=True,
                amenities={"parking": True, "showers": True, "cafeteria": True},
            )
            db.add(ground)
            await db.flush()
        else:
            ground.owner_id = owner.id
            ground.name = "QA Arena Kathmandu"
            ground.location = "Kathmandu"
            ground.price_per_hour = 1800
            ground.weekend_price_per_hour = 2200
            ground.is_active = True
            ground.is_verified = True
            ground.updated_at = datetime.utcnow()

        image_result = await db.execute(
            select(GroundImage).where(
                GroundImage.ground_id == ground.id,
                GroundImage.image_url == "/media/qa/ground-main.jpg",
            )
        )
        if not image_result.scalar_one_or_none():
            db.add(
                GroundImage(
                    ground_id=ground.id,
                    image_url="/media/qa/ground-main.jpg",
                    is_primary=True,
                    display_order=0,
                )
            )

        upcoming_date = today + timedelta(days=2)
        completed_date = today - timedelta(days=2)
        cancelled_date = today + timedelta(days=4)

        async def upsert_booking(b_date: date, start_h: int, status: BookingStatus, team_name: str) -> Booking:
            stmt = select(Booking).where(
                Booking.user_id == player.id,
                Booking.ground_id == ground.id,
                Booking.booking_date == b_date,
                Booking.start_time == time(start_h, 0),
            )
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                existing = Booking(
                    user_id=player.id,
                    ground_id=ground.id,
                    booking_date=b_date,
                    start_time=time(start_h, 0),
                    end_time=time(start_h + 1, 0),
                    total_amount=1800,
                    paid_amount=1800,
                    status=status,
                    team_name=team_name,
                    notes="QA seeded booking",
                    qr_used=(status == BookingStatus.COMPLETED),
                )
                db.add(existing)
                await db.flush()
            else:
                existing.status = status
                existing.team_name = team_name
                existing.total_amount = 1800
                existing.paid_amount = 1800
                existing.qr_used = status == BookingStatus.COMPLETED
            return existing

        booking_upcoming = await upsert_booking(upcoming_date, 18, BookingStatus.CONFIRMED, "QA Upcoming Team")
        booking_completed = await upsert_booking(completed_date, 19, BookingStatus.COMPLETED, "QA Completed Team")
        booking_cancelled = await upsert_booking(cancelled_date, 20, BookingStatus.CANCELLED, "QA Cancelled Team")
        booking_cancelled.cancellation_reason = "QA cancellation scenario"

        review_result = await db.execute(select(Review).where(Review.booking_id == booking_completed.id))
        review = review_result.scalar_one_or_none()
        if not review:
            review = Review(
                user_id=player.id,
                ground_id=ground.id,
                booking_id=booking_completed.id,
                rating=5,
                comment="Great ground and smooth booking process for QA.",
                owner_reply="Thanks for the feedback.",
                is_verified=True,
            )
            db.add(review)
        else:
            review.rating = 5
            review.comment = "Great ground and smooth booking process for QA."
            review.owner_reply = "Thanks for the feedback."
            review.is_verified = True

        fav_result = await db.execute(
            select(FavouriteGround).where(
                FavouriteGround.user_id == player.id,
                FavouriteGround.ground_id == ground.id,
            )
        )
        if not fav_result.scalar_one_or_none():
            db.add(FavouriteGround(user_id=player.id, ground_id=ground.id))

        loyalty_result = await db.execute(
            select(LoyaltyAccount).where(LoyaltyAccount.user_id == player.id)
        )
        loyalty_account = loyalty_result.scalar_one_or_none()
        if not loyalty_account:
            loyalty_account = LoyaltyAccount(
                user_id=player.id,
                points_balance=30,
                total_earned=30,
                total_redeemed=0,
            )
            db.add(loyalty_account)
            await db.flush()
        else:
            loyalty_account.points_balance = 30
            loyalty_account.total_earned = 30
            loyalty_account.total_redeemed = 0

        tx_result = await db.execute(
            select(LoyaltyTransaction).where(
                LoyaltyTransaction.account_id == loyalty_account.id,
                LoyaltyTransaction.description == "QA seed points from completed booking",
            )
        )
        if not tx_result.scalar_one_or_none():
            db.add(
                LoyaltyTransaction(
                    account_id=loyalty_account.id,
                    booking_id=booking_completed.id,
                    transaction_type=LoyaltyTransactionType.EARNED,
                    points=30,
                    description="QA seed points from completed booking",
                )
            )

        gateway_result = await db.execute(
            select(OwnerPaymentGateway).where(OwnerPaymentGateway.owner_id == owner.id)
        )
        gateway = gateway_result.scalar_one_or_none()
        encrypted = encrypt_credentials(
            {
                "secret_key": "qa-khalti-secret",
                "merchant_mobile": "9800001111",
            }
        )
        if not gateway:
            gateway = OwnerPaymentGateway(
                owner_id=owner.id,
                provider=GatewayProvider.KHALTI,
                credentials_encrypted=encrypted,
                account_name="QA Owner Merchant",
                account_number_hint="1111",
                is_active=True,
                is_verified=True,
            )
            db.add(gateway)
        else:
            gateway.provider = GatewayProvider.KHALTI
            gateway.credentials_encrypted = encrypted
            gateway.account_name = "QA Owner Merchant"
            gateway.account_number_hint = "1111"
            gateway.is_active = True
            gateway.is_verified = True

        payout_result = await db.execute(
            select(PayoutRecord).where(
                PayoutRecord.owner_id == owner.id,
                PayoutRecord.period_start == completed_date,
                PayoutRecord.period_end == completed_date,
            )
        )
        payout = payout_result.scalar_one_or_none()
        if not payout:
            payout = PayoutRecord(
                owner_id=owner.id,
                ground_id=ground.id,
                period_start=completed_date,
                period_end=completed_date,
                total_bookings=1,
                gross_amount=1800,
                platform_fee_pct=5.0,
                platform_fee=90,
                net_amount=1710,
                status=PayoutStatus.COMPLETED,
                payout_mode="PLATFORM",
                provider="khalti",
                transaction_ref="qa-payout-ref",
                completed_at=datetime.utcnow(),
            )
            db.add(payout)
            await db.flush()
        else:
            payout.status = PayoutStatus.COMPLETED
            payout.gross_amount = 1800
            payout.platform_fee_pct = 5.0
            payout.platform_fee = 90
            payout.net_amount = 1710
            payout.provider = "khalti"
            payout.transaction_ref = "qa-payout-ref"

        ledger_result = await db.execute(
            select(PayoutLedger).where(PayoutLedger.booking_id == booking_completed.id)
        )
        ledger = ledger_result.scalar_one_or_none()
        if not ledger:
            ledger = PayoutLedger(
                ground_id=ground.id,
                owner_id=owner.id,
                booking_id=booking_completed.id,
                gross_amount=1800,
                platform_fee_pct=5.0,
                platform_fee=90,
                net_amount=1710,
                payout_mode="PLATFORM",
                settled=True,
                payout_id=payout.id,
            )
            db.add(ledger)
        else:
            ledger.gross_amount = 1800
            ledger.platform_fee_pct = 5.0
            ledger.platform_fee = 90
            ledger.net_amount = 1710
            ledger.payout_mode = "PLATFORM"
            ledger.settled = True
            ledger.payout_id = payout.id

        staff_result = await db.execute(
            select(GroundStaff).where(
                GroundStaff.ground_id == ground.id,
                GroundStaff.user_id == staff.id,
            )
        )
        staff_record = staff_result.scalar_one_or_none()
        if not staff_record:
            staff_record = GroundStaff(
                ground_id=ground.id,
                user_id=staff.id,
                invited_by=owner.id,
                role=StaffRole.MANAGER,
                is_active=True,
                invite_email=staff.email,
                accepted_at=datetime.utcnow(),
            )
            db.add(staff_record)
        else:
            staff_record.invited_by = owner.id
            staff_record.role = StaffRole.MANAGER
            staff_record.is_active = True
            staff_record.invite_email = staff.email
            staff_record.accepted_at = datetime.utcnow()

        note_result = await db.execute(
            select(Notification).where(
                Notification.user_id == player.id,
                Notification.title == "QA booking reminder",
            )
        )
        if not note_result.scalar_one_or_none():
            db.add(
                Notification(
                    user_id=player.id,
                    title="QA booking reminder",
                    body="You have an upcoming booking in the QA dataset.",
                    type=NotificationType.INFO,
                    is_read=False,
                    extra_data={"booking_id": booking_upcoming.id},
                )
            )

        await db.commit()

    print("QA seed complete.")
    print("Credentials (all users):")
    print("  password: QaPass123")
    print("  qa_admin / qa_admin@example.com")
    print("  qa_owner / qa_owner@example.com")
    print("  qa_player / qa_player@example.com")
    print("  qa_staff / qa_staff@example.com")


if __name__ == "__main__":
    asyncio.run(seed())