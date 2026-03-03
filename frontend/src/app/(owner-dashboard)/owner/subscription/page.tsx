'use client';

import { useState, useEffect } from 'react';
import {
  useSubscription,
  useSubscriptionPlans,
  useCancelSubscription,
  useStartTrial,
  type SubscriptionStatus,
  type SubscriptionPlan,
} from '@/hooks/use-subscription';
import { apiClient } from '@/lib/api-client';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { CheckCircle, Clock, XCircle, AlertTriangle, CreditCard, Zap } from 'lucide-react';
import { useAnalytics } from '@/hooks/use-analytics';

// ── Status badge ───────────────────────────────────────────────────────────

const STATUS_STYLES: Record<SubscriptionStatus, string> = {
  ACTIVE: 'bg-green-100 text-green-700',
  TRIALING: 'bg-blue-100 text-blue-700',
  GRACE: 'bg-yellow-100 text-yellow-700',
  EXPIRED: 'bg-red-100 text-red-700',
  CANCELLED: 'bg-gray-100 text-gray-500',
};

const STATUS_ICONS: Record<SubscriptionStatus, React.ElementType> = {
  ACTIVE: CheckCircle,
  TRIALING: Clock,
  GRACE: AlertTriangle,
  EXPIRED: XCircle,
  CANCELLED: XCircle,
};

function StatusBadge({ status }: { status: SubscriptionStatus }) {
  const Icon = STATUS_ICONS[status];
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold uppercase ${STATUS_STYLES[status]}`}
    >
      <Icon className="h-3.5 w-3.5" />
      {status}
    </span>
  );
}

// ── Toast banner ───────────────────────────────────────────────────────────

function Toast({
  message,
  type,
  onClose,
}: {
  message: string;
  type: 'success' | 'error';
  onClose: () => void;
}) {
  return (
    <div
      className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-4 py-3 shadow-lg text-sm font-medium ${
        type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
      }`}
    >
      {message}
      <button onClick={onClose} className="ml-2 text-white/80 hover:text-white">
        ✕
      </button>
    </div>
  );
}

// ── Trial button wrapper ───────────────────────────────────────────────────

function TrialButton({
  plan,
  onSuccess,
  onError,
}: {
  plan: SubscriptionPlan;
  onSuccess: () => void;
  onError: (msg: string) => void;
}) {
  const startTrial = useStartTrial(plan.id);
  return (
    <Button
      size="sm"
      variant="outline"
      className="w-full border-blue-500 text-blue-600 hover:bg-blue-50"
      isLoading={startTrial.isPending}
      onClick={() =>
        startTrial.mutate(undefined, {
          onSuccess,
          onError: (e: unknown) => {
            const msg =
              (e as { response?: { data?: { detail?: string } } })?.response?.data?.detail ??
              'Failed to start trial.';
            onError(msg);
          },
        })
      }
    >
      <Zap className="mr-1.5 h-3.5 w-3.5" />
      Start {plan.trial_days}-day Free Trial
    </Button>
  );
}

// ── Plan card ──────────────────────────────────────────────────────────────

