import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';

// ── Types ──────────────────────────────────────────────────────────────────

export type SubscriptionStatus = 'ACTIVE' | 'TRIALING' | 'GRACE' | 'EXPIRED' | 'CANCELLED';

export interface SubscriptionPlan {
  id: number;
  name: string;
  slug: string;
  price_monthly: number;
  max_grounds: number;
  max_staff: number;
  trial_days: number;
  features: string[];
  is_active: boolean;
}

type RawSubscriptionPlan = Omit<SubscriptionPlan, 'features'> & {
  features: string[] | string | null;
};

function normalizeFeatures(features: RawSubscriptionPlan['features']): string[] {
  if (Array.isArray(features)) {
    return features.filter((item): item is string => typeof item === 'string');
  }
  if (typeof features !== 'string' || features.trim() === '') {
    return [];
  }

  try {
    const parsed: unknown = JSON.parse(features);
    if (Array.isArray(parsed)) {
      return parsed.filter((item): item is string => typeof item === 'string');
    }
  } catch {
    // Fall back to comma/newline separated values.
  }

  return features
    .split(/[\n,]/)
    .map((item) => item.trim())
    .filter(Boolean);
}

function normalizePlan(plan: RawSubscriptionPlan): SubscriptionPlan {
  return {
    ...plan,
    features: normalizeFeatures(plan.features),
  };
}

export interface OwnerSubscription {
  status: SubscriptionStatus;
  plan: SubscriptionPlan | null;
  current_period_end: string | null;
  trial_ends_at: string | null;
  cancel_at_period_end: boolean;
  is_active: boolean;
}

export interface OwnerSubscriptionAdmin {
  owner_id: number;
  plan: SubscriptionPlan | null;
  status: SubscriptionStatus;
  current_period_end: string | null;
  created_at: string;
}

// ── Hooks ──────────────────────────────────────────────────────────────────

export function useSubscription() {
  return useQuery({
    queryKey: ['subscription', 'me'],
    queryFn: async () => {
      const { data } = await apiClient.get<OwnerSubscription>('/subscriptions/me');
      if (!data.plan) {
        return data;
      }
      return {
        ...data,
        plan: normalizePlan(data.plan as RawSubscriptionPlan),
      };
    },
  });
}

export function useSubscriptionPlans() {
  return useQuery({
    queryKey: ['subscription-plans'],
    queryFn: async () => {
      const { data } = await apiClient.get<RawSubscriptionPlan[]>('/subscriptions/plans');
      return data.map(normalizePlan);
    },
  });
}

export function useStartTrial(planId: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async () => {
      const { data } = await apiClient.post(`/subscriptions/trial/${planId}`);
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscription'] }),
  });
}

export function useVerifyPayment() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: {
      plan_id: number;
      transaction_id: string;
      provider_token: string;
    }) => {
      const { data } = await apiClient.post('/subscriptions/verify-payment', payload);
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscription'] }),
  });
}

export function useCancelSubscription() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (immediately: boolean) => {
      const { data } = await apiClient.post('/subscriptions/cancel', null, {
        params: { immediately },
      });
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscription'] }),
  });
}

export function useAllSubscriptions() {
  return useQuery({
    queryKey: ['subscriptions', 'admin', 'all'],
    queryFn: async () => {
      const { data } =
        await apiClient.get<OwnerSubscriptionAdmin[]>('/subscriptions/admin/all');
      return data;
    },
  });
}

export function useActivateSubscription() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ ownerId, planId }: { ownerId: number; planId: number }) => {
      const { data } = await apiClient.patch(
        `/subscriptions/admin/${ownerId}/activate`,
        null,
        { params: { plan_id: planId } },
      );
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['subscriptions', 'admin'] }),
  });
}
