'use client';

import { useState } from 'react';
import {
  useAllSubscriptions,
  useActivateSubscription,
  useSubscriptionPlans,
  type SubscriptionStatus,
  type OwnerSubscriptionAdmin,
} from '@/hooks/use-subscription';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Activity, CheckCircle, Clock, AlertTriangle, XCircle, RefreshCw } from 'lucide-react';

// ── Types ──────────────────────────────────────────────────────────────────

const STATUS_STYLES: Record<SubscriptionStatus, string> = {
  ACTIVE: 'bg-green-900 text-green-300',
  TRIALING: 'bg-blue-900 text-blue-300',
  GRACE: 'bg-yellow-900 text-yellow-300',
  EXPIRED: 'bg-red-900 text-red-300',
  CANCELLED: 'bg-slate-700 text-slate-400',
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
      className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-xs font-semibold uppercase ${STATUS_STYLES[status]}`}
    >
      <Icon className="h-3 w-3" />
      {status}
    </span>
  );
}

// ── Toast ──────────────────────────────────────────────────────────────────

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

// ── Activate dialog ────────────────────────────────────────────────────────

function ActivateDialog({
  subscription,
  planOptions,
  onClose,
  onSuccess,
  onError,
}: {
  subscription: OwnerSubscriptionAdmin;
  planOptions: { id: number; name: string }[];
  onClose: () => void;
  onSuccess: () => void;
  onError: (msg: string) => void;
}) {
  const [planId, setPlanId] = useState<number>(
    subscription.plan?.id ?? planOptions[0]?.id ?? 0,
  );
  const activate = useActivateSubscription();

  const handleActivate = () => {
    if (!planId) return;
    activate.mutate(
      { ownerId: subscription.owner_id, planId },
      {
        onSuccess: () => {
          onSuccess();
          onClose();
        },
        onError: (err: unknown) => {
          const msg =
            (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ??
            'Failed to activate subscription.';
          onError(msg);
        },
      },
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
      <div className="w-full max-w-sm rounded-xl bg-slate-800 border border-slate-700 p-6 shadow-xl">
        <h2 className="text-base font-semibold text-white mb-4">
          Manually Activate — Owner #{subscription.owner_id}
        </h2>
        <div className="space-y-3">
          <div className="space-y-1">
            <label className="text-sm font-medium text-slate-300">Plan</label>
            <select
              value={planId}
              onChange={(e) => setPlanId(Number(e.target.value))}
              className="w-full rounded-md border border-slate-600 bg-slate-900 px-3 py-2 text-sm text-white focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              {planOptions.map((p) => (
                <option key={p.id} value={p.id}>
                  {p.name}
                </option>
              ))}
            </select>
          </div>
        </div>
        <div className="mt-5 flex gap-2">
          <Button
            onClick={handleActivate}
            isLoading={activate.isPending}
            className="flex-1 bg-indigo-600 hover:bg-indigo-700"
          >
            Activate
          </Button>
          <Button variant="outline" onClick={onClose} className="flex-1 border-slate-600 text-slate-300">
            Cancel
          </Button>
        </div>
      </div>
    </div>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────

const ALL_STATUSES: SubscriptionStatus[] = ['ACTIVE', 'TRIALING', 'GRACE', 'EXPIRED', 'CANCELLED'];

export default function AdminSubscriptionsPage() {
  const { data: subscriptions = [], isLoading } = useAllSubscriptions();
  const { data: plans = [] } = useSubscriptionPlans();

  const [statusFilter, setStatusFilter] = useState<SubscriptionStatus | 'ALL'>('ALL');
  const [activating, setActivating] = useState<OwnerSubscriptionAdmin | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const filtered =
    statusFilter === 'ALL'
      ? subscriptions
      : subscriptions.filter((s) => s.status === statusFilter);

  // Summary stats
  const counts = ALL_STATUSES.reduce(
    (acc, s) => {
      acc[s] = subscriptions.filter((sub) => sub.status === s).length;
      return acc;
    },
    {} as Record<SubscriptionStatus, number>,
  );

  const statCards = [
    { label: 'Active', count: counts.ACTIVE, color: 'text-green-400 bg-green-900' },
    { label: 'Trialing', count: counts.TRIALING, color: 'text-blue-400 bg-blue-900' },
    { label: 'Expired', count: counts.EXPIRED, color: 'text-red-400 bg-red-900' },
    { label: 'Cancelled', count: counts.CANCELLED, color: 'text-slate-400 bg-slate-700' },
  ];

  return (
    <div className="space-y-6">
      {toast && (
        <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />
      )}

      <div>
        <h1 className="text-2xl font-bold text-white">Subscriptions</h1>
        <p className="text-indigo-300 mt-1">Manage owner subscriptions</p>
      </div>

      {/* Summary stats */}
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        {statCards.map((s) => (
          <Card key={s.label} className="bg-slate-900 border-slate-700">
            <CardContent className="pt-5">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-slate-400">{s.label}</p>
                  <p className="text-3xl font-bold text-white mt-0.5">{s.count}</p>
                </div>
                <div className={`h-10 w-10 rounded-lg flex items-center justify-center ${s.color}`}>
                  <Activity className="h-5 w-5" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Filter */}
      <div className="flex items-center gap-2 flex-wrap">
        <span className="text-sm text-slate-400">Filter:</span>
        {(['ALL', ...ALL_STATUSES] as const).map((s) => (
          <button
            key={s}
            onClick={() => setStatusFilter(s)}
            className={`rounded-full px-3 py-1 text-xs font-semibold transition-colors ${
              statusFilter === s
                ? 'bg-indigo-600 text-white'
                : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
            }`}
          >
            {s}
          </button>
        ))}
      </div>

      {/* Table */}
      <Card className="bg-slate-900 border-slate-700">
        <CardHeader>
          <CardTitle className="text-white text-base">
            Owner Subscriptions
            <span className="ml-2 text-sm font-normal text-slate-400">({filtered.length})</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0 overflow-x-auto">
          {isLoading ? (
            <div className="p-4 space-y-2">
              {[1, 2, 3].map((i) => (
                <Skeleton key={i} className="h-10 w-full bg-slate-800" />
              ))}
            </div>
          ) : filtered.length === 0 ? (
            <p className="px-4 py-8 text-center text-sm text-slate-500">
              No subscriptions found.
            </p>
          ) : (
            <table className="w-full">
              <thead>
                <tr className="border-b border-slate-700 text-left">
                  {['Owner ID', 'Plan', 'Status', 'Period End', 'Created', 'Actions'].map(
                    (col) => (
                      <th
                        key={col}
                        className="px-4 py-3 text-xs font-medium uppercase tracking-wide text-slate-500"
                      >
                        {col}
                      </th>
                    ),
                  )}
                </tr>
              </thead>
              <tbody>
                {filtered.map((sub) => (
                  <tr
                    key={sub.owner_id}
                    className="border-b border-slate-800 hover:bg-slate-800/50 transition-colors"
                  >
                    <td className="px-4 py-3 text-sm font-mono text-slate-200">{sub.owner_id}</td>
                    <td className="px-4 py-3 text-sm text-slate-300">
                      {sub.plan?.name ?? <span className="text-slate-600">—</span>}
                    </td>
                    <td className="px-4 py-3">
                      <StatusBadge status={sub.status} />
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-400">
                      {sub.current_period_end
                        ? new Date(sub.current_period_end).toLocaleDateString()
                        : '—'}
                    </td>
                    <td className="px-4 py-3 text-sm text-slate-400">
                      {new Date(sub.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => setActivating(sub)}
                        className="inline-flex items-center gap-1.5 rounded-md bg-indigo-900 px-3 py-1.5 text-xs font-medium text-indigo-300 hover:bg-indigo-800 transition-colors"
                        title="Manually Activate"
                      >
                        <RefreshCw className="h-3.5 w-3.5" />
                        Activate
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </CardContent>
      </Card>

      {activating && (
        <ActivateDialog
          subscription={activating}
          planOptions={plans.map((p) => ({ id: p.id, name: p.name }))}
          onClose={() => setActivating(null)}
          onSuccess={() => showToast(`Subscription activated for owner #${activating.owner_id}.`, 'success')}
          onError={(msg) => showToast(msg, 'error')}
        />
      )}
    </div>
  );
}
