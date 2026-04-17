'use client';

import Link from 'next/link';
import { useAuthStore } from '@/store/auth-store';
import { useMyBookings } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { CalendarDays, CheckCircle2, Clock3, MapPin } from 'lucide-react';
import { Button } from '@/components/ui/button';

export default function DashboardPage() {
  const { user } = useAuthStore();
  const { data: bookings = [], isLoading } = useMyBookings();
  const upcoming = bookings.filter((booking) => booking.status === 'confirmed');
  const completed = bookings.filter((booking) => booking.status === 'completed');
  const cancelled = bookings.filter((booking) => booking.status === 'cancelled');
  const nextBooking = upcoming[0];
  const stats = [
    { name: 'Upcoming', value: upcoming.length, icon: Clock3, color: 'text-green-600 bg-green-50' },
    { name: 'Completed', value: completed.length, icon: CheckCircle2, color: 'text-blue-600 bg-blue-50' },
    { name: 'Cancelled', value: cancelled.length, icon: CalendarDays, color: 'text-red-600 bg-red-50' },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-gray-500">
          Welcome back{user?.first_name ? `, ${user.first_name}` : user?.username ? `, ${user.username}` : ''}!
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {stats.map((stat) => (
          <Card key={stat.name}>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-500">{stat.name}</p>
                  <p className="text-2xl font-bold text-gray-900 mt-1">{stat.value}</p>
                </div>
                <div className={`h-12 w-12 rounded-lg flex items-center justify-center ${stat.color}`}>
                  <stat.icon className="h-6 w-6" />
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-[2fr,1fr] gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Next Booking</CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <p className="text-sm text-gray-400">Loading your bookings...</p>
            ) : nextBooking ? (
              <div className="space-y-3">
                <div>
                  <p className="text-lg font-semibold text-gray-900">{nextBooking.ground_name ?? 'Booked Ground'}</p>
                  <p className="text-sm text-gray-500">{nextBooking.booking_date}</p>
                </div>
                <div className="flex flex-wrap gap-4 text-sm text-gray-600">
                  <span className="flex items-center gap-1"><CalendarDays className="h-4 w-4 text-green-600" />{nextBooking.start_time} - {nextBooking.end_time}</span>
                  {nextBooking.ground_location && (
                    <span className="flex items-center gap-1"><MapPin className="h-4 w-4 text-green-600" />{nextBooking.ground_location}</span>
                  )}
                </div>
                <Link href="/my-bookings">
                  <Button className="mt-2 bg-green-600 hover:bg-green-700">View all bookings</Button>
                </Link>
              </div>
            ) : (
              <div className="space-y-3">
                <p className="text-sm text-gray-500">You have no upcoming bookings yet.</p>
                <Link href="/grounds">
                  <Button className="bg-green-600 hover:bg-green-700">Browse grounds</Button>
                </Link>
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Quick Actions</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Link href="/grounds" className="block rounded-lg border border-gray-200 p-4 hover:bg-gray-50">
              <p className="font-medium text-gray-900">Find a ground</p>
              <p className="text-sm text-gray-500">Search by location, type, and price.</p>
            </Link>
            <Link href="/profile" className="block rounded-lg border border-gray-200 p-4 hover:bg-gray-50">
              <p className="font-medium text-gray-900">Update profile</p>
              <p className="text-sm text-gray-500">Keep your name, email, and password up to date.</p>
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
