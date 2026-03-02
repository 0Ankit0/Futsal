'use client';

import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Wallet, RefreshCw, PauseCircle, Info, DollarSign } from 'lucide-react';

// ── Types ─────────────────────────────────────────────────────────────────────

type PayoutMode   = 'PLATFORM' | 'DIRECT';
type PayoutStatus = 'pending' | 'processing' | 'completed' | 'failed' | 'on_hold';
type ModeFilter   = 'ALL' | 'PLATFORM' | 'DIRECT';

interface PayoutModeResponse {
  mode: PayoutMode;
  description?: string;
}

interface PlatformBalance {
  total_gross: number;
  total_fee: number;
  total_owed: number;
  currency: string;
}

interface PayoutRecord {
  id: number;
  owner_id: number;
  period_start: string;
  period_end: string;
  total_bookings: number;
  gross_amount: number;
  platform_fee: number;
  net_amount: number;
  currency: string;
  status: PayoutStatus;
  payout_mode?: PayoutMode;
  transaction_ref?: string;
  retry_count: number;
  created_at: string;
}

// ── Status & Mode badges ───────────────────────────────────────────────────────

const STATUS_BADGE: Record<PayoutStatus, string> = {
  pending:    'bg-yellow-50 text-yellow-700',
  processing: 'bg-blue-50 text-blue-700',
  completed:  'bg-green-50 text-green-700',
  failed:     'bg-red-50 text-red-600',
  on_hold:    'bg-orange-50 text-orange-700',
};

const MODE_BADGE: Record<PayoutMode, string> = {
  PLATFORM: 'bg-purple-50 text-purple-700',
  DIRECT:   'bg-cyan-50 text-cyan-700',
};

// ── Page ──────────────────────────────────────────────────────────────────────

