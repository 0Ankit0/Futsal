'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { useSubscription } from '@/hooks/use-subscription';
import type { FutsalGround } from '@/hooks/use-futsal';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Skeleton } from '@/components/ui/skeleton';
import { ConfirmDialog } from '@/components/ui/confirm-dialog';
import { UserPlus, Users, Trash2, Mail } from 'lucide-react';
import { useAnalytics } from '@/hooks/use-analytics';

// ── Types ──────────────────────────────────────────────────────────────────

type StaffRole = 'MANAGER' | 'STAFF';

interface StaffMember {
  id: number;
  email: string;
  role: StaffRole;
  status: 'accepted' | 'pending';
  joined_at: string | null;
}

// ── Toast ──────────────────────────────────────────────────────────────────

function Toast({
  message,
  type,
  onClose,
}: {
  message: string;
  type: 'success' | 'error';
  onClose: () => void;
}) {
  return (
    <div
      className={`fixed top-4 right-4 z-50 flex items-center gap-3 rounded-lg px-4 py-3 shadow-lg text-sm font-medium ${
        type === 'success' ? 'bg-green-600 text-white' : 'bg-red-600 text-white'
      }`}
    >
      {message}
      <button onClick={onClose} className="ml-2 text-white/80 hover:text-white">
        ✕
      </button>
    </div>
  );
}

// ── Hooks ──────────────────────────────────────────────────────────────────

function useOwnerGrounds() {
  return useQuery({
    queryKey: ['owner-grounds'],
    queryFn: async () => {
      const { data } = await apiClient.get<FutsalGround[]>('/grounds');
      return data;
    },
  });
}

function useGroundStaff(groundId: number | null) {
  return useQuery({
    queryKey: ['ground-staff', groundId],
    queryFn: async () => {
      const { data } = await apiClient.get<StaffMember[]>(`/grounds/${groundId}/staff`);
      return data;
    },
    enabled: !!groundId,
  });
}

function useInviteStaff(groundId: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (payload: { email: string; role: StaffRole }) => {
      const { data } = await apiClient.post(`/grounds/${groundId}/staff/invite`, payload);
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['ground-staff', groundId] }),
  });
}

function useRemoveStaff(groundId: number) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (staffId: number) => {
      await apiClient.delete(`/grounds/${groundId}/staff/${staffId}`);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['ground-staff', groundId] }),
  });
}

// ── Invite dialog ──────────────────────────────────────────────────────────

function InviteDialog({
  groundId,
  onClose,
  onSuccess,
  onError,
}: {
  groundId: number;
  onClose: () => void;
  onSuccess: () => void;
  onError: (msg: string) => void;
}) {
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<StaffRole>('STAFF');
  const invite = useInviteStaff(groundId);
  const { track } = useAnalytics();

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    invite.mutate(
      { email: email.trim(), role },
      {
        onSuccess: () => {
          track('staff_invited', { ground_id: groundId, role });
          onSuccess();
          onClose();
        },
        onError: (err: unknown) => {
          const msg =
            (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail ??
            'Failed to send invitation.';
          onError(msg);
        },
      },
    );
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm">
      <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Invite Staff Member</h2>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-1">
            <label className="text-sm font-medium text-gray-700">Email</label>
            <Input
              type="email"
              placeholder="staff@example.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="space-y-1">
            <label className="text-sm font-medium text-gray-700">Role</label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as StaffRole)}
              className="w-full rounded-md border border-gray-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="STAFF">Staff</option>
              <option value="MANAGER">Manager</option>
            </select>
          </div>
          <div className="flex gap-2 pt-2">
            <Button type="submit" isLoading={invite.isPending} className="flex-1">
              <Mail className="mr-1.5 h-4 w-4" />
              Send Invite
            </Button>
            <Button type="button" variant="outline" onClick={onClose} className="flex-1">
              Cancel
            </Button>
          </div>
        </form>
      </div>
    </div>
  );
}

// ── Role badge ─────────────────────────────────────────────────────────────

function RoleBadge({ role }: { role: StaffRole }) {
  return (
    <span
      className={`rounded-full px-2 py-0.5 text-xs font-semibold ${
        role === 'MANAGER' ? 'bg-purple-100 text-purple-700' : 'bg-blue-100 text-blue-700'
      }`}
    >
      {role}
    </span>
  );
}

// ── Main page ──────────────────────────────────────────────────────────────

