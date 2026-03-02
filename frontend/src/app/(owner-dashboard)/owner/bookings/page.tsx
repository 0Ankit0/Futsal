'use client';

import { useState } from 'react';
import { useGrounds, useGroundBookings, type Booking } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Calendar, Search } from 'lucide-react';

const STATUS_COLORS: Record<string, string> = {
  pending:   'bg-yellow-100 text-yellow-700',
  confirmed: 'bg-green-100 text-green-700',
  completed: 'bg-blue-100 text-blue-700',
  cancelled: 'bg-red-100 text-red-700',
  no_show:   'bg-gray-100 text-gray-500',
};

export default function OwnerBookingsPage() {
  const today = new Date().toISOString().split('T')[0];
  const [selectedDate, setSelectedDate] = useState(today);
  const [selectedGroundId, setSelectedGroundId] = useState<number | null>(null);

  const { data: grounds = [] } = useGrounds();
  const groundId = selectedGroundId ?? grounds[0]?.id ?? 0;
  const { data: bookings = [], isLoading } = useGroundBookings(groundId, {
    booking_date: selectedDate,
  });

  const totalRevenue = bookings
    .filter((b) => ['confirmed', 'completed'].includes(b.status))
    .reduce((s, b) => s + b.total_amount, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Bookings</h1>

      {/* Filters */}
      <div className="flex flex-wrap gap-4">
        <select
          className="border rounded-lg px-3 py-2 text-sm"
          value={selectedGroundId ?? ''}
          onChange={(e) => setSelectedGroundId(e.target.value ? Number(e.target.value) : null)}
        >
          {grounds.map((g) => (
            <option key={g.id} value={g.id}>{g.name}</option>
          ))}
        </select>

        <Input
          type="date"
          value={selectedDate}
          onChange={(e) => setSelectedDate(e.target.value)}
          className="w-44"
        />
      </div>

      {/* Summary */}
      <div className="grid grid-cols-3 gap-4">
        {['confirmed', 'completed', 'cancelled'].map((status) => {
          const count = bookings.filter((b) => b.status === status).length;
          return (
            <Card key={status}>
              <CardContent className="p-4 text-center">
                <p className="text-2xl font-bold">{count}</p>
                <p className="text-sm text-gray-500 capitalize">{status}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Bookings table */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>
              {bookings.length} booking{bookings.length !== 1 ? 's' : ''} — NPR {totalRevenue.toLocaleString()} revenue
            </CardTitle>
          </div>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <p className="text-gray-400">Loading...</p>
          ) : bookings.length === 0 ? (
            <p className="text-gray-400">No bookings for this date.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-gray-500">
                    <th className="pb-2 font-medium">Time</th>
                    <th className="pb-2 font-medium">Team</th>
                    <th className="pb-2 font-medium">Amount</th>
                    <th className="pb-2 font-medium">Paid</th>
                    <th className="pb-2 font-medium">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {bookings.map((b) => (
                    <tr key={b.id}>
                      <td className="py-3 font-medium">{b.start_time} – {b.end_time}</td>
                      <td className="py-3 text-gray-600">{b.team_name || '—'}</td>
                      <td className="py-3">NPR {b.total_amount}</td>
                      <td className="py-3">NPR {b.paid_amount}</td>
                      <td className="py-3">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[b.status] ?? ''}`}>
                          {b.status}
                        </span>
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
