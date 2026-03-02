'use client';

import { useState, useMemo } from 'react';
import { useGrounds, useGroundBookings, type Booking } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  TrendingUp, Calendar, DollarSign, Users, BarChart2, Clock,
} from 'lucide-react';

// ── Helpers ───────────────────────────────────────────────────────────────────

function isoWeekStart(): string {
  const d = new Date();
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  return d.toISOString().split('T')[0];
}

function monthStart(): string {
  const d = new Date();
  return new Date(d.getFullYear(), d.getMonth(), 1).toISOString().split('T')[0];
}

function revenueFor(bookings: Booking[], from: string, to: string): number {
  return bookings
    .filter((b) => {
      const d = b.booking_date;
      return (b.status === 'confirmed' || b.status === 'completed') && d >= from && d <= to;
    })
    .reduce((s, b) => s + b.total_amount, 0);
}

function hourOf(timeStr: string): number {
  return parseInt(timeStr.split(':')[0], 10);
}

// ── Status badge ──────────────────────────────────────────────────────────────

const STATUS_COLORS: Record<string, string> = {
  pending:   'bg-yellow-100 text-yellow-700',
  confirmed: 'bg-green-100 text-green-700',
  completed: 'bg-blue-100 text-blue-700',
  cancelled: 'bg-red-100 text-red-600',
  no_show:   'bg-gray-100 text-gray-500',
};

// ── Page ──────────────────────────────────────────────────────────────────────

