'use client';

import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { Award, TrendingUp, TrendingDown, Info } from 'lucide-react';

// ── Types ─────────────────────────────────────────────────────────────────────

interface LoyaltyBalance {
  points_balance: number;
  tier: 'BRONZE' | 'SILVER' | 'GOLD' | 'PLATINUM';
  tier_name: string;
  next_tier_points: number;
}

interface LoyaltyTransaction {
  id: number;
  points: number;
  type: 'EARNED' | 'REDEEMED' | 'EXPIRED' | 'ADJUSTED';
  description: string;
  created_at: string;
  booking_id?: number;
}

// ── Tier config ───────────────────────────────────────────────────────────────

const TIER_CONFIG: Record<string, { color: string; bg: string; thresholds: [number, number] }> = {
  BRONZE:   { color: 'text-amber-700',   bg: 'bg-amber-100',   thresholds: [0,   500]  },
  SILVER:   { color: 'text-slate-600',   bg: 'bg-slate-100',   thresholds: [500, 1500] },
  GOLD:     { color: 'text-yellow-600',  bg: 'bg-yellow-100',  thresholds: [1500, 3000] },
  PLATINUM: { color: 'text-purple-700',  bg: 'bg-purple-100',  thresholds: [3000, 3000] },
};

// ── Page ──────────────────────────────────────────────────────────────────────

export default function LoyaltyPage() {
  const {
    data: balance,
    isLoading: balanceLoading,
    isError: balanceError,
  } = useQuery({
    queryKey: ['loyalty-balance'],
    queryFn: async () => {
      const { data } = await apiClient.get<LoyaltyBalance>('/futsal/loyalty/balance');
      return data;
    },
  });

  const {
    data: history = [],
    isLoading: historyLoading,
    isError: historyError,
  } = useQuery({
    queryKey: ['loyalty-history'],
    queryFn: async () => {
      const { data } = await apiClient.get<LoyaltyTransaction[]>('/futsal/loyalty/history');
      return data;
    },
  });

  const tier         = balance?.tier ?? 'BRONZE';
  const tierCfg      = TIER_CONFIG[tier] ?? TIER_CONFIG.BRONZE;
  const [min, max]   = tierCfg.thresholds;
  const current      = balance?.points_balance ?? 0;
  const progress     = max > min ? Math.min(100, ((current - min) / (max - min)) * 100) : 100;
  const nextPoints   = balance?.next_tier_points ?? 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Loyalty Rewards</h1>
        <p className="text-gray-500 text-sm">Earn points on every booking and unlock exclusive rewards</p>
      </div>

      {/* Balance card */}
      {balanceLoading ? (
        <Card><CardContent className="p-8"><Skeleton className="h-32 w-full" /></CardContent></Card>
      ) : balanceError ? (
        <Card><CardContent className="p-6 text-center text-red-500">Failed to load loyalty balance.</CardContent></Card>
      ) : balance && (
        <Card className="overflow-hidden">
          <div className="bg-gradient-to-r from-blue-600 to-indigo-600 p-6 text-white">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-blue-200 text-sm font-medium">Total Points</p>
                <p className="text-5xl font-bold mt-1">{current.toLocaleString()}</p>
                <p className="text-blue-200 text-sm mt-1">points</p>
              </div>
              <div className="flex items-center gap-2">
                <Award className="h-8 w-8 text-yellow-300" />
                <span className={`rounded-full px-3 py-1 text-sm font-semibold ${tierCfg.bg} ${tierCfg.color}`}>
                  {balance.tier_name}
                </span>
              </div>
            </div>

            {/* Progress to next tier */}
            {tier !== 'PLATINUM' && (
              <div className="mt-5">
                <div className="flex justify-between text-xs text-blue-200 mb-1.5">
                  <span>{tier}</span>
                  <span>
                    {nextPoints > 0
                      ? `${nextPoints.toLocaleString()} pts to next tier`
                      : 'Max tier reached'}
                  </span>
                </div>
                <div className="h-2 rounded-full bg-blue-400/40">
                  <div
                    className="h-2 rounded-full bg-white transition-all duration-500"
                    style={{ width: `${progress}%` }}
                  />
                </div>
              </div>
            )}
            {tier === 'PLATINUM' && (
              <p className="mt-4 text-blue-200 text-sm">🏆 You&apos;ve reached the highest tier!</p>
            )}
          </div>
        </Card>
      )}

      {/* Info box */}
      <div className="flex gap-3 rounded-xl border border-blue-100 bg-blue-50 p-4">
        <Info className="h-5 w-5 text-blue-500 flex-shrink-0 mt-0.5" />
        <div className="text-sm text-blue-700">
          <p className="font-medium">How it works</p>
          <p className="mt-0.5">
            Earn <strong>10 points</strong> per confirmed booking.
            Redeem <strong>100 points = NPR 50 off</strong> your next booking at checkout.
          </p>
        </div>
      </div>

      {/* Transaction history */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Point History</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {historyLoading ? (
            <div className="p-6 space-y-3">
              {[1, 2, 3].map((i) => <Skeleton key={i} className="h-10 w-full" />)}
            </div>
          ) : historyError ? (
            <p className="p-6 text-center text-red-500 text-sm">Failed to load history.</p>
          ) : history.length === 0 ? (
            <div className="p-12 text-center">
              <Award className="mx-auto h-10 w-10 text-gray-200 mb-3" />
              <p className="text-gray-400 text-sm">No transactions yet. Make a booking to earn points!</p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 text-xs text-gray-400 uppercase tracking-wide">
                    <th className="px-5 py-3 text-left font-medium">Date</th>
                    <th className="px-5 py-3 text-left font-medium">Description</th>
                    <th className="px-5 py-3 text-left font-medium">Type</th>
                    <th className="px-5 py-3 text-right font-medium">Points</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map((tx) => (
                    <tr key={tx.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                      <td className="px-5 py-3 text-gray-500 whitespace-nowrap">
                        {new Date(tx.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-5 py-3 text-gray-700">{tx.description}</td>
                      <td className="px-5 py-3">
                        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                          tx.type === 'EARNED'   ? 'bg-green-50 text-green-700' :
                          tx.type === 'REDEEMED' ? 'bg-orange-50 text-orange-700' :
                          tx.type === 'EXPIRED'  ? 'bg-gray-100 text-gray-500' :
                          'bg-blue-50 text-blue-700'
                        }`}>
                          {tx.type}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-right font-semibold whitespace-nowrap">
                        {tx.type === 'EARNED' || tx.type === 'ADJUSTED' ? (
                          <span className="flex items-center justify-end gap-0.5 text-green-600">
                            <TrendingUp className="h-3.5 w-3.5" />
                            +{tx.points}
                          </span>
                        ) : (
                          <span className="flex items-center justify-end gap-0.5 text-red-500">
                            <TrendingDown className="h-3.5 w-3.5" />
                            -{tx.points}
                          </span>
                        )}
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