export default function OwnerTeamPage() {
  const { data: grounds = [], isLoading: groundsLoading } = useOwnerGrounds();
  const { data: subscription } = useSubscription();
  const [selectedGroundId, setSelectedGroundId] = useState<number | null>(null);
  const [showInvite, setShowInvite] = useState(false);
  const [removingStaffId, setRemovingStaffId] = useState<number | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const activeGroundId = selectedGroundId ?? grounds[0]?.id ?? null;
  const { data: staff = [], isLoading: staffLoading } = useGroundStaff(activeGroundId);
  const removeStaff = useRemoveStaff(activeGroundId ?? 0);

  const maxStaff = subscription?.plan?.max_staff ?? null;

  const showToast = (message: string, type: 'success' | 'error') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const handleRemove = () => {
    if (!removingStaffId || !activeGroundId) return;
    removeStaff.mutate(removingStaffId, {
      onSuccess: () => {
        setRemovingStaffId(null);
        showToast('Staff member removed.', 'success');
      },
      onError: () => {
        setRemovingStaffId(null);
        showToast('Failed to remove staff member.', 'error');
      },
    });
  };

  return (
    <div className="space-y-6">
      {toast && (
        <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} />
      )}

      <div className="flex items-start justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Team</h1>
          <p className="text-gray-500">Manage staff for your grounds</p>
        </div>
        {maxStaff !== null && (
          <span className="rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-600">
            <Users className="mr-1 inline h-4 w-4" />
            {staff.length} / {maxStaff} staff
          </span>
        )}
      </div>

      {/* Ground selector */}
      {groundsLoading ? (
        <Skeleton className="h-10 w-64" />
      ) : grounds.length === 0 ? (
        <Card>
          <CardContent className="py-10 text-center text-sm text-gray-400">
            You have no grounds. Add a ground first to manage staff.
          </CardContent>
        </Card>
      ) : (
        <div className="flex items-center gap-3">
          <label className="text-sm font-medium text-gray-700">Ground:</label>
          <select
            value={activeGroundId ?? ''}
            onChange={(e) => setSelectedGroundId(Number(e.target.value))}
            className="rounded-md border border-gray-200 bg-white px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            {grounds.map((g) => (
              <option key={g.id} value={g.id}>
                {g.name}
              </option>
            ))}
          </select>
        </div>
      )}

      {/* Staff table */}
      {activeGroundId && (
        <Card>
          <CardHeader className="flex flex-row items-center justify-between pb-2">
            <CardTitle className="text-base">Staff Members</CardTitle>
            <Button
              size="sm"
              className="bg-green-600 hover:bg-green-700"
              onClick={() => setShowInvite(true)}
              disabled={maxStaff !== null && staff.length >= maxStaff}
            >
              <UserPlus className="mr-1.5 h-4 w-4" />
              Invite Staff
            </Button>
          </CardHeader>
          <CardContent className="p-0 overflow-x-auto">
            {staffLoading ? (
              <div className="p-4 space-y-2">
                <Skeleton className="h-8 w-full" />
                <Skeleton className="h-8 w-full" />
              </div>
            ) : staff.length === 0 ? (
              <p className="px-4 py-8 text-center text-sm text-gray-400">
                No staff members yet. Invite someone to get started.
              </p>
            ) : (
              <table className="w-full">
                <thead>
                  <tr className="border-b border-gray-100 bg-gray-50 text-left">
                    <th className="px-4 py-3 text-xs font-medium uppercase tracking-wide text-gray-500">
                      Email
                    </th>
                    <th className="px-4 py-3 text-xs font-medium uppercase tracking-wide text-gray-500">
                      Role
                    </th>
                    <th className="px-4 py-3 text-xs font-medium uppercase tracking-wide text-gray-500">
                      Status
                    </th>
                    <th className="px-4 py-3 text-xs font-medium uppercase tracking-wide text-gray-500">
                      Joined
                    </th>
                    <th className="px-4 py-3 text-xs font-medium uppercase tracking-wide text-gray-500">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody>
                  {staff.map((member) => (
                    <tr
                      key={member.id}
                      className="border-b border-gray-100 hover:bg-gray-50 transition-colors"
                    >
                      <td className="px-4 py-3 text-sm text-gray-700">{member.email}</td>
                      <td className="px-4 py-3">
                        <RoleBadge role={member.role} />
                      </td>
                      <td className="px-4 py-3">
                        <span
                          className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                            member.status === 'accepted'
                              ? 'bg-green-100 text-green-700'
                              : 'bg-yellow-100 text-yellow-700'
                          }`}
                        >
                          {member.status}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-sm text-gray-400">
                        {member.joined_at
                          ? new Date(member.joined_at).toLocaleDateString()
                          : '—'}
                      </td>
                      <td className="px-4 py-3">
                        <button
                          onClick={() => setRemovingStaffId(member.id)}
                          className="rounded p-1.5 text-red-400 hover:bg-red-50 hover:text-red-600"
                          title="Remove"
                        >
                          <Trash2 className="h-4 w-4" />
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </CardContent>
        </Card>
      )}

      {/* Invite dialog */}
      {showInvite && activeGroundId && (
        <InviteDialog
          groundId={activeGroundId}
          onClose={() => setShowInvite(false)}
          onSuccess={() => showToast('Invitation sent successfully.', 'success')}
          onError={(msg) => showToast(msg, 'error')}
        />
      )}

      {/* Remove confirm */}
      <ConfirmDialog
        open={removingStaffId !== null}
        title="Remove Staff Member?"
        description="This will revoke their access to this ground."
        confirmLabel="Remove"
        cancelLabel="Keep"
        onConfirm={handleRemove}
        onCancel={() => setRemovingStaffId(null)}
        isLoading={removeStaff.isPending}
      />
    </div>
  );
}
