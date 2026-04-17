'use client';

import { useAuthStore } from '@/store/auth-store';
import { useMyGrounds, useGroundBookings } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { MapPin, Calendar, TrendingUp } from 'lucide-react';
import Link from 'next/link';

export default function OwnerDashboardPage() {
  const { user } = useAuthStore();
  const { data: grounds = [] } = useMyGrounds();
  const today = new Date().toISOString().split('T')[0];
  const { data: todaysBookings = [] } = useGroundBookings(
    grounds[0]?.id ?? 0,
    { booking_date: today }
  );

  const confirmedToday = todaysBookings.filter((b) => b.status === 'confirmed').length;
  const revenueToday = todaysBookings
    .filter((b) => ['confirmed', 'completed'].includes(b.status))
    .reduce((sum, b) => sum + b.total_amount, 0);

  const stats = [
    {
      name: "Today's Bookings",
      value: String(confirmedToday),
      icon: Calendar,
      href: '/owner/bookings',
      color: 'text-blue-600 bg-blue-50',
    },
    {
      name: "Today's Revenue",
      value: `NPR ${revenueToday.toLocaleString()}`,
      icon: TrendingUp,
      href: '/owner/bookings',
      color: 'text-purple-600 bg-purple-50',
    },
    {
      name: 'My Grounds',
      value: String(grounds.length),
      icon: MapPin,
      href: '/owner/grounds',
      color: 'text-orange-600 bg-orange-50',
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Owner Dashboard</h1>
        <p className="text-gray-500">
          Welcome back{user?.first_name ? `, ${user.first_name}` : ''}!
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {stats.map((stat) => (
          <Link key={stat.name} href={stat.href}>
            <Card className="hover:shadow-md transition-shadow cursor-pointer">
              <CardContent className="p-6">
                <div className="flex items-center gap-4">
                  <div className={`rounded-full p-3 ${stat.color}`}>
                    <stat.icon className="h-6 w-6" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">{stat.name}</p>
                    <p className="text-2xl font-bold">{stat.value}</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      {/* Today's bookings list */}
      <Card>
        <CardHeader>
          <CardTitle>Today&apos;s Bookings</CardTitle>
        </CardHeader>
        <CardContent>
          {todaysBookings.length === 0 ? (
            <p className="text-gray-400 text-sm">No bookings today.</p>
          ) : (
            <div className="space-y-2">
              {todaysBookings.map((b) => (
                <div key={b.id} className="flex items-center justify-between border-b pb-2">
                  <div>
                    <span className="font-medium">{b.start_time} – {b.end_time}</span>
                    {b.team_name && (
                      <span className="ml-2 text-sm text-gray-500">({b.team_name})</span>
                    )}
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-sm font-medium text-green-600">
                      NPR {b.total_amount}
                    </span>
                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium
                      ${b.status === 'confirmed' ? 'bg-green-100 text-green-700' :
                        b.status === 'completed' ? 'bg-blue-100 text-blue-700' :
                        b.status === 'cancelled' ? 'bg-red-100 text-red-700' :
                        'bg-yellow-100 text-yellow-700'}`}>
                      {b.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