export default function AdminPayoutsPage() {
  const qc = useQueryClient();
  const [modeFilter, setModeFilter] = useState<ModeFilter>('ALL');
  const [statusFilter, setStatusFilter] = useState<string>('all');

  const { data: payoutMode, isLoading: modeLoading } = useQuery({
    queryKey: ['payout-mode'],
    queryFn: async () => {
      const { data } = await apiClient.get<PayoutModeResponse>('/payout-mgmt/payout/mode');
      return data;
    },
  });

  const { data: platformBalance, isLoading: balanceLoading } = useQuery({
    queryKey: ['platform-balance'],
    queryFn: async () => {
      const { data } = await apiClient.get<PlatformBalance>('/payout-mgmt/payout/platform-balance');
      return data;
    },
    enabled: payoutMode?.mode === 'PLATFORM',
  });

  const { data: records = [], isLoading: recordsLoading, isError: recordsError } = useQuery({
    queryKey: ['payout-records'],
    queryFn: async () => {
      const { data } = await apiClient.get<PayoutRecord[]>('/payout-mgmt/payout/records');
      return data;
    },
  });

  const retryPayout = useMutation({
    mutationFn: async (id: number) => {
      const { data } = await apiClient.patch(`/payout-mgmt/payout/records/${id}/retry`);
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payout-records'] }),
  });

  const holdPayout = useMutation({
    mutationFn: async (id: number) => {
      const { data } = await apiClient.patch(`/payout-mgmt/payout/records/${id}/hold`);
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payout-records'] }),
  });

  // Filter records
  const filtered = useMemo(() => {
    return records.filter((r) => {
      const matchMode =
        modeFilter === 'ALL' ? true : r.payout_mode === modeFilter;
      const matchStatus =
        statusFilter === 'all' ? true : r.status === statusFilter;
      return matchMode && matchStatus;
    });
  }, [records, modeFilter, statusFilter]);

  const currency = platformBalance?.currency ?? records[0]?.currency ?? 'NPR';

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Payouts Oversight</h1>
        <p className="text-gray-500 text-sm">Monitor and manage all owner payout records</p>
      </div>

      {/* Top row: Payout mode + Platform balance */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        {/* Payout mode card */}
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Payout Mode</CardTitle>
          </CardHeader>
          <CardContent>
            {modeLoading ? (
              <Skeleton className="h-10 w-40" />
            ) : payoutMode ? (
              <div className="flex items-start gap-3">
                <span className={`rounded-full px-3 py-1 text-sm font-bold ${
                  MODE_BADGE[payoutMode.mode] ?? 'bg-gray-100 text-gray-700'
                }`}>
                  {payoutMode.mode}
                </span>
                <div>
                  <p className="text-sm text-gray-600">
                    {payoutMode.mode === 'PLATFORM'
                      ? 'Platform collects payments and disburses to owners.'
                      : 'Owners receive payments directly from customers.'}
                  </p>
                  <div className="mt-2 flex items-center gap-1 text-xs text-gray-400">
                    <Info className="h-3.5 w-3.5" />
                    Change via <code className="font-mono bg-gray-100 px-1 rounded">PAYOUT_MODE</code> in .env
                  </div>
                </div>
              </div>
            ) : (
              <p className="text-sm text-red-500">Failed to load payout mode.</p>
            )}
          </CardContent>
        </Card>

        {/* Platform balance card (only shown in PLATFORM mode) */}
        {payoutMode?.mode === 'PLATFORM' && (
          <Card>
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-500">Platform Balance</CardTitle>
            </CardHeader>
            <CardContent>
              {balanceLoading ? (
                <Skeleton className="h-16 w-full" />
              ) : platformBalance ? (
                <div className="grid grid-cols-3 gap-4 text-center">
                  {[
                    { label: 'Gross',      value: platformBalance.total_gross,  color: 'text-gray-900' },
                    { label: 'Fee',        value: platformBalance.total_fee,    color: 'text-red-600' },
                    { label: 'Owed to Owners', value: platformBalance.total_owed, color: 'text-green-700' },
                  ].map((item) => (
                    <div key={item.label}>
                      <p className={`text-lg font-bold ${item.color}`}>
                        {currency} {item.value.toLocaleString()}
                      </p>
                      <p className="text-xs text-gray-400 mt-0.5">{item.label}</p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-sm text-red-500">Failed to load balance.</p>
              )}
            </CardContent>
          </Card>
        )}

        {/* Placeholder for DIRECT mode */}
        {payoutMode?.mode === 'DIRECT' && (
          <Card>
            <CardContent className="p-5 flex items-center gap-3 text-gray-500">
              <DollarSign className="h-8 w-8 text-cyan-400" />
              <div>
                <p className="font-medium text-gray-700">Direct Mode Active</p>
                <p className="text-sm">Owners are paid directly. Platform does not hold funds.</p>
              </div>
            </CardContent>
          </Card>
        )}
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        {/* Mode filter tabs */}
        <div className="flex gap-1 rounded-lg border border-gray-200 bg-gray-50 p-1">
          {(['ALL', 'PLATFORM', 'DIRECT'] as ModeFilter[]).map((m) => (
            <button
              key={m}
              onClick={() => setModeFilter(m)}
              className={`rounded-md px-3 py-1.5 text-xs font-medium transition-colors ${
                modeFilter === m
                  ? 'bg-white shadow-sm text-gray-900'
                  : 'text-gray-500 hover:text-gray-700'
              }`}
            >
              {m}
            </button>
          ))}
        </div>

        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="border rounded-lg px-3 py-2 text-sm bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="all">All Statuses</option>
          <option value="pending">Pending</option>
          <option value="processing">Processing</option>
          <option value="completed">Completed</option>
          <option value="failed">Failed</option>
          <option value="on_hold">On Hold</option>
        </select>
      </div>

      {/* Records table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Wallet className="h-4 w-4 text-gray-400" />
            Payout Records
            <span className="text-sm font-normal text-gray-400 ml-1">({filtered.length})</span>
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {recordsLoading ? (
            <div className="p-6 space-y-3">
              {[1, 2, 3, 4].map((i) => <Skeleton key={i} className="h-10 w-full" />)}
            </div>
          ) : recordsError ? (
            <p className="p-6 text-center text-red-500 text-sm">Failed to load payout records.</p>
          ) : filtered.length === 0 ? (
            <p className="p-8 text-center text-gray-400 text-sm">No payout records found.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 text-xs text-gray-400 uppercase tracking-wide">
                    <th className="px-4 py-3 text-left font-medium">Owner</th>
                    <th className="px-4 py-3 text-left font-medium">Period</th>
                    <th className="px-4 py-3 text-right font-medium">Bookings</th>
                    <th className="px-4 py-3 text-right font-medium">Gross</th>
                    <th className="px-4 py-3 text-right font-medium">Fee</th>
                    <th className="px-4 py-3 text-right font-medium">Net</th>
                    <th className="px-4 py-3 text-left font-medium">Status</th>
                    <th className="px-4 py-3 text-left font-medium">Mode</th>
                    <th className="px-4 py-3 text-left font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((record) => (
                    <tr key={record.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                      <td className="px-4 py-3 text-gray-500">#{record.owner_id}</td>
                      <td className="px-4 py-3 whitespace-nowrap text-xs text-gray-500">
                        {record.period_start} → {record.period_end}
                      </td>
                      <td className="px-4 py-3 text-right text-gray-700">{record.total_bookings}</td>
                      <td className="px-4 py-3 text-right font-medium">
                        {record.currency} {record.gross_amount.toLocaleString()}
                      </td>
                      <td className="px-4 py-3 text-right text-red-500">
                        {record.currency} {record.platform_fee.toLocaleString()}
                      </td>
                      <td className="px-4 py-3 text-right font-semibold text-green-700">
                        {record.currency} {record.net_amount.toLocaleString()}
                      </td>
                      <td className="px-4 py-3">
                        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                          STATUS_BADGE[record.status] ?? 'bg-gray-100 text-gray-500'
                        }`}>
                          {record.status.replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-4 py-3">
                        {record.payout_mode && (
                          <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                            MODE_BADGE[record.payout_mode] ?? 'bg-gray-100 text-gray-500'
                          }`}>
                            {record.payout_mode}
                          </span>
                        )}
                      </td>
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          {(record.status === 'failed' || record.status === 'on_hold') && (
                            <button
                              onClick={() => retryPayout.mutate(record.id)}
                              disabled={retryPayout.isPending && retryPayout.variables === record.id}
                              className="inline-flex items-center gap-1 rounded-lg border border-blue-200 bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-700 hover:bg-blue-100 transition-colors disabled:opacity-50"
                            >
                              <RefreshCw className="h-3.5 w-3.5" />
                              Retry
                            </button>
                          )}
                          {record.status === 'processing' && (
                            <button
                              onClick={() => holdPayout.mutate(record.id)}
                              disabled={holdPayout.isPending && holdPayout.variables === record.id}
                              className="inline-flex items-center gap-1 rounded-lg border border-orange-200 bg-orange-50 px-2.5 py-1 text-xs font-medium text-orange-700 hover:bg-orange-100 transition-colors disabled:opacity-50"
                            >
                              <PauseCircle className="h-3.5 w-3.5" />
                              Hold
                            </button>
                          )}
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
