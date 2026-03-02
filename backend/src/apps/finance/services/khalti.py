"""
Khalti payment gateway integration (v2 API).

Sandbox credentials (from Khalti documentation):
  Public key : test_public_key_dc74e0fd57cb46cd93832aee0a390234
  Secret key : test_secret_key_dc74e0fd57cb46cd93832aee0a390234
  Base URL   : https://a.khalti.com/api/v2/

Test card (Khalti wallet):
  Mobile : 9800000000 / 9800000001 … 9800000005
  MPIN   : 1111
  OTP    : 987654
"""
import json
from datetime import datetime

import httpx
from sqlalchemy.ext.asyncio import AsyncSession

from src.apps.core.config import settings
from src.apps.finance.models.payment import PaymentProvider, PaymentStatus, PaymentTransaction
from src.apps.finance.schemas.payment import (
    InitiatePaymentRequest,
    InitiatePaymentResponse,
    VerifyPaymentRequest,
    VerifyPaymentResponse,
)
from src.apps.finance.services.base import BasePaymentProvider


class KhaltiService(BasePaymentProvider):
    """Khalti v2 payment provider."""

    BASE_URL: str = settings.KHALTI_BASE_URL

    # ------------------------------------------------------------------ #
    # Initiate                                                             #
    # ------------------------------------------------------------------ #

    async def initiate_payment(
        self,
        request: InitiatePaymentRequest,
        db: AsyncSession,
    ) -> InitiatePaymentResponse:
        """
        Call Khalti /epayment/initiate/ and persist a transaction record.

        Returns the ``payment_url`` the client should redirect the user to.
        """
        customer_info: dict = {}
        if request.customer_name:
            customer_info["name"] = request.customer_name
        if request.customer_email:
            customer_info["email"] = request.customer_email
        if request.customer_phone:
            customer_info["mobile"] = request.customer_phone

        payload: dict = {
            "return_url": request.return_url,
            "website_url": request.website_url or settings.SERVER_HOST,
            "amount": request.amount,
            "purchase_order_id": request.purchase_order_id,
            "purchase_order_name": request.purchase_order_name,
        }
        if customer_info:
            payload["customer_info"] = customer_info

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.BASE_URL}epayment/initiate/",
                json=payload,
                headers={
                    "Authorization": f"key {settings.KHALTI_SECRET_KEY}",
                    "Content-Type": "application/json",
                },
                timeout=30,
            )

        if resp.status_code != 200:
            error_detail = resp.text
            tx = PaymentTransaction(
                provider=PaymentProvider.KHALTI,
                amount=request.amount,
                purchase_order_id=request.purchase_order_id,
                purchase_order_name=request.purchase_order_name,
                return_url=request.return_url,
                website_url=request.website_url,
                status=PaymentStatus.FAILED,
                failure_reason=f"Initiation failed: {error_detail}",
                user_id=None,
            )
            db.add(tx)
            await db.commit()
            await db.refresh(tx)
            raise ValueError(f"Khalti initiation failed ({resp.status_code}): {error_detail}")

        data = resp.json()
        pidx: str = data["pidx"]
        payment_url: str = data["payment_url"]

        tx = PaymentTransaction(
            provider=PaymentProvider.KHALTI,
            amount=request.amount,
            purchase_order_id=request.purchase_order_id,
            purchase_order_name=request.purchase_order_name,
            return_url=request.return_url,
            website_url=request.website_url,
            status=PaymentStatus.INITIATED,
            provider_pidx=pidx,
            extra_data=json.dumps(data),
        )
        db.add(tx)
        await db.commit()
        await db.refresh(tx)

        return InitiatePaymentResponse(
            transaction_id=tx.id,
            provider=PaymentProvider.KHALTI,
            status=PaymentStatus.INITIATED,
            payment_url=payment_url,
            provider_pidx=pidx,
            extra=data,
        )

    # ------------------------------------------------------------------ #
    # Verify                                                               #
    # ------------------------------------------------------------------ #

    async def verify_payment(
        self,
        request: VerifyPaymentRequest,
        db: AsyncSession,
    ) -> VerifyPaymentResponse:
        """
        Call Khalti /epayment/lookup/ with the pidx to verify the payment.

        Khalti sends ``pidx`` as a query parameter to the return_url after
        the user completes (or cancels) payment.
        """
        pidx = request.pidx
        if not pidx:
            raise ValueError("pidx is required for Khalti verification")

        async with httpx.AsyncClient() as client:
            resp = await client.post(
                f"{self.BASE_URL}epayment/lookup/",
                json={"pidx": pidx},
                headers={
                    "Authorization": f"key {settings.KHALTI_SECRET_KEY}",
                    "Content-Type": "application/json",
                },
                timeout=30,
            )

        if resp.status_code != 200:
            raise ValueError(f"Khalti lookup failed ({resp.status_code}): {resp.text}")

        data = resp.json()
        khalti_status: str = data.get("status", "")
        transaction_id_provider: str = data.get("transaction_id", "")

        status_map = {
            "Completed": PaymentStatus.COMPLETED,
            "Pending": PaymentStatus.PENDING,
            "Expired": PaymentStatus.FAILED,
            "User canceled": PaymentStatus.CANCELLED,
            "Refunded": PaymentStatus.REFUNDED,
        }
        our_status = status_map.get(khalti_status, PaymentStatus.FAILED)

        from sqlmodel import select
        result = await db.execute(
            select(PaymentTransaction).where(PaymentTransaction.provider_pidx == pidx)
        )
        tx: PaymentTransaction | None = result.scalars().first()

        if tx is None:
            raise ValueError(f"No transaction found for Khalti pidx={pidx}")

        tx.status = our_status
        tx.provider_transaction_id = transaction_id_provider
        tx.extra_data = json.dumps(data)
        tx.updated_at = datetime.now()
        db.add(tx)
        await db.commit()
        await db.refresh(tx)

        return VerifyPaymentResponse(
            transaction_id=tx.id,
            provider=PaymentProvider.KHALTI,
            status=our_status,
            amount=data.get("total_amount"),
            provider_transaction_id=transaction_id_provider,
            extra=data,
        )
