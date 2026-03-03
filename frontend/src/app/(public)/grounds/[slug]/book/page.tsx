'use client';

import { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { useAuthStore } from '@/store/auth-store';
import { useAnalytics } from '@/hooks/use-analytics';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Skeleton } from '@/components/ui/skeleton';
import { MapPin, Clock, AlertCircle, CalendarDays } from 'lucide-react';
import type { FutsalGround, Booking } from '@/hooks/use-futsal';

const PAYMENT_METHODS = [
  { id: 'khalti', label: 'Khalti', logo: '💜' },
  { id: 'esewa', label: 'eSewa', logo: '💚' },
] as const;

type PaymentMethod = (typeof PAYMENT_METHODS)[number]['id'];

export default function BookingPage({ params }: { params: { slug: string } }) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const _hasHydrated = useAuthStore((s) => s._hasHydrated);
  const { track } = useAnalytics();

  const groundId = searchParams.get('ground_id');
  const slotStart = searchParams.get('slot_start') ?? '';
  const slotEnd = searchParams.get('slot_end') ?? '';
  const date = searchParams.get('date') ?? '';

  const [teamName, setTeamName] = useState('');
  const [notes, setNotes] = useState('');
  const [useLoyalty, setUseLoyalty] = useState(false);
  const [paymentMethod, setPaymentMethod] = useState<PaymentMethod>('khalti');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (_hasHydrated && !isAuthenticated) {
      router.replace(`/login?redirect=/grounds/${params.slug}/book?ground_id=${groundId}&slot_start=${slotStart}&slot_end=${slotEnd}&date=${date}`);
    }
  }, [_hasHydrated, isAuthenticated]);

  const { data: ground, isLoading } = useQuery({
    queryKey: ['ground-slug', params.slug],
    queryFn: async () => {
      const { data } = await apiClient.get<FutsalGround>(`/futsal/grounds/${params.slug}`);
      return data;
    },
    enabled: !!params.slug,
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!ground) return;
    setError('');
    setIsSubmitting(true);

    try {
      const { data: booking } = await apiClient.post<Booking>('/futsal/bookings', {
        ground_id: ground.id,
        booking_date: date,
        start_time: slotStart,
        end_time: slotEnd,
        team_name: teamName || undefined,
        notes: notes || undefined,
        ...(useLoyalty && { loyalty_points_to_redeem: 1 }),
      });

      track('booking_initiated', { ground_id: ground.id, ground_name: ground.name, date, slot_start: slotStart, slot_end: slotEnd, payment_method: paymentMethod });

      const { data: payment } = await apiClient.post('/payments/initiate', {
        booking_id: booking.id,
        payment_method: paymentMethod,
        return_url: `${window.location.origin}/booking/${booking.id}/confirmation`,
      });

      track('payment_initiated', { amount: booking.total_amount ?? 0, provider: paymentMethod, context: 'booking' });

      if (payment?.payment_url) {
        window.location.href = payment.payment_url;
      } else {
        router.push(`/booking/${booking.id}/confirmation`);
      }
    } catch (err: unknown) {
      const axiosErr = err as { response?: { status?: number } };
      if (axiosErr?.response?.status === 409) {
        setError('This slot was just taken. Please select another.');
      } else if (axiosErr?.response?.status === 402) {
        setError('Payment required. Please ensure your account is set up for payments.');
      } else {
        setError('Something went wrong. Please try again.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!_hasHydrated || isLoading) {
    return (
      <div className="max-w-2xl mx-auto px-4 py-12 space-y-4">
        <Skeleton className="h-10 w-1/2" />
        <Skeleton className="h-48 w-full rounded-xl" />
        <Skeleton className="h-64 w-full rounded-xl" />
      </div>
    );
  }

  if (!ground || !groundId || !slotStart || !slotEnd || !date) {
    return (
      <div className="max-w-2xl mx-auto px-4 py-24 text-center text-gray-400">
        <AlertCircle className="h-12 w-12 mx-auto mb-4 opacity-40" />
        <p className="text-lg font-medium">Invalid booking details.</p>
        <a href={`/grounds/${params.slug}`}
          className="inline-flex items-center justify-center font-medium rounded-lg transition-colors border border-gray-300 bg-transparent hover:bg-gray-100 px-4 py-2 mt-4 text-base text-gray-700"
        >
          Back to Ground
        </a>
      </div>
    );
  }

  // Compute duration in minutes from start/end times
  const toMinutes = (t: string) => {
    const [h, m] = t.split(':').map(Number);
    return h * 60 + m;
  };
  const durationMin = toMinutes(slotEnd) - toMinutes(slotStart);
  const durationHr = durationMin / 60;

  // Estimate price
  const estimatedPrice = Math.round(ground.price_per_hour * durationHr);

  return (
    <div className="max-w-2xl mx-auto px-4 py-10">
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Complete Your Booking</h1>

      {/* Booking summary */}
      <Card className="mb-6 border-green-200 bg-green-50">
        <CardContent className="p-5">
          <h2 className="text-base font-semibold text-green-800 mb-3">Booking Summary</h2>
          <div className="space-y-2 text-sm text-gray-700">
            <div className="flex items-center gap-2">
              <MapPin className="h-4 w-4 text-green-600 shrink-0" />
              <span className="font-medium">{ground.name}</span>
            </div>
            <div className="flex items-center gap-2">
              <CalendarDays className="h-4 w-4 text-green-600 shrink-0" />
              <span>{date}</span>
            </div>
            <div className="flex items-center gap-2">
              <Clock className="h-4 w-4 text-green-600 shrink-0" />
              <span>{slotStart.slice(0, 5)} – {slotEnd.slice(0, 5)} ({durationMin} min)</span>
            </div>
            <div className="border-t border-green-200 pt-2 mt-2 flex justify-between font-semibold text-green-800">
              <span>Total Amount</span>
              <span>Rs. {estimatedPrice.toLocaleString()}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Form */}
      <form onSubmit={handleSubmit}>
        <Card className="mb-6">
          <CardContent className="p-5 space-y-4">
            <h2 className="text-base font-semibold text-gray-900">Additional Details</h2>
            <div>
              <Label htmlFor="team_name" className="text-sm font-medium text-gray-700">Team Name <span className="text-gray-400">(optional)</span></Label>
              <Input
                id="team_name"
                placeholder="e.g. Thunder FC"
                value={teamName}
                onChange={(e) => setTeamName(e.target.value)}
                className="mt-1.5"
              />
            </div>
            <div>
              <Label htmlFor="notes" className="text-sm font-medium text-gray-700">Notes <span className="text-gray-400">(optional)</span></Label>
              <textarea
                id="notes"
                rows={3}
                placeholder="Any special requests..."
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
                className="mt-1.5 w-full border border-gray-200 rounded-md px-3 py-2 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-green-500 resize-none"
              />
            </div>
            <label className="flex items-center gap-2 cursor-pointer">
              <input
                type="checkbox"
                checked={useLoyalty}
                onChange={(e) => setUseLoyalty(e.target.checked)}
                className="accent-green-600 h-4 w-4"
              />
              <span className="text-sm text-gray-700">Use loyalty points</span>
            </label>
          </CardContent>
        </Card>

        {/* Payment method */}
        <Card className="mb-6">
          <CardContent className="p-5">
            <h2 className="text-base font-semibold text-gray-900 mb-3">Payment Method</h2>
            <div className="grid grid-cols-2 gap-3">
              {PAYMENT_METHODS.map((pm) => (
                <button
                  key={pm.id}
                  type="button"
                  onClick={() => setPaymentMethod(pm.id)}
                  className={`flex items-center justify-center gap-2 p-3 rounded-lg border-2 text-sm font-medium transition-colors ${
                    paymentMethod === pm.id
                      ? 'border-green-600 bg-green-50 text-green-800'
                      : 'border-gray-200 text-gray-600 hover:border-gray-300'
                  }`}
                >
                  <span className="text-xl">{pm.logo}</span>
                  {pm.label}
                </button>
              ))}
            </div>
          </CardContent>
        </Card>

        {error && (
          <div className="flex items-center gap-2 p-4 mb-4 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
            <AlertCircle className="h-4 w-4 shrink-0" />
            {error}
          </div>
        )}

        <Button
          type="submit"
          disabled={isSubmitting}
          className="w-full bg-green-600 hover:bg-green-700 text-white font-semibold py-3 text-base"
        >
          {isSubmitting ? 'Processing...' : `Confirm & Pay via ${paymentMethod === 'khalti' ? 'Khalti' : 'eSewa'}`}
        </Button>
      </form>
    </div>
  );
}
