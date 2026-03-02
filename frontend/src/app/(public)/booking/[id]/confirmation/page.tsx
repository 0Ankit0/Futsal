'use client';

import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { Card, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import { CheckCircle2, XCircle, Clock, MapPin, CalendarDays, Download, ArrowRight, AlertCircle } from 'lucide-react';
import type { Booking } from '@/hooks/use-futsal';

function generateICSLink(booking: Booking & { ground_name?: string }): string {
  const pad = (n: number) => String(n).padStart(2, '0');
  const dateStr = booking.booking_date.replace(/-/g, '');
  const startParts = booking.start_time.split(':').map(Number);
  const endParts = booking.end_time.split(':').map(Number);
  const dtStart = `${dateStr}T${pad(startParts[0])}${pad(startParts[1])}00`;
  const dtEnd = `${dateStr}T${pad(endParts[0])}${pad(endParts[1])}00`;
  const ics = [
    'BEGIN:VCALENDAR',
    'VERSION:2.0',
    'BEGIN:VEVENT',
    `DTSTART:${dtStart}`,
    `DTEND:${dtEnd}`,
    `SUMMARY:Futsal at ${booking.ground_name ?? 'Ground'}`,
    `DESCRIPTION:Booking ID: ${booking.id}`,
    'END:VEVENT',
    'END:VCALENDAR',
  ].join('\r\n');
  return `data:text/calendar;charset=utf8,${encodeURIComponent(ics)}`;
}

const STATUS_CONFIG = {
  confirmed: {
    icon: <CheckCircle2 className="h-20 w-20 text-green-500" />,
    title: 'Booking Confirmed!',
    subtitle: 'Your slot is reserved. Show the QR code at the ground.',
    color: 'text-green-700',
    bg: 'bg-green-50',
    border: 'border-green-200',
  },
  pending: {
    icon: <Clock className="h-20 w-20 text-yellow-500" />,
    title: 'Booking Pending',
    subtitle: 'Your booking is awaiting confirmation. Please complete payment.',
    color: 'text-yellow-700',
    bg: 'bg-yellow-50',
    border: 'border-yellow-200',
  },
  cancelled: {
    icon: <XCircle className="h-20 w-20 text-red-400" />,
    title: 'Booking Cancelled',
    subtitle: 'This booking has been cancelled.',
    color: 'text-red-700',
    bg: 'bg-red-50',
    border: 'border-red-200',
  },
  completed: {
    icon: <CheckCircle2 className="h-20 w-20 text-blue-500" />,
    title: 'Booking Completed',
    subtitle: 'Thanks for playing! We hope you had a great game.',
    color: 'text-blue-700',
    bg: 'bg-blue-50',
    border: 'border-blue-200',
  },
  no_show: {
    icon: <AlertCircle className="h-20 w-20 text-gray-400" />,
    title: 'No Show',
    subtitle: 'This booking was marked as no show.',
    color: 'text-gray-600',
    bg: 'bg-gray-50',
    border: 'border-gray-200',
  },
};

type BookingWithGround = Booking & { ground_name?: string; ground_location?: string };

export default function BookingConfirmationPage({ params }: { params: { id: string } }) {
  const { data: booking, isLoading, isError } = useQuery({
    queryKey: ['booking', params.id],
    queryFn: async () => {
      const { data } = await apiClient.get<BookingWithGround>(`/futsal/bookings/${params.id}`);
      return data;
    },
    enabled: !!params.id,
  });

  if (isLoading) {
    return (
      <div className="max-w-lg mx-auto px-4 py-16 space-y-4">
        <Skeleton className="h-24 w-24 rounded-full mx-auto" />
        <Skeleton className="h-8 w-2/3 mx-auto" />
        <Skeleton className="h-48 w-full rounded-xl" />
        <Skeleton className="h-36 w-full rounded-xl" />
      </div>
    );
  }

  if (isError || !booking) {
    return (
      <div className="max-w-lg mx-auto px-4 py-24 text-center text-gray-400">
        <AlertCircle className="h-14 w-14 mx-auto mb-4 opacity-40" />
        <p className="text-lg font-medium">Booking not found.</p>
        <Link href="/grounds" className="inline-flex items-center justify-center font-medium rounded-lg transition-colors border border-gray-300 bg-transparent hover:bg-gray-100 px-4 py-2 mt-4 text-base text-gray-700">
          Browse Grounds
        </Link>
      </div>
    );
  }

  const config = STATUS_CONFIG[booking.status] ?? STATUS_CONFIG.pending;
  const icsLink = generateICSLink(booking);

  return (
    <div className="max-w-lg mx-auto px-4 py-12">
      {/* Status hero */}
      <div className={`flex flex-col items-center text-center py-10 px-6 rounded-2xl border mb-6 ${config.bg} ${config.border}`}>
        {config.icon}
        <h1 className={`text-2xl font-bold mt-4 ${config.color}`}>{config.title}</h1>
        <p className="text-gray-500 mt-2 text-sm max-w-xs">{config.subtitle}</p>
      </div>

      {/* Booking details */}
      <Card className="mb-4">
        <CardContent className="p-5 space-y-3">
          <h2 className="text-base font-semibold text-gray-900">Booking Details</h2>
          <div className="text-sm text-gray-500 space-y-2">
            <div className="flex justify-between">
              <span className="text-gray-500">Booking ID</span>
              <span className="font-mono font-medium text-gray-800">#{booking.id}</span>
            </div>
            {booking.ground_name && (
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1.5 text-gray-500"><MapPin className="h-3.5 w-3.5" /> Ground</span>
                <span className="font-medium text-gray-800">{booking.ground_name}</span>
              </div>
            )}
            <div className="flex items-center justify-between">
              <span className="flex items-center gap-1.5 text-gray-500"><CalendarDays className="h-3.5 w-3.5" /> Date</span>
              <span className="font-medium text-gray-800">{booking.booking_date}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="flex items-center gap-1.5 text-gray-500"><Clock className="h-3.5 w-3.5" /> Time</span>
              <span className="font-medium text-gray-800">
                {booking.start_time.slice(0, 5)} – {booking.end_time.slice(0, 5)}
              </span>
            </div>
            {booking.team_name && (
              <div className="flex items-center justify-between">
                <span className="text-gray-500">Team</span>
                <span className="font-medium text-gray-800">{booking.team_name}</span>
              </div>
            )}
            <div className="border-t pt-2 flex justify-between font-semibold text-gray-900">
              <span>Amount Paid</span>
              <span className="text-green-700">Rs. {booking.paid_amount.toLocaleString()}</span>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* QR Code */}
      {booking.qr_code && booking.status === 'confirmed' && (
        <Card className="mb-6">
          <CardContent className="p-5 flex flex-col items-center">
            <h2 className="text-base font-semibold text-gray-900 mb-3">Entry QR Code</h2>
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src={booking.qr_code}
              alt="Booking QR Code"
              className="w-48 h-48 object-contain border rounded-lg p-2 bg-white"
            />
            <p className="text-xs text-gray-400 mt-2">Show this at the ground for entry</p>
          </CardContent>
        </Card>
      )}

      {/* Actions */}
      <div className="flex flex-col gap-3">
        {booking.status === 'confirmed' && (
          <a
            href={icsLink}
            download={`futsal-booking-${booking.id}.ics`}
            className="flex items-center justify-center gap-2 w-full border border-gray-200 rounded-lg py-3 text-sm font-medium text-gray-700 hover:bg-gray-50 transition-colors"
          >
            <Download className="h-4 w-4" />
            Add to Calendar
          </a>
        )}
        <Link href="/my-bookings" className="inline-flex items-center justify-center w-full font-medium rounded-lg transition-colors border border-gray-300 bg-transparent hover:bg-gray-100 px-4 py-2 text-base text-gray-700">
          View My Bookings <ArrowRight className="ml-2 h-4 w-4" />
        </Link>
        <Link href="/grounds" className="inline-flex items-center justify-center w-full font-medium rounded-lg transition-colors bg-green-600 hover:bg-green-700 text-white px-4 py-2 text-base">
          Book Again
        </Link>
      </div>
    </div>
  );
}