export default function OwnerAnalyticsPage() {
  const { data: grounds = [], isLoading: groundsLoading } = useGrounds();
  const [selectedGroundId, setSelectedGroundId] = useState<number | null>(null);

  const groundId = selectedGroundId ?? grounds[0]?.id ?? 0;

  // Fetch last 200 bookings for analytics
  const { data: bookings = [], isLoading: bookingsLoading } = useGroundBookings(groundId, {});

  const today     = new Date().toISOString().split('T')[0];
  const weekStart = isoWeekStart();
  const monStart  = monthStart();

  const isLoading = groundsLoading || bookingsLoading;

  // Revenue summaries
  const revenueToday = useMemo(() => revenueFor(bookings, today, today), [bookings, today]);
  const revenueWeek  = useMemo(() => revenueFor(bookings, weekStart, today), [bookings, weekStart, today]);
  const revenueMonth = useMemo(() => revenueFor(bookings, monStart, today), [bookings, monStart, today]);

  // Status breakdown
  const statusBreakdown = useMemo(() => {
    const counts: Record<string, number> = {};
    bookings.forEach((b) => { counts[b.status] = (counts[b.status] ?? 0) + 1; });
    return counts;
  }, [bookings]);

  // Peak hours
  const peakHours = useMemo(() => {
    const hours: Record<number, { count: number; revenue: number }> = {};
    bookings
      .filter((b) => b.status === 'confirmed' || b.status === 'completed')
      .forEach((b) => {
        const h = hourOf(b.start_time);
        if (!hours[h]) hours[h] = { count: 0, revenue: 0 };
        hours[h].count++;
        hours[h].revenue += b.total_amount;
      });
    return Object.entries(hours)
      .map(([h, v]) => ({ hour: parseInt(h, 10), ...v }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 10);
  }, [bookings]);

  // Occupancy rate estimate (based on 16 operating hours/day, slot duration assumed 60 min)
  const occupancyRate = useMemo(() => {
    const ground = grounds.find((g) => g.id === groundId);
    if (!ground || bookings.length === 0) return null;

    const uniqueDays = new Set(bookings.map((b) => b.booking_date)).size;
    const slotDuration = ground.slot_duration_minutes ?? 60;
    const slotsPerDay = Math.round((16 * 60) / slotDuration); // estimate 16 operating hrs
    const totalSlots = uniqueDays * slotsPerDay;
    const booked = bookings.filter(
      (b) => b.status === 'confirmed' || b.status === 'completed'
    ).length;
    return totalSlots > 0 ? Math.min(100, Math.round((booked / totalSlots) * 100)) : 0;
  }, [bookings, grounds, groundId]);

  // Recent bookings
  const recentBookings = useMemo(
    () => [...bookings].sort((a, b) => b.booking_date.localeCompare(a.booking_date)).slice(0, 10),
    [bookings]
  );

  if (groundsLoading) {
    return (
      <div className="space-y-6">
        <Skeleton className="h-8 w-48" />
        <div className="grid grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => <Skeleton key={i} className="h-24" />)}
        </div>
      </div>
    );
  }

  if (grounds.length === 0) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-gray-400">No grounds registered yet.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header + ground selector */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Analytics</h1>
          <p className="text-gray-500 text-sm">Booking and revenue insights for your ground</p>
        </div>

        {grounds.length > 1 && (
          <select
            value={selectedGroundId ?? grounds[0]?.id}
            onChange={(e) => setSelectedGroundId(Number(e.target.value))}
            className="border rounded-lg px-3 py-2 text-sm bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {grounds.map((g) => (
              <option key={g.id} value={g.id}>{g.name}</option>
            ))}
          </select>
        )}
      </div>

      {/* Revenue summary cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {[
          { label: 'Today',      value: revenueToday, icon: DollarSign,  color: 'text-green-600 bg-green-50' },
          { label: 'This Week',  value: revenueWeek,  icon: TrendingUp,  color: 'text-blue-600 bg-blue-50'  },
          { label: 'This Month', value: revenueMonth, icon: BarChart2,   color: 'text-purple-600 bg-purple-50' },
        ].map((stat) => (
          <Card key={stat.label}>
            <CardContent className="p-5">
              {isLoading ? (
                <Skeleton className="h-12 w-full" />
              ) : (
                <div className="flex items-center gap-4">
                  <div className={`rounded-full p-3 ${stat.color}`}>
                    <stat.icon className="h-5 w-5" />
                  </div>
                  <div>
                    <p className="text-sm text-gray-500">{stat.label}</p>
                    <p className="text-xl font-bold text-gray-900">
                      NPR {stat.value.toLocaleString()}
                    </p>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {/* Booking status breakdown */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Users className="h-4 w-4 text-gray-400" /> Status Breakdown
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="space-y-2">{[1, 2, 3].map((i) => <Skeleton key={i} className="h-8 w-full" />)}</div>
            ) : (
              <div className="space-y-2">
                {(['confirmed', 'completed', 'cancelled', 'pending', 'no_show'] as const).map((status) => {
                  const count = statusBreakdown[status] ?? 0;
                  const total = bookings.length || 1;
                  return (
                    <div key={status} className="flex items-center gap-3">
                      <span className={`w-20 shrink-0 rounded-full px-2 py-0.5 text-xs font-medium text-center ${STATUS_COLORS[status]}`}>
                        {status.replace('_', ' ')}
                      </span>
                      <div className="flex-1 h-2 rounded-full bg-gray-100">
                        <div
                          className={`h-2 rounded-full transition-all ${
                            status === 'confirmed' ? 'bg-green-400' :
                            status === 'completed' ? 'bg-blue-400' :
                            status === 'cancelled' ? 'bg-red-400' :
                            status === 'pending'   ? 'bg-yellow-400' :
                            'bg-gray-300'
                          }`}
                          style={{ width: `${(count / total) * 100}%` }}
                        />
                      </div>
                      <span className="w-8 shrink-0 text-right text-sm font-medium text-gray-700">{count}</span>
                    </div>
                  );
                })}
              </div>
            )}
          </CardContent>
        </Card>

        {/* Occupancy rate */}
        <Card>
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <Calendar className="h-4 w-4 text-gray-400" /> Occupancy Rate
            </CardTitle>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <Skeleton className="h-24 w-full" />
            ) : occupancyRate === null ? (
              <p className="text-sm text-gray-400">Not enough data yet.</p>
            ) : (
              <div className="text-center py-2">
                <p className="text-5xl font-bold text-gray-900">{occupancyRate}%</p>
                <p className="text-sm text-gray-400 mt-1">of available slots booked</p>
                <div className="mt-4 h-3 rounded-full bg-gray-100">
                  <div
                    className="h-3 rounded-full bg-gradient-to-r from-blue-400 to-indigo-500 transition-all"
                    style={{ width: `${occupancyRate}%` }}
                  />
                </div>
                <p className="text-xs text-gray-400 mt-2">
                  Based on {bookings.length} bookings across {new Set(bookings.map((b) => b.booking_date)).size} days
                </p>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Peak hours */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Clock className="h-4 w-4 text-gray-400" /> Peak Hours
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-6 space-y-2">{[1, 2, 3].map((i) => <Skeleton key={i} className="h-8 w-full" />)}</div>
          ) : peakHours.length === 0 ? (
            <p className="p-6 text-center text-sm text-gray-400">No booking data available.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 text-xs text-gray-400 uppercase tracking-wide">
                    <th className="px-5 py-3 text-left font-medium">Time Slot</th>
                    <th className="px-5 py-3 text-right font-medium">Bookings</th>
                    <th className="px-5 py-3 text-right font-medium">Revenue</th>
                    <th className="px-5 py-3 text-left font-medium">Popularity</th>
                  </tr>
                </thead>
                <tbody>
                  {peakHours.map(({ hour, count, revenue }) => {
                    const maxCount = peakHours[0]?.count ?? 1;
                    const pct = Math.round((count / maxCount) * 100);
                    return (
                      <tr key={hour} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                        <td className="px-5 py-3 font-medium text-gray-800">
                          {String(hour).padStart(2, '0')}:00 – {String(hour + 1).padStart(2, '0')}:00
                        </td>
                        <td className="px-5 py-3 text-right text-gray-700">{count}</td>
                        <td className="px-5 py-3 text-right font-medium text-green-700">
                          NPR {revenue.toLocaleString()}
                        </td>
                        <td className="px-5 py-3">
                          <div className="flex items-center gap-2">
                            <div className="flex-1 h-2 rounded-full bg-gray-100 max-w-xs">
                              <div
                                className="h-2 rounded-full bg-indigo-400"
                                style={{ width: `${pct}%` }}
                              />
                            </div>
                            <span className="text-xs text-gray-400 w-8">{pct}%</span>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Recent bookings */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Recent Bookings</CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-6 space-y-2">{[1, 2, 3].map((i) => <Skeleton key={i} className="h-8 w-full" />)}</div>
          ) : recentBookings.length === 0 ? (
            <p className="p-6 text-center text-sm text-gray-400">No bookings recorded yet.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 text-xs text-gray-400 uppercase tracking-wide">
                    <th className="px-5 py-3 text-left font-medium">Team</th>
                    <th className="px-5 py-3 text-left font-medium">Date</th>
                    <th className="px-5 py-3 text-left font-medium">Time</th>
                    <th className="px-5 py-3 text-left font-medium">Status</th>
                    <th className="px-5 py-3 text-right font-medium">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  {recentBookings.map((b) => (
                    <tr key={b.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                      <td className="px-5 py-3 text-gray-700">
                        {b.team_name ?? <span className="text-gray-400 italic">No team</span>}
                      </td>
                      <td className="px-5 py-3 text-gray-500 whitespace-nowrap">{b.booking_date}</td>
                      <td className="px-5 py-3 text-gray-500 whitespace-nowrap">
                        {b.start_time} – {b.end_time}
                      </td>
                      <td className="px-5 py-3">
                        <span className={`inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium ${
                          STATUS_COLORS[b.status] ?? 'bg-gray-100 text-gray-500'
                        }`}>
                          {b.status.replace('_', ' ')}
                        </span>
                      </td>
                      <td className="px-5 py-3 text-right font-medium text-green-700">
                        NPR {b.total_amount.toLocaleString()}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
