import { useCallback } from 'react';
import { posthog } from '@/lib/posthog';

// ── Typed event catalogue ──────────────────────────────────────────────────
// Add new events here. Everything flows through `capture` but typed callers
// get autocomplete and won't accidentally misname an event.

type AuthEvents = {
  user_signed_up:   { method: 'email' | 'google' | 'github' | 'facebook' };
  user_signed_in:   { method: 'email' | 'google' | 'github' | 'facebook' };
  user_signed_out:  Record<string, never>;
};

type GroundEvents = {
  ground_viewed:     { ground_id: number; ground_name: string; ground_type: string };
  ground_searched:   { query: string; filters: Record<string, unknown>; result_count: number };
  ground_favourited: { ground_id: number; action: 'add' | 'remove' };
};

type BookingEvents = {
  slot_selected:       { ground_id: number; date: string; start_time: string; price: number };
  booking_initiated:   { ground_id: number; date: string; amount: number; payment_method: string };
  booking_confirmed:   { booking_id: number; ground_id: number; amount: number };
  booking_cancelled:   { booking_id: number; reason?: string };
  booking_checkin:     { booking_id: number; ground_id: number };
  waitlist_joined:     { ground_id: number; slot: string };
};

type PaymentEvents = {
  payment_initiated: { amount: number; provider: 'khalti' | 'esewa' | 'stripe' | 'paypal'; context: 'booking' | 'subscription' };
  payment_success:   { amount: number; provider: string; context: 'booking' | 'subscription'; transaction_id: number };
  payment_failed:    { amount: number; provider: string; error?: string };
};

type SubscriptionEvents = {
  subscription_page_viewed: Record<string, never>;
  trial_started:            { plan_id: number; plan_name: string; trial_days: number };
  subscription_activated:   { plan_id: number; plan_name: string; price: number };
  subscription_cancelled:   { plan_id: number; immediately: boolean };
  subscription_expired:     { plan_id: number };
};

type ReviewEvents = {
  review_submitted:  { ground_id: number; rating: number };
  review_helpful:    { review_id: number };
};

type LoyaltyEvents = {
  loyalty_points_redeemed: { points: number; booking_id: number };
};

type StaffEvents = {
  staff_invited: { ground_id: number; role: 'manager' | 'staff' };
  staff_invite_accepted: { ground_id: number; role: string };
};

// Union of all events
type AllEvents =
  & AuthEvents
  & GroundEvents
  & BookingEvents
  & PaymentEvents
  & SubscriptionEvents
  & ReviewEvents
  & LoyaltyEvents
  & StaffEvents;

type EventName = keyof AllEvents;
type EventProperties<E extends EventName> = AllEvents[E];

// ── Hook ──────────────────────────────────────────────────────────────────────

/**
 * Typed wrapper around posthog.capture().
 *
 * Usage:
 *   const { track, setUserProperty } = useAnalytics();
 *   track('booking_confirmed', { booking_id: 42, ground_id: 7, amount: 1500 });
 */
export function useAnalytics() {
  const track = useCallback(
    <E extends EventName>(event: E, properties: EventProperties<E>) => {
      if (typeof window === 'undefined' || !posthog.__loaded) return;
      posthog.capture(event, properties as Record<string, unknown>);
    },
    [],
  );

  const setUserProperty = useCallback((properties: Record<string, unknown>) => {
    if (typeof window === 'undefined' || !posthog.__loaded) return;
    posthog.setPersonProperties(properties);
  }, []);

  const startFeatureFlagEvaluation = useCallback(() => {
    if (typeof window === 'undefined' || !posthog.__loaded) return;
    posthog.reloadFeatureFlags();
  }, []);

  const isFeatureEnabled = useCallback((flag: string): boolean => {
    if (typeof window === 'undefined' || !posthog.__loaded) return false;
    return posthog.isFeatureEnabled(flag) ?? false;
  }, []);

  return { track, setUserProperty, startFeatureFlagEvaluation, isFeatureEnabled };
}
