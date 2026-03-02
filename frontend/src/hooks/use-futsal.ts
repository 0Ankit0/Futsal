import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';

// ── Types ──────────────────────────────────────────────────────────────────

export interface FutsalGround {
  id: number;
  name: string;
  slug: string;
  owner_id: number;
  location: string;
  latitude?: number;
  longitude?: number;
  description?: string;
  ground_type: 'indoor' | 'outdoor' | 'hybrid';
  price_per_hour: number;
  weekend_price_per_hour?: number;
  peak_hours_start?: string;
  peak_hours_end?: string;
  peak_price_multiplier: number;
  open_time: string;
  close_time: string;
  slot_duration_minutes: number;
  is_active: boolean;
  is_verified: boolean;
  average_rating: number;
  rating_count: number;
  amenities?: Record<string, boolean | string>;
}

export interface Slot {
  start_time: string;
  end_time: string;
  is_available: boolean;
  is_locked: boolean;
  price: number;
}

export interface Booking {
  id: number;
  user_id: number;
  ground_id: number;
  booking_date: string;
  start_time: string;
  end_time: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled' | 'no_show';
  total_amount: number;
  paid_amount: number;
  team_name?: string;
  notes?: string;
  qr_code: string;
  is_recurring: boolean;
  cancellation_reason?: string;
}

export interface Review {
  id: number;
  user_id: number;
  ground_id: number;
  booking_id: number;
  rating: number;
  comment?: string;
  image_url?: string;
  owner_reply?: string;
  is_verified: boolean;
}

export interface PayoutRecord {
  id: number;
  owner_id: number;
  period_start: string;
  period_end: string;
  total_bookings: number;
  gross_amount: number;
  platform_fee: number;
  net_amount: number;
  currency: string;
  status: 'pending' | 'processing' | 'completed' | 'failed' | 'on_hold';
  transaction_ref?: string;
  retry_count: number;
  created_at: string;
}

export interface LoyaltyAccount {
  points_balance: number;
  total_earned: number;
  total_redeemed: number;
}

// ── Ground Hooks ───────────────────────────────────────────────────────────

export function useGrounds(params?: {
  location?: string;
  min_price?: number;
  max_price?: number;
  ground_type?: string;
  verified_only?: boolean;
}) {
  return useQuery({
    queryKey: ['grounds', params],
    queryFn: async () => {
      const { data } = await apiClient.get<FutsalGround[]>('/futsal/grounds', { params });
      return data;
    },
  });
}

export function useGround(id: number) {
  return useQuery({
    queryKey: ['ground', id],
    queryFn: async () => {
      const { data } = await apiClient.get<FutsalGround>(`/futsal/grounds/${id}`);
      return data;
    },
    enabled: !!id,
  });
}

export function useGroundSlots(groundId: number, date: string) {
  return useQuery({
    queryKey: ['slots', groundId, date],
    queryFn: async () => {
      const { data } = await apiClient.get<Slot[]>(`/futsal/grounds/${groundId}/slots`, {
        params: { booking_date: date },
      });
      return data;
    },
    enabled: !!groundId && !!date,
    staleTime: 30_000, // re-fetch every 30s to show real-time availability
    refetchInterval: 30_000,
  });
}

export function useCreateGround() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: Partial<FutsalGround>) => {
      const res = await apiClient.post<FutsalGround>('/futsal/grounds', data);
      return res.data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['grounds'] }),
  });
}

export function useUpdateGround(id: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: Partial<FutsalGround>) => {
      const res = await apiClient.put<FutsalGround>(`/futsal/grounds/${id}`, data);
      return res.data;
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['ground', id] });
      qc.invalidateQueries({ queryKey: ['grounds'] });
    },
  });
}

// ── Booking Hooks ──────────────────────────────────────────────────────────

export function useMyBookings(params?: { status_filter?: string }) {
  return useQuery({
    queryKey: ['my-bookings', params],
    queryFn: async () => {
      const { data } = await apiClient.get<Booking[]>('/futsal/bookings', { params });
      return data;
    },
  });
}

