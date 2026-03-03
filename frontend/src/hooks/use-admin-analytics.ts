import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';

// ── Types ──────────────────────────────────────────────────────────────────

export interface AdminAnalyticsSummary {
  users: {
    total: number;
    new_last_30d: number;
    new_last_7d: number;
  };
  grounds: {
    total: number;
    verified: number;
    total_owners: number;
  };
  bookings: {
    today: number;
    last_7d: number;
    last_30d: number;
  };
  revenue: {
    platform_fee_30d: number;
    gross_30d: number;
    subscription_monthly: number;
  };
  payouts: {
    on_hold: number;
    failed: number;
    completed_30d: number;
  };
  subscriptions: {
    active: number;
  };
}

export interface DailyTrendPoint {
  date: string;
  bookings: number;
  revenue: number;
}

export interface AdminDailyTrend {
  trend: DailyTrendPoint[];
  days: number;
}

// ── Hooks ──────────────────────────────────────────────────────────────────

export function useAdminAnalyticsSummary() {
  return useQuery<AdminAnalyticsSummary>({
    queryKey: ['admin', 'analytics', 'summary'],
    queryFn: () => apiClient.get<AdminAnalyticsSummary>('/futsal/admin/analytics/summary'),
    staleTime: 5 * 60 * 1000, // 5 min
    refetchOnWindowFocus: false,
  });
}

export function useAdminDailyTrend(days: number = 30) {
  return useQuery<AdminDailyTrend>({
    queryKey: ['admin', 'analytics', 'daily-trend', days],
    queryFn: () =>
      apiClient.get<AdminDailyTrend>(`/futsal/admin/analytics/daily-trend?days=${days}`),
    staleTime: 5 * 60 * 1000,
    refetchOnWindowFocus: false,
  });
}
