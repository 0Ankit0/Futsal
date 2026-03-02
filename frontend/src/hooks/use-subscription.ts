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
      return data;
    },
  });
}

export function useSubscriptionPlans() {
  return useQuery({
    queryKey: ['subscription-plans'],
    queryFn: async () => {
      const { data } = await apiClient.get<SubscriptionPlan[]>('/subscriptions/plans');
      return data;
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