export function useGroundBookings(groundId: number, params?: { booking_date?: string; status_filter?: string }) {
  return useQuery({
    queryKey: ['ground-bookings', groundId, params],
    queryFn: async () => {
      const { data } = await apiClient.get<Booking[]>(`/futsal/grounds/${groundId}/bookings`, { params });
      return data;
    },
    enabled: !!groundId,
  });
}

export function useCreateBooking() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: {
      ground_id: number;
      booking_date: string;
      start_time: string;
      end_time: string;
      team_name?: string;
      notes?: string;
      loyalty_points_to_redeem?: number;
    }) => {
      const res = await apiClient.post<Booking>('/futsal/bookings', data);
      return res.data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['my-bookings'] }),
  });
}

export function useCancelBooking() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ bookingId, reason }: { bookingId: number; reason?: string }) => {
      const res = await apiClient.patch<Booking>(`/futsal/bookings/${bookingId}/cancel`, null, {
        params: { reason },
      });
      return res.data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['my-bookings'] }),
  });
}

// ── Review Hooks ───────────────────────────────────────────────────────────

export function useGroundReviews(groundId: number) {
  return useQuery({
    queryKey: ['reviews', groundId],
    queryFn: async () => {
      const { data } = await apiClient.get<Review[]>(`/futsal/grounds/${groundId}/reviews`);
      return data;
    },
    enabled: !!groundId,
  });
}

export function useReplyToReview() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async ({ reviewId, reply }: { reviewId: number; reply: string }) => {
      const res = await apiClient.post<Review>(`/futsal/reviews/${reviewId}/reply`, { reply });
      return res.data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['reviews'] }),
  });
}

// ── Loyalty Hooks ──────────────────────────────────────────────────────────

export function useLoyalty() {
  return useQuery({
    queryKey: ['loyalty'],
    queryFn: async () => {
      const { data } = await apiClient.get<LoyaltyAccount>('/futsal/loyalty');
      return data;
    },
  });
}

export function useLoyaltyHistory() {
  return useQuery({
    queryKey: ['loyalty-history'],
    queryFn: async () => {
      const { data } = await apiClient.get('/futsal/loyalty/history');
      return data;
    },
  });
}

// ── Payout Hooks ───────────────────────────────────────────────────────────

export function usePayoutHistory() {
  return useQuery({
    queryKey: ['payout-history'],
    queryFn: async () => {
      const { data } = await apiClient.get<PayoutRecord[]>('/payout-mgmt/payout/history');
      return data;
    },
  });
}

export function usePayoutLedger(settled?: boolean) {
  return useQuery({
    queryKey: ['payout-ledger', settled],
    queryFn: async () => {
      const { data } = await apiClient.get('/payout-mgmt/payout/ledger', {
        params: settled !== undefined ? { settled } : {},
      });
      return data;
    },
  });
}

export function usePendingBalance() {
  return useQuery({
    queryKey: ['pending-balance'],
    queryFn: async () => {
      const { data } = await apiClient.get<{
        pending_amount: number;
        pending_bookings: number;
        currency: string;
      }>('/payout-mgmt/payout/pending-balance');
      return data;
    },
  });
}

export function usePayoutGateway() {
  return useQuery({
    queryKey: ['payout-gateway'],
    queryFn: async () => {
      const { data } = await apiClient.get('/payout-mgmt/payout/gateway');
      return data;
    },
  });
}

export function useConfigureGateway() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (data: {
      provider: string;
      account_name: string;
      credentials: Record<string, string>;
    }) => {
      try {
        const res = await apiClient.post('/payout-mgmt/payout/gateway', data);
        return res.data;
      } catch {
        const res = await apiClient.put('/payout-mgmt/payout/gateway', data);
        return res.data;
      }
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['payout-gateway'] }),
  });
}
