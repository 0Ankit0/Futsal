'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { Heart, MapPin, Star } from 'lucide-react';
import Link from 'next/link';

// ── Types ─────────────────────────────────────────────────────────────────────

interface FavouriteGround {
  id: number;
  name: string;
  slug: string;
  location: string;
  ground_type: 'indoor' | 'outdoor' | 'hybrid';
  price_per_hour: number;
  average_rating: number;
  rating_count: number;
  is_verified: boolean;
  image_url?: string;
}

// ── Ground Card ───────────────────────────────────────────────────────────────

function GroundCard({
  ground,
  onUnfavourite,
  isRemoving,
}: {
  ground: FavouriteGround;
  onUnfavourite: (id: number) => void;
  isRemoving: boolean;
}) {
  return (
    <Card className="overflow-hidden hover:shadow-md transition-shadow group">
      {/* Image / placeholder */}
      <Link href={`/grounds/${ground.slug}`} className="block">
        <div className="relative h-40 bg-gradient-to-br from-green-100 to-emerald-200 flex items-center justify-center">
          {ground.image_url ? (
            <img
              src={ground.image_url}
              alt={ground.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <span className="text-4xl">⚽</span>
          )}
          <span className="absolute top-2 left-2 rounded-full bg-white/90 px-2 py-0.5 text-xs font-medium text-gray-700 capitalize">
            {ground.ground_type}
          </span>
        </div>
      </Link>

      <CardContent className="p-4">
        <div className="flex items-start justify-between gap-2">
          <Link href={`/grounds/${ground.slug}`} className="flex-1 min-w-0">
            <h3 className="font-semibold text-gray-900 truncate group-hover:text-blue-600 transition-colors">
              {ground.name}
            </h3>
          </Link>

          <button
            onClick={() => onUnfavourite(ground.id)}
            disabled={isRemoving}
            className="flex-shrink-0 p-1.5 rounded-full hover:bg-red-50 transition-colors disabled:opacity-50"
            title="Remove from favourites"
          >
            <Heart className="h-5 w-5 fill-red-500 text-red-500" />
          </button>
        </div>

        <div className="mt-1 flex items-center gap-1 text-sm text-gray-500">
          <MapPin className="h-3.5 w-3.5 flex-shrink-0" />
          <span className="truncate">{ground.location}</span>
        </div>

        <div className="mt-2 flex items-center justify-between">
          <div className="flex items-center gap-1 text-sm">
            <Star className="h-3.5 w-3.5 fill-yellow-400 text-yellow-400" />
            <span className="font-medium">{ground.average_rating.toFixed(1)}</span>
            <span className="text-gray-400">({ground.rating_count})</span>
          </div>
          <span className="text-sm font-semibold text-green-700">
            NPR {ground.price_per_hour.toLocaleString()}/hr
          </span>
        </div>

        {ground.is_verified && (
          <span className="mt-2 inline-flex items-center gap-1 rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-600">
            ✓ Verified
          </span>
        )}
      </CardContent>
    </Card>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function FavouritesPage() {
  const qc = useQueryClient();

  const { data: favourites = [], isLoading, isError } = useQuery({
    queryKey: ['favourites'],
    queryFn: async () => {
      const { data } = await apiClient.get<FavouriteGround[]>('/futsal/favourites');
      return data;
    },
  });

  const unfavourite = useMutation({
    mutationFn: async (groundId: number) => {
      await apiClient.delete(`/futsal/favourites/${groundId}`);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['favourites'] }),
  });

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Favourites</h1>
        <p className="text-gray-500 text-sm">Your saved futsal grounds</p>
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <Card key={i}>
              <CardContent className="p-0">
                <Skeleton className="h-40 w-full rounded-none" />
                <div className="p-4 space-y-2">
                  <Skeleton className="h-4 w-3/4" />
                  <Skeleton className="h-3 w-1/2" />
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      ) : isError ? (
        <Card>
          <CardContent className="p-8 text-center text-red-500">
            Failed to load favourites. Please try again.
          </CardContent>
        </Card>
      ) : favourites.length === 0 ? (
        <Card>
          <CardContent className="p-12 text-center">
            <Heart className="mx-auto h-12 w-12 text-gray-300 mb-4" />
            <p className="text-gray-500 font-medium">No favourites yet</p>
            <p className="text-sm text-gray-400 mb-6">
              Save grounds you love by tapping the heart icon
            </p>
            <Link href="/grounds">
              <Button>Browse Grounds</Button>
            </Link>
          </CardContent>
        </Card>
      ) : (
        <>
          <p className="text-sm text-gray-400">{favourites.length} saved ground{favourites.length !== 1 ? 's' : ''}</p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {favourites.map((ground) => (
              <GroundCard
                key={ground.id}
                ground={ground}
                onUnfavourite={(id) => unfavourite.mutate(id)}
                isRemoving={unfavourite.isPending && unfavourite.variables === ground.id}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
}
