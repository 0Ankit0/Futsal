'use client';

import { useState } from 'react';
import { useMyBookings, useCancelBooking, type Booking } from '@/hooks/use-futsal';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { Skeleton } from '@/components/ui/skeleton';
import { Calendar, Clock, MapPin, X } from 'lucide-react';
import Link from 'next/link';

// ── Types ─────────────────────────────────────────────────────────────────────

type FilterTab = 'all' | 'upcoming' | 'completed' | 'cancelled';

const STATUS_COLORS: Record<string, string> = {
  pending:   'bg-yellow-100 text-yellow-700',
  confirmed: 'bg-green-100 text-green-700',
  completed: 'bg-blue-100 text-blue-700',
  cancelled: 'bg-red-100 text-red-600',
  no_show:   'bg-gray-100 text-gray-500',
};

function BookingCard({
  booking,
  onCancel,
}: {
  booking: Booking;
  onCancel: (b: Booking) => void;
}) {
  const isUpcoming = booking.status === 'confirmed' || booking.status === 'pending';

  return (
    <Card className="hover:shadow-md transition-shadow">
      <CardContent className="p-5">
        <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3">
          {/* Left: info */}
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span
                className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                  STATUS_COLORS[booking.status] ?? 'bg-gray-100 text-gray-500'
                }`}
              >
                {booking.status.replace('_', ' ')}
              </span>
              {booking.team_name && (
                <span className="text-xs text-gray-400 truncate">· {booking.team_name}</span>
              )}
            </div>

            <p className="text-base font-semibold text-gray-900 truncate">{booking.ground_name ?? `Ground #${booking.ground_id}`}</p>

            <div className="mt-1.5 flex flex-wrap gap-x-4 gap-y-1 text-sm text-gray-500">
              <span className="flex items-center gap-1">
                <Calendar className="h-3.5 w-3.5" />
                {booking.booking_date}
              </span>
                <span className="flex items-center gap-1">
                  <Clock className="h-3.5 w-3.5" />
                  {booking.start_time} – {booking.end_time}
                </span>
                {booking.ground_location && (
                  <span className="flex items-center gap-1">
                    <MapPin className="h-3.5 w-3.5" />
                    {booking.ground_location}
                  </span>
                )}
              </div>

            <p className="mt-2 text-sm font-medium text-green-700">
              NPR {booking.total_amount.toLocaleString()}
            </p>
          </div>

          {/* Right: actions */}
            <div className="flex flex-wrap gap-2 sm:flex-col sm:items-end">
              {isUpcoming && (
                <button
                  onClick={() => onCancel(booking)}
                className="inline-flex items-center gap-1.5 rounded-lg border border-red-200 px-3 py-1.5 text-xs font-medium text-red-500 hover:bg-red-50 transition-colors"
              >
                  <X className="h-3.5 w-3.5" /> Cancel
                </button>
              )}
            </div>
          </div>
      </CardContent>
    </Card>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

const TABS: { key: FilterTab; label: string }[] = [
  { key: 'all',       label: 'All' },
  { key: 'upcoming',  label: 'Upcoming' },
  { key: 'completed', label: 'Completed' },
  { key: 'cancelled', label: 'Cancelled' },
];

export default function MyBookingsPage() {
  const [activeTab, setActiveTab]           = useState<FilterTab>('all');
  const [cancelTarget, setCancelTarget]     = useState<Booking | null>(null);

  const { data: bookings = [], isLoading, isError } = useMyBookings();
  const cancelBooking = useCancelBooking();

  // Filter bookings by active tab
  const filtered = bookings.filter((b) => {
    if (activeTab === 'all')       return true;
    if (activeTab === 'upcoming')  return b.status === 'confirmed' || b.status === 'pending';
    if (activeTab === 'completed') return b.status === 'completed';
    if (activeTab === 'cancelled') return b.status === 'cancelled' || b.status === 'no_show';
    return true;
  });

  const tabCount = (tab: FilterTab) =>
    tab === 'all'       ? bookings.length
    : tab === 'upcoming'  ? bookings.filter((b) => b.status === 'confirmed' || b.status === 'pending').length
    : tab === 'completed' ? bookings.filter((b) => b.status === 'completed').length
    : bookings.filter((b) => b.status === 'cancelled' || b.status === 'no_show').length;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">My Bookings</h1>
        <p className="text-gray-500 text-sm">Manage and track all your futsal bookings</p>
      </div>

      {/* Filter tabs */}
      <div className="flex gap-1 border-b border-gray-200">
        {TABS.map((tab) => (
          <button
            key={tab.key}
            onClick={() => setActiveTab(tab.key)}
            className={`px-4 py-2 text-sm font-medium transition-colors border-b-2 -mb-px ${
              activeTab === tab.key
                ? 'border-blue-600 text-blue-600'
                : 'border-transparent text-gray-500 hover:text-gray-700'
            }`}
          >
            {tab.label}
            <span className={`ml-1.5 rounded-full px-1.5 py-0.5 text-xs ${
              activeTab === tab.key ? 'bg-blue-100 text-blue-600' : 'bg-gray-100 text-gray-500'
            }`}>
              {tabCount(tab.key)}
            </span>
          </button>
        ))}
      </div>

      {/* Content */}
      {isLoading ? (
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <Card key={i}><CardContent className="p-5"><Skeleton className="h-24 w-full" /></CardContent></Card>
          ))}
        </div>
      ) : isError ? (
        <Card>
          <CardContent className="p-8 text-center text-red-500">
            Failed to load bookings. Please try again.
          </CardContent>
        </Card>
      ) : filtered.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Calendar className="mx-auto h-12 w-12 text-gray-300 mb-4" />
            <p className="text-gray-500 font-medium">No bookings yet</p>
            <p className="text-sm text-gray-400 mb-6">Book a futsal ground to get started</p>
            <Link href="/grounds">
              <Button>Browse Grounds</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {filtered.map((booking) => (
            <BookingCard
              key={booking.id}
              booking={booking}
              onCancel={setCancelTarget}
            />
          ))}
        </div>
      )}

      {/* Cancel confirm dialog */}
      <ConfirmDialog
        open={!!cancelTarget}
        title="Cancel Booking"
        description={
          cancelTarget
            ? `Cancel booking on ${cancelTarget.booking_date} at ${cancelTarget.start_time}? This action cannot be undone.`
            : ''
        }
        confirmLabel="Yes, Cancel"
        isLoading={cancelBooking.isPending}
        onConfirm={() => {
          if (!cancelTarget) return;
          cancelBooking.mutate(
            { bookingId: cancelTarget.id, reason: 'Cancelled by user' },
            { onSuccess: () => setCancelTarget(null) }
          );
        }}
        onCancel={() => setCancelTarget(null)}
      />
    </div>
  );
}
