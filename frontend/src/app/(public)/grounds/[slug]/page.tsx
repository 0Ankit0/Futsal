'use client';

import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { apiClient } from '@/lib/api-client';
import { useAuthStore } from '@/store/auth-store';
import { useAnalytics } from '@/hooks/use-analytics';
import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { MapPin, Star, Clock, CheckCircle, AlertCircle, Lock } from 'lucide-react';
import type { FutsalGround, Slot, Review } from '@/hooks/use-futsal';

const TYPE_COLORS: Record<string, string> = {
  indoor: 'bg-blue-100 text-blue-700',
  outdoor: 'bg-green-100 text-green-700',
  hybrid: 'bg-purple-100 text-purple-700',
};

function StarRating({ rating, count }: { rating: number; count?: number }) {
  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((s) => (
        <Star key={s} className={`h-4 w-4 ${s <= Math.round(rating) ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`} />
      ))}
      <span className="text-sm text-gray-500 ml-1">{rating.toFixed(1)}{count !== undefined && ` (${count})`}</span>
    </div>
  );
}

function GroundDetailClient({ slug }: { slug: string }) {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const today = new Date().toISOString().split('T')[0];
  const [selectedDate, setSelectedDate] = useState(today);
  const [selectedSlot, setSelectedSlot] = useState<Slot | null>(null);
  const { track } = useAnalytics();

  const { data: ground, isLoading: groundLoading } = useQuery({
    queryKey: ['ground-slug', slug],
    queryFn: async () => {
      const { data } = await apiClient.get<FutsalGround>(`/futsal/grounds/${slug}`);
      return data;
    },
    enabled: !!slug,
  });

  useEffect(() => {
    if (ground) {
      track('ground_viewed', { ground_id: ground.id, ground_name: ground.name, ground_type: ground.ground_type });
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ground?.id]);

  const { data: slots, isLoading: slotsLoading } = useQuery({
    queryKey: ['slots', ground?.id, selectedDate],
    queryFn: async () => {
      const { data } = await apiClient.get<Slot[]>(`/futsal/grounds/${ground!.id}/slots`, {
        params: { booking_date: selectedDate },
      });
      return data;
    },
    enabled: !!ground?.id && !!selectedDate,
    refetchInterval: 30_000,
  });

  const { data: reviews } = useQuery({
    queryKey: ['reviews', ground?.id],
    queryFn: async () => {
      const { data } = await apiClient.get<Review[]>(`/futsal/grounds/${ground!.id}/reviews`);
      return data;
    },
    enabled: !!ground?.id,
  });

  if (groundLoading) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-10">
        <div className="grid lg:grid-cols-3 gap-8">
          <div className="lg:col-span-2 space-y-4">
            <Skeleton className="h-10 w-2/3" />
            <Skeleton className="h-5 w-1/3" />
            <Skeleton className="h-32 w-full" />
            <Skeleton className="h-24 w-full" />
          </div>
          <div><Skeleton className="h-96 w-full rounded-xl" /></div>
        </div>
      </div>
    );
  }

  if (!ground) {
    return (
      <div className="max-w-7xl mx-auto px-4 py-24 text-center text-gray-400">
        <AlertCircle className="h-12 w-12 mx-auto mb-4 opacity-40" />
        <p className="text-lg font-medium">Ground not found</p>
      </div>
    );
  }

  const bookingHref = isAuthenticated
    ? `/grounds/${slug}/book?slot_start=${selectedSlot?.start_time}&slot_end=${selectedSlot?.end_time}&date=${selectedDate}&ground_id=${ground.id}`
    : `/login?redirect=/grounds/${slug}`;

  return (
    <div className="max-w-7xl mx-auto px-4 py-10">
      <div className="grid lg:grid-cols-3 gap-8">
        {/* Left section */}
        <div className="lg:col-span-2 space-y-8">
          {/* Header */}
          <div>
            <div className="flex flex-wrap items-center gap-3 mb-2">
              <h1 className="text-3xl font-bold text-gray-900">{ground.name}</h1>
              {ground.is_verified && (
                <span className="inline-flex items-center gap-1 bg-green-100 text-green-700 text-xs font-semibold px-2.5 py-1 rounded-full">
                  <CheckCircle className="h-3.5 w-3.5" /> Verified
                </span>
              )}
              <span className={`text-xs font-medium px-2.5 py-1 rounded-full capitalize ${TYPE_COLORS[ground.ground_type] ?? 'bg-gray-100 text-gray-600'}`}>
                {ground.ground_type}
              </span>
            </div>
            <div className="flex items-center text-gray-500 mb-3">
              <MapPin className="h-4 w-4 mr-1.5 shrink-0" />
              <span>{ground.location}</span>
            </div>
            <StarRating rating={ground.average_rating} count={ground.rating_count} />
          </div>

          {/* Description */}
          {ground.description && (
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-2">About</h2>
              <p className="text-gray-600 leading-relaxed">{ground.description}</p>
            </div>
          )}

          {/* Amenities */}
          {ground.amenities && Object.keys(ground.amenities).length > 0 && (
            <div>
              <h2 className="text-lg font-semibold text-gray-900 mb-3">Amenities</h2>
              <div className="flex flex-wrap gap-2">
                {Object.entries(ground.amenities).map(([key, val]) =>
                  val ? (
                    <span key={key} className="flex items-center gap-1.5 bg-gray-100 text-gray-700 text-sm px-3 py-1.5 rounded-full capitalize">
                      <CheckCircle className="h-3.5 w-3.5 text-green-500" />
                      {key.replace(/_/g, ' ')}
                    </span>
                  ) : null
                )}
              </div>
            </div>
          )}

          {/* Hours & Pricing */}
          <div className="grid sm:grid-cols-2 gap-4">
            <Card>
              <CardContent className="p-4">
                <h3 className="font-semibold text-gray-900 mb-3 flex items-center gap-2">
                  <Clock className="h-4 w-4 text-green-600" /> Operating Hours
                </h3>
                <p className="text-gray-700 text-sm">
                  {ground.open_time} — {ground.close_time}
                </p>
                <p className="text-gray-500 text-xs mt-1">Slot duration: {ground.slot_duration_minutes} min</p>
              </CardContent>
            </Card>
            <Card>
              <CardContent className="p-4">
                <h3 className="font-semibold text-gray-900 mb-3">Pricing</h3>
                <div className="space-y-1 text-sm">
                  <p className="text-gray-700">Base: <span className="font-semibold text-green-700">Rs. {ground.price_per_hour.toLocaleString()}/hr</span></p>
                  {ground.weekend_price_per_hour && (
                    <p className="text-gray-700">Weekend: <span className="font-semibold text-green-700">Rs. {ground.weekend_price_per_hour.toLocaleString()}/hr</span></p>
                  )}
                  {ground.peak_price_multiplier > 1 && (
                    <p className="text-gray-500 text-xs">Peak hours multiplier: {ground.peak_price_multiplier}×
                      {ground.peak_hours_start && ground.peak_hours_end && ` (${ground.peak_hours_start}–${ground.peak_hours_end})`}
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Reviews */}
          <div>
            <h2 className="text-lg font-semibold text-gray-900 mb-4">Reviews</h2>
            {!reviews || reviews.length === 0 ? (
              <p className="text-gray-400 text-sm">No reviews yet.</p>
            ) : (
              <div className="space-y-4">
                {reviews.map((review) => (
                  <Card key={review.id}>
                    <CardContent className="p-4">
                      <div className="flex items-center justify-between mb-2">
                        <StarRating rating={review.rating} />
                        {review.is_verified && (
                          <span className="text-xs text-green-600 font-medium">Verified</span>
                        )}
                      </div>
                      {review.comment && <p className="text-gray-700 text-sm mb-2">{review.comment}</p>}
                      {review.owner_reply && (
                        <div className="mt-3 pl-3 border-l-2 border-green-200 bg-green-50 rounded p-2">
                          <p className="text-xs font-semibold text-green-700 mb-0.5">Owner's reply</p>
                          <p className="text-sm text-gray-600">{review.owner_reply}</p>
                        </div>
                      )}
                    </CardContent>
                  </Card>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Right sticky section */}
        <div className="lg:col-span-1">
          <div className="sticky top-6 space-y-4">
            <Card>
              <CardContent className="p-5">
                <h2 className="text-lg font-semibold text-gray-900 mb-4">Book a Slot</h2>

                {/* Date picker */}
                <div className="mb-4">
                  <label className="block text-sm font-medium text-gray-700 mb-1.5">Select Date</label>
                  <input
                    type="date"
                    min={today}
                    value={selectedDate}
                    onChange={(e) => { setSelectedDate(e.target.value); setSelectedSlot(null); }}
                    className="w-full border border-gray-200 rounded-md px-3 py-2 text-sm text-gray-700 focus:outline-none focus:ring-2 focus:ring-green-500"
                  />
                </div>

                {/* Slot grid */}
                {slotsLoading ? (
                  <div className="grid grid-cols-2 gap-2">
                    {Array.from({ length: 6 }).map((_, i) => <Skeleton key={i} className="h-10 rounded-md" />)}
                  </div>
                ) : !slots || slots.length === 0 ? (
                  <p className="text-sm text-gray-400 text-center py-4">No slots available for this date.</p>
                ) : (
                  <>
                    <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto pr-1">
                      {slots.map((slot) => {
                        const isSelected = selectedSlot?.start_time === slot.start_time;
                        if (slot.is_locked) {
                          return (
                            <button key={slot.start_time} disabled
                              className="flex flex-col items-center justify-center py-2 px-1 rounded-md border border-yellow-200 bg-yellow-50 text-yellow-600 text-xs cursor-not-allowed opacity-80"
                            >
                              <Lock className="h-3 w-3 mb-0.5" />
                              <span>{slot.start_time.slice(0, 5)}</span>
                              <span className="text-yellow-500">Reserved</span>
                            </button>
                          );
                        }
                        if (!slot.is_available) {
                          return (
                            <button key={slot.start_time} disabled
                              className="flex flex-col items-center justify-center py-2 px-1 rounded-md border border-gray-200 bg-gray-100 text-gray-400 text-xs cursor-not-allowed"
                            >
                              <span>{slot.start_time.slice(0, 5)}</span>
                              <span>Unavailable</span>
                            </button>
                          );
                        }
                        return (
                          <button
                            key={slot.start_time}
                            onClick={() => setSelectedSlot(isSelected ? null : slot)}
                            className={`flex flex-col items-center justify-center py-2 px-1 rounded-md border text-xs font-medium transition-colors ${
                              isSelected
                                ? 'border-green-600 bg-green-600 text-white'
                                : 'border-green-300 bg-green-50 text-green-700 hover:bg-green-100'
                            }`}
                          >
                            <span>{slot.start_time.slice(0, 5)}</span>
                            <span className={isSelected ? 'text-green-100' : 'text-green-600'}>Rs. {slot.price}</span>
                          </button>
                        );
                      })}
                    </div>
                    <div className="mt-2 flex gap-2 text-xs text-gray-500 flex-wrap">
                      <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded bg-green-200 inline-block" /> Available</span>
                      <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded bg-yellow-200 inline-block" /> Reserved</span>
                      <span className="flex items-center gap-1"><span className="w-2.5 h-2.5 rounded bg-gray-200 inline-block" /> Unavailable</span>
                    </div>
                  </>
                )}

                {/* Selected slot summary */}
                {selectedSlot && (
                  <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded-md text-sm">
                    <p className="font-semibold text-green-800">Selected Slot</p>
                    <p className="text-gray-700 mt-1">{selectedDate} · {selectedSlot.start_time.slice(0, 5)} – {selectedSlot.end_time.slice(0, 5)}</p>
                    <p className="text-green-700 font-bold mt-1">Rs. {selectedSlot.price.toLocaleString()}</p>
                  </div>
                )}

                  {selectedSlot ? (
                    <Link
                      href={bookingHref}
                      className="w-full mt-4 inline-flex items-center justify-center font-medium rounded-lg transition-colors bg-green-600 hover:bg-green-700 text-white px-4 py-2"
                    >
                      Book Now
                    </Link>
                  ) : (
                    <button
                      disabled
                      className="w-full mt-4 inline-flex items-center justify-center font-medium rounded-lg bg-green-600 text-white px-4 py-2 opacity-50 cursor-not-allowed"
                    >
                      Select a Slot
                    </button>
                  )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  );
}

export default function GroundDetailPage({ params }: { params: { slug: string } }) {
  return <GroundDetailClient slug={params.slug} />;
}
