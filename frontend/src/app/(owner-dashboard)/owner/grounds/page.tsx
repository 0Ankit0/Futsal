'use client';

import { useGrounds, useUpdateGround } from '@/hooks/use-futsal';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import Link from 'next/link';
import { Plus, MapPin, Star, Clock, CheckCircle, XCircle } from 'lucide-react';

export default function OwnerGroundsPage() {
  const { data: grounds = [], isLoading } = useGrounds();

  if (isLoading) return <div className="text-gray-400">Loading grounds...</div>;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">My Grounds</h1>
        <Link href="/owner/grounds/new">
          <Button className="flex items-center gap-2 bg-green-600 hover:bg-green-700">
            <Plus className="h-4 w-4" />
            Add Ground
          </Button>
        </Link>
      </div>

      {grounds.length === 0 ? (
        <Card>
          <CardContent className="py-12 text-center">
            <MapPin className="mx-auto h-12 w-12 text-gray-300 mb-4" />
            <p className="text-gray-500">You haven&apos;t added any grounds yet.</p>
            <Link href="/owner/grounds/new">
              <Button className="mt-4 bg-green-600 hover:bg-green-700">Add Your First Ground</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {grounds.map((g) => (
            <Card key={g.id} className="hover:shadow-md transition-shadow">
              <CardContent className="p-5 space-y-3">
                <div className="flex items-start justify-between">
                  <h3 className="font-semibold text-lg">{g.name}</h3>
                  <div className="flex gap-1">
                    {g.is_verified ? (
                      <CheckCircle className="h-5 w-5 text-green-500" title="Verified" />
                    ) : (
                      <span className="text-xs text-yellow-600 bg-yellow-50 px-2 py-0.5 rounded-full">
                        Pending Verification
                      </span>
                    )}
                  </div>
                </div>

                <div className="flex items-center gap-1 text-sm text-gray-500">
                  <MapPin className="h-4 w-4" />
                  {g.location}
                </div>

                <div className="flex items-center gap-4 text-sm">
                  <span className="flex items-center gap-1">
                    <Star className="h-4 w-4 text-yellow-500" />
                    {g.average_rating.toFixed(1)} ({g.rating_count})
                  </span>
                  <span className="flex items-center gap-1">
                    <Clock className="h-4 w-4 text-gray-400" />
                    {g.open_time} – {g.close_time}
                  </span>
                </div>

                <div className="flex items-center justify-between pt-1">
                  <span className="font-semibold text-green-600">
                    NPR {g.price_per_hour}/hr
                  </span>
                  <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${
                    g.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                  }`}>
                    {g.is_active ? 'Active' : 'Inactive'}
                  </span>
                </div>

                <div className="flex gap-2 pt-2">
                  <Link href={`/owner/grounds/${g.id}`} className="flex-1">
                    <Button variant="outline" className="w-full text-sm">Edit</Button>
                  </Link>
                  <Link href={`/owner/bookings?ground_id=${g.id}`} className="flex-1">
                    <Button variant="outline" className="w-full text-sm">Bookings</Button>
                  </Link>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