function PlanCard({
  plan,
  isCurrentPlan,
  canTrial,
  onSubscribe,
  onTrialSuccess,
  onTrialError,
}: {
  plan: SubscriptionPlan;
  isCurrentPlan: boolean;
  canTrial: boolean;
  onSubscribe: (plan: SubscriptionPlan) => void;
  onTrialSuccess: () => void;
  onTrialError: (msg: string) => void;
}) {
  return (
    <Card
      className={`flex flex-col ${isCurrentPlan ? 'ring-2 ring-green-500' : 'hover:shadow-md'} transition-shadow`}
    >
      <CardHeader className="pb-2">
        <div className="flex items-start justify-between">
          <CardTitle className="text-lg">{plan.name}</CardTitle>
          {isCurrentPlan && (
            <span className="rounded-full bg-green-100 px-2 py-0.5 text-xs font-semibold text-green-700">
              Current
            </span>
          )}
        </div>
        <p className="text-2xl font-bold text-gray-900">
          NPR {plan.price_monthly.toLocaleString()}
          <span className="text-sm font-normal text-gray-500">/month</span>
        </p>
      </CardHeader>
      <CardContent className="flex flex-1 flex-col gap-4">
        <ul className="space-y-1.5 text-sm text-gray-600">
          <li className="flex items-center gap-2">
            <CheckCircle className="h-4 w-4 text-green-500 shrink-0" />
            Up to {plan.max_grounds} ground{plan.max_grounds !== 1 ? 's' : ''}
          </li>
          <li className="flex items-center gap-2">
            <CheckCircle className="h-4 w-4 text-green-500 shrink-0" />
            Up to {plan.max_staff} staff member{plan.max_staff !== 1 ? 's' : ''}
          </li>
          {plan.trial_days > 0 && (
            <li className="flex items-center gap-2">
              <Zap className="h-4 w-4 text-blue-500 shrink-0" />
              {plan.trial_days}-day free trial
            </li>
          )}
          {plan.features.map((f) => (
            <li key={f} className="flex items-center gap-2">
              <CheckCircle className="h-4 w-4 text-green-500 shrink-0" />
              {f}
            </li>
          ))}
        </ul>
        <div className="mt-auto space-y-2">
          <Button
            className="w-full bg-green-600 hover:bg-green-700"
            onClick={() => onSubscribe(plan)}
          >
            <CreditCard className="mr-1.5 h-4 w-4" />
            Subscribe via Khalti
          </Button>
          {canTrial && plan.trial_days > 0 && (
            <TrialButton
              plan={plan}
              onSuccess={onTrialSuccess}
              onError={onTrialError}
            />
          )}
        </div>
      </CardContent>
    </Card>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────

export default function OwnerSubscriptionPage() {
  const { data: subscription, isLoading: subLoading } = useSubscription();
  const { data: plans = [], isLoading: plansLoading } = useSubscriptionPlans();
  const cancelSubscription = useCancelSubscription();
  const { track } = useAnalytics();

  useEffect(() => {
    track('subscription_page_viewed', {});
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const [showCancelDialog, setShowCancelDialog] = useState(false);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);
  const [isInitiatingPayment, setIsInitiatingPayment] = useState(false);

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const handleCancel = () => {
    cancelSubscription.mutate(false as boolean, {
      onSuccess: () => {
        setShowCancelDialog(false);
        showToast('Subscription will be cancelled at the end of the billing period.', 'success');
      },
      onError: () => {
        setShowCancelDialog(false);
        showToast('Failed to cancel subscription. Please try again.', 'error');
      },
    });
  };

  const handleSubscribe = async (plan: SubscriptionPlan) => {
    setIsInitiatingPayment(true);
    try {
      const { data } = await apiClient.post('/payments/initiate', {
        amount: plan.price_monthly,
        plan_id: plan.id,
      });
      if (data?.payment_url) {
        window.location.href = data.payment_url;
      } else {
        showToast('Payment initiation failed. No redirect URL received.', 'error');
      }
    } catch (e: unknown) {
      const status = (e as { response?: { status?: number } })?.response?.status;
      if (status === 402) {
        showToast('Payment required. Please add a valid payment method.', 'error');
      } else {
        showToast('Failed to initiate payment. Please try again.', 'error');
      }
    } finally {
      setIsInitiatingPayment(false);
    }
  };

  const isTrialing = subscription?.status === 'TRIALING';
  const canTrial = !isTrialing && subscription?.status !== 'ACTIVE';
  const endDate = subscription?.trial_ends_at ?? subscription?.current_period_end;

  return (
    <div className="space-y-8">
      {toast && (
        <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />
      )}

      <div>
        <h1 className="text-2xl font-bold text-gray-900">Subscription</h1>
        <p className="text-gray-500">Manage your plan and billing</p>
      </div>

      {/* Current subscription status */}
      <Card>
        <CardHeader>
          <CardTitle>Current Plan</CardTitle>
        </CardHeader>
        <CardContent>
          {subLoading ? (
            <div className="space-y-3">
              <Skeleton className="h-6 w-48" />
              <Skeleton className="h-4 w-64" />
            </div>
          ) : (
            <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
              <div className="space-y-2">
                <div className="flex items-center gap-3">
                  <p className="font-semibold text-gray-900">
                    {subscription?.plan?.name ?? 'No active plan'}
                  </p>
                  {subscription?.status && <StatusBadge status={subscription.status} />}
                </div>
                {endDate && (
                  <p className="text-sm text-gray-500">
                    {isTrialing ? 'Trial ends' : 'Renews on'}:{' '}
                    <span className="font-medium text-gray-700">
                      {new Date(endDate).toLocaleDateString()}
                    </span>
                  </p>
                )}
                {subscription?.cancel_at_period_end && (
                  <p className="text-sm text-yellow-600">
                    ⚠ Cancels at end of current period
                  </p>
                )}
              </div>
              {subscription?.is_active && !subscription.cancel_at_period_end && (
                <Button
                  variant="outline"
                  className="border-red-300 text-red-600 hover:bg-red-50"
                  onClick={() => setShowCancelDialog(true)}
                >
                  Cancel Subscription
                </Button>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Plans grid */}
      <div>
        <h2 className="mb-4 text-lg font-semibold text-gray-900">Available Plans</h2>
        {plansLoading ? (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {[1, 2, 3].map((i) => (
              <Skeleton key={i} className="h-64 w-full rounded-xl" />
            ))}
          </div>
        ) : plans.length === 0 ? (
          <p className="text-sm text-gray-400">No plans available.</p>
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {plans
              .filter((p) => p.is_active)
              .map((plan) => (
                <PlanCard
                  key={plan.id}
                  plan={plan}
                  isCurrentPlan={subscription?.plan?.id === plan.id}
                  canTrial={canTrial}
                  onSubscribe={handleSubscribe}
                  onTrialSuccess={() =>
                    showToast(`Free trial for ${plan.name} started!`, 'success')
                  }
                  onTrialError={(msg) => showToast(msg, 'error')}
                />
              ))}
          </div>
        )}
      </div>

      {isInitiatingPayment && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30">
          <div className="rounded-xl bg-white px-8 py-6 shadow-xl text-center">
            <p className="font-medium text-gray-700">Redirecting to Khalti…</p>
          </div>
        </div>
      )}

      <ConfirmDialog
        open={showCancelDialog}
        title="Cancel Subscription?"
        description="Your subscription will remain active until the end of the current billing period. You won't be charged again."
        confirmLabel="Yes, Cancel"
        cancelLabel="Keep Subscription"
        onConfirm={handleCancel}
        onCancel={() => setShowCancelDialog(false)}
        isLoading={cancelSubscription.isPending}
      />
    </div>
  );
}
