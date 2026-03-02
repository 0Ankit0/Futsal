'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { MapPin, Star, Search } from 'lucide-react';
import type { FutsalGround } from '@/hooks/use-futsal';

const LIMIT = 9;

const GROUND_TYPE_OPTIONS = [
  { value: '', label: 'All Types' },
  { value: 'indoor', label: 'Indoor' },
  { value: 'outdoor', label: 'Outdoor' },
  { value: 'hybrid', label: 'Hybrid' },
];

const TYPE_COLORS: Record<string, string> = {
  indoor: 'bg-blue-100 text-blue-700',
  outdoor: 'bg-green-100 text-green-700',
  hybrid: 'bg-purple-100 text-purple-700',
};

function GroundCardSkeleton() {
  return (
    <Card className="overflow-hidden">
      <Skeleton className="h-44 w-full rounded-none" />
      <CardContent className="p-4 space-y-2">
        <Skeleton className="h-5 w-3/4" />
        <Skeleton className="h-4 w-1/2" />
        <Skeleton className="h-4 w-1/3" />
      </CardContent>
    </Card>
  );
}

function StarRating({ rating }: { rating: number }) {
  return (
    <div className="flex items-center gap-1">
      {[1, 2, 3, 4, 5].map((s) => (
        <Star
          key={s}
          className={`h-4 w-4 ${s <= Math.round(rating) ? 'text-yellow-400 fill-yellow-400' : 'text-gray-300'}`}
        />
      ))}
      <span className="text-xs text-gray-500 ml-1">{rating.toFixed(1)}</span>
    </div>
  );
}

export default function GroundsPage() {
  const [search, setSearch] = useState('');
  const [groundType, setGroundType] = useState('');
  const [minPrice, setMinPrice] = useState('');
  const [maxPrice, setMaxPrice] = useState('');
  const [skip, setSkip] = useState(0);
  const [allGrounds, setAllGrounds] = useState<FutsalGround[]>([]);
  const [hasMore, setHasMore] = useState(true);
  const [filterKey, setFilterKey] = useState(0);

  const queryParams = {
    ...(search && { search }),
    ...(groundType && { ground_type: groundType }),
    ...(minPrice && { min_price: Number(minPrice) }),
    ...(maxPrice && { max_price: Number(maxPrice) }),
    skip,
    limit: LIMIT,
  };

  const { data, isLoading, isFetching } = useQuery<FutsalGround[]>({
    queryKey: ['grounds-browse', filterKey, skip],
    queryFn: async () => {
      const { data } = await apiClient.get<FutsalGround[]>('/futsal/grounds', { params: queryParams });
      return data;
    },
  });

  useEffect(() => {
    if (!data) return;
    if (skip === 0) {
      setAllGrounds(data);
    } else {
      setAllGrounds((prev) => [...prev, ...data]);
    }
    setHasMore(data.length === LIMIT);
  }, [data, skip]);

  const handleFilter = () => {
    setSkip(0);
    setAllGrounds([]);
    setFilterKey((k) => k + 1);
  };

  const loadMore = () => setSkip((prev) => prev + LIMIT);

  return (
    <div className="max-w-7xl mx-auto px-4 py-10">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Browse Grounds</h1>
        <p className="text-gray-500">Find and book the perfect futsal ground for your game.</p>
      </div>

      {/* Filter bar */}
      <div className="bg-white border rounded-xl p-4 mb-8 flex flex-wrap gap-3 items-end shadow-sm">
        <div className="relative flex-1 min-w-[200px]">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            placeholder="Search grounds..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <select
          value={groundType}
          onChange={(e) => setGroundType(e.target.value)}
          className="border border-gray-200 rounded-md px-3 py-2 text-sm text-gray-700 bg-white focus:outline-none focus:ring-2 focus:ring-green-500 min-w-[140px]"
        >
          {GROUND_TYPE_OPTIONS.map((opt) => (
            <option key={opt.value} value={opt.value}>{opt.label}</option>
          ))}
        </select>
        <Input
          type="number"
          placeholder="Min price"
          value={minPrice}
          onChange={(e) => setMinPrice(e.target.value)}
          className="w-28"
        />
        <Input
          type="number"
          placeholder="Max price"
          value={maxPrice}
          onChange={(e) => setMaxPrice(e.target.value)}
          className="w-28"
        />
        <Button onClick={handleFilter} className="bg-green-600 hover:bg-green-700 text-white">
          Search
        </Button>
      </div>

      {/* Skeleton loading */}
      {isLoading && (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
          {Array.from({ length: 9 }).map((_, i) => <GroundCardSkeleton key={i} />)}
        </div>
      )}

      {/* Empty state */}
      {!isLoading && allGrounds.length === 0 && (
        <div className="text-center py-24 text-gray-400">
          <MapPin className="h-12 w-12 mx-auto mb-4 opacity-40" />
          <p className="text-lg font-medium">No grounds found</p>
          <p className="text-sm mt-1">Try adjusting your search or filters.</p>
        </div>
      )}

      {/* Ground cards */}
      {!isLoading && allGrounds.length > 0 && (
        <>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {allGrounds.map((ground) => (
              <Link key={ground.id} href={`/grounds/${ground.slug}`}>
                <Card className="overflow-hidden hover:shadow-lg transition-shadow cursor-pointer h-full">
                  {/* Image placeholder */}
                  <div className="h-44 bg-gray-200 flex items-center justify-center">
                    <MapPin className="h-10 w-10 text-gray-400" />
                  </div>
                  <CardContent className="p-4">
                    <div className="flex items-start justify-between mb-1">
                      <h3 className="font-semibold text-gray-900 text-base leading-tight">{ground.name}</h3>
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ml-2 shrink-0 capitalize ${TYPE_COLORS[ground.ground_type] ?? 'bg-gray-100 text-gray-600'}`}>
                        {ground.ground_type}
                      </span>
                    </div>
                    <div className="flex items-center text-gray-500 text-sm mb-2">
                      <MapPin className="h-3.5 w-3.5 mr-1 shrink-0" />
                      <span className="truncate">{ground.location}</span>
                    </div>
                    <StarRating rating={ground.average_rating} />
                    <div className="mt-3 flex items-center justify-between">
                      <p className="text-green-700 font-bold text-sm">
                        Rs. {ground.price_per_hour.toLocaleString()}<span className="text-gray-400 font-normal">/hr</span>
                      </p>
                      {ground.amenities && (
                        <div className="flex gap-1">
                          {Object.entries(ground.amenities).slice(0, 3).map(([key, val]) =>
                            val ? (
                              <span key={key} className="text-xs bg-gray-100 text-gray-600 px-1.5 py-0.5 rounded capitalize">
                                {key.replace(/_/g, ' ')}
                              </span>
                            ) : null
                          )}
                        </div>
                      )}
                    </div>
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>

          {/* Load more */}
          {hasMore && (
            <div className="flex justify-center mt-10">
              <Button
                variant="outline"
                onClick={loadMore}
                disabled={isFetching}
                className="px-8"
              >
                {isFetching ? 'Loading...' : 'Load More'}
              </Button>
            </div>
          )}
        </>
      )}
    </div>
  );
}
