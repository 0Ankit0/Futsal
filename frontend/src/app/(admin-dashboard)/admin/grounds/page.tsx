'use client';

import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import {
  MapPin, Search, CheckCircle, XCircle, ToggleLeft, ToggleRight,
  Star, Shield, AlertCircle,
} from 'lucide-react';

// ── Types ─────────────────────────────────────────────────────────────────────

interface AdminGround {
  id: number;
  name: string;
  slug: string;
  owner_id: number;
  location: string;
  ground_type: 'indoor' | 'outdoor' | 'hybrid';
  price_per_hour: number;
  is_verified: boolean;
  is_active: boolean;
  average_rating: number;
  rating_count: number;
}

type VerifiedFilter = 'all' | 'verified' | 'unverified';

// ── Page ──────────────────────────────────────────────────────────────────────

export default function AdminGroundsPage() {
  const qc = useQueryClient();

  const [search, setSearch]               = useState('');
  const [verifiedFilter, setVerifiedFilter] = useState<VerifiedFilter>('all');
  const [typeFilter, setTypeFilter]       = useState<string>('all');

  const { data: grounds = [], isLoading, isError } = useQuery({
    queryKey: ['admin-grounds'],
    queryFn: async () => {
      const { data } = await apiClient.get<AdminGround[]>('/futsal/grounds', {
        params: { limit: 100 },
      });
      return data;
    },
  });

  const verifyGround = useMutation({
    mutationFn: async (id: number) => {
      const { data } = await apiClient.patch(`/futsal/grounds/${id}/verify`);
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-grounds'] }),
  });

  const toggleActive = useMutation({
    mutationFn: async ({ id, is_active }: { id: number; is_active: boolean }) => {
      const { data } = await apiClient.patch(`/futsal/grounds/${id}`, { is_active });
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-grounds'] }),
  });

  // Stats
  const stats = useMemo(() => ({
    total:    grounds.length,
    verified: grounds.filter((g) => g.is_verified).length,
    pending:  grounds.filter((g) => !g.is_verified).length,
    suspended: grounds.filter((g) => !g.is_active).length,
  }), [grounds]);

  // Filtered grounds
  const filtered = useMemo(() => {
    return grounds.filter((g) => {
      const matchSearch = !search ||
        g.name.toLowerCase().includes(search.toLowerCase()) ||
        g.location.toLowerCase().includes(search.toLowerCase());
      const matchVerified =
        verifiedFilter === 'all' ? true :
        verifiedFilter === 'verified' ? g.is_verified :
        !g.is_verified;
      const matchType = typeFilter === 'all' || g.ground_type === typeFilter;
      return matchSearch && matchVerified && matchType;
    });
  }, [grounds, search, verifiedFilter, typeFilter]);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Grounds Management</h1>
        <p className="text-gray-500 text-sm">Review, verify, and manage all registered futsal grounds</p>
      </div>

      {/* Stats row */}
      {isLoading ? (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          {[1, 2, 3, 4].map((i) => (
            <Card key={i}><CardContent className="p-4"><Skeleton className="h-12 w-full" /></CardContent></Card>
          ))}
        </div>
      ) : (
        <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
          {[
            { label: 'Total Grounds',       value: stats.total,     icon: MapPin,       color: 'text-blue-600 bg-blue-50' },
            { label: 'Verified',            value: stats.verified,  icon: CheckCircle,  color: 'text-green-600 bg-green-50' },
            { label: 'Pending Verification',value: stats.pending,   icon: AlertCircle,  color: 'text-yellow-600 bg-yellow-50' },
            { label: 'Suspended',           value: stats.suspended, icon: XCircle,      color: 'text-red-600 bg-red-50' },
          ].map((s) => (
            <Card key={s.label}>
              <CardContent className="p-4 flex items-center gap-3">
                <div className={`rounded-full p-2.5 ${s.color}`}>
                  <s.icon className="h-5 w-5" />
                </div>
                <div>
                  <p className="text-xl font-bold text-gray-900">{s.value}</p>
                  <p className="text-xs text-gray-500">{s.label}</p>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <div className="relative flex-1 min-w-48">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
          <Input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name or location…"
            className="pl-9"
          />
        </div>

        <select
          value={verifiedFilter}
          onChange={(e) => setVerifiedFilter(e.target.value as VerifiedFilter)}
          className="border rounded-lg px-3 py-2 text-sm bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="all">All Status</option>
          <option value="verified">Verified</option>
          <option value="unverified">Unverified</option>
        </select>

        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="border rounded-lg px-3 py-2 text-sm bg-white text-gray-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
        >
          <option value="all">All Types</option>
          <option value="indoor">Indoor</option>
          <option value="outdoor">Outdoor</option>
          <option value="hybrid">Hybrid</option>
        </select>
      </div>

      {/* Table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">
            {filtered.length} ground{filtered.length !== 1 ? 's' : ''}
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          {isLoading ? (
            <div className="p-6 space-y-3">
              {[1, 2, 3, 4, 5].map((i) => <Skeleton key={i} className="h-10 w-full" />)}
            </div>
          ) : isError ? (
            <p className="p-6 text-center text-red-500 text-sm">Failed to load grounds. Please try again.</p>
          ) : filtered.length === 0 ? (
            <p className="p-8 text-center text-gray-400 text-sm">No grounds match your filters.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-gray-100 text-xs text-gray-400 uppercase tracking-wide">
                    <th className="px-4 py-3 text-left font-medium">Ground</th>
                    <th className="px-4 py-3 text-left font-medium">Owner ID</th>
                    <th className="px-4 py-3 text-left font-medium">Type</th>
                    <th className="px-4 py-3 text-left font-medium">Rating</th>
                    <th className="px-4 py-3 text-left font-medium">Verified</th>
                    <th className="px-4 py-3 text-left font-medium">Active</th>
                    <th className="px-4 py-3 text-left font-medium">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((ground) => (
                    <tr key={ground.id} className="border-b border-gray-50 hover:bg-gray-50 transition-colors">
                      {/* Ground info */}
                      <td className="px-4 py-3">
                        <p className="font-medium text-gray-900">{ground.name}</p>
                        <p className="text-xs text-gray-400 flex items-center gap-1 mt-0.5">
                          <MapPin className="h-3 w-3" />{ground.location}
                        </p>
                      </td>

                      {/* Owner */}
                      <td className="px-4 py-3 text-gray-500">#{ground.owner_id}</td>

                      {/* Type */}
                      <td className="px-4 py-3">
                        <span className="capitalize rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-600">
                          {ground.ground_type}
                        </span>
                      </td>

                      {/* Rating */}
                      <td className="px-4 py-3">
                        <span className="flex items-center gap-1 text-sm">
                          <Star className="h-3.5 w-3.5 fill-yellow-400 text-yellow-400" />
                          {ground.average_rating.toFixed(1)}
                          <span className="text-gray-400 text-xs">({ground.rating_count})</span>
                        </span>
                      </td>

                      {/* Verified badge */}
                      <td className="px-4 py-3">
                        {ground.is_verified ? (
                          <span className="inline-flex items-center gap-1 rounded-full bg-green-50 px-2 py-0.5 text-xs font-medium text-green-700">
                            <CheckCircle className="h-3 w-3" /> Verified
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 rounded-full bg-yellow-50 px-2 py-0.5 text-xs font-medium text-yellow-700">
                            <AlertCircle className="h-3 w-3" /> Pending
                          </span>
                        )}
                      </td>

                      {/* Active toggle */}
                      <td className="px-4 py-3">
                        <button
                          onClick={() => toggleActive.mutate({ id: ground.id, is_active: !ground.is_active })}
                          disabled={toggleActive.isPending}
                          className="flex items-center gap-1 text-xs font-medium"
                          title={ground.is_active ? 'Suspend' : 'Activate'}
                        >
                          {ground.is_active ? (
                            <>
                              <ToggleRight className="h-5 w-5 text-green-500" />
                              <span className="text-green-600">Active</span>
                            </>
                          ) : (
                            <>
                              <ToggleLeft className="h-5 w-5 text-gray-400" />
                              <span className="text-gray-400">Suspended</span>
                            </>
                          )}
                        </button>
                      </td>

                      {/* Actions */}
                      <td className="px-4 py-3">
                        <div className="flex items-center gap-2">
                          {!ground.is_verified && (
                            <button
                              onClick={() => verifyGround.mutate(ground.id)}
                              disabled={verifyGround.isPending && verifyGround.variables === ground.id}
                              className="inline-flex items-center gap-1 rounded-lg border border-green-200 bg-green-50 px-2.5 py-1 text-xs font-medium text-green-700 hover:bg-green-100 transition-colors disabled:opacity-50"
                            >
                              <Shield className="h-3.5 w-3.5" />
                              Verify
                            </button>
                          )}
                          {ground.is_active && (
                            <button
                              onClick={() => toggleActive.mutate({ id: ground.id, is_active: false })}
                              disabled={toggleActive.isPending}
                              className="inline-flex items-center gap-1 rounded-lg border border-red-200 bg-red-50 px-2.5 py-1 text-xs font-medium text-red-600 hover:bg-red-100 transition-colors disabled:opacity-50"
                            >
                              <XCircle className="h-3.5 w-3.5" />
                              Suspend
                            </button>
                          )}
                          {!ground.is_active && (
                            <button
                              onClick={() => toggleActive.mutate({ id: ground.id, is_active: true })}
                              disabled={toggleActive.isPending}
                              className="inline-flex items-center gap-1 rounded-lg border border-blue-200 bg-blue-50 px-2.5 py-1 text-xs font-medium text-blue-600 hover:bg-blue-100 transition-colors disabled:opacity-50"
                            >
                              <CheckCircle className="h-3.5 w-3.5" />
                              Activate
                            </button>
                          )}
                        </div>
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
