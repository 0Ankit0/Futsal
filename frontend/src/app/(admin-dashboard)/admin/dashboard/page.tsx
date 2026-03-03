'use client';

import { useListUsers } from '@/hooks/use-users';
import { useTokens } from '@/hooks/use-tokens';
import { useRoles } from '@/hooks/use-rbac';
import { useAdminAnalyticsSummary, useAdminDailyTrend } from '@/hooks/use-admin-analytics';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  Users, Key, Shield, Activity, UserCheck, UserX,
  TrendingUp, MapPin, Wallet, BarChart2, AlertTriangle, CheckCircle,
} from 'lucide-react';
import Link from 'next/link';
import {
  ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip, CartesianGrid,
} from 'recharts';

// ── Mini bar chart for 7-day booking trend ────────────────────────────────────

function MiniTrendChart() {
  const { data, isLoading } = useAdminDailyTrend(7);
  if (isLoading) return <Skeleton className="h-24 w-full" />;
  if (!data) return null;

  return (
    <ResponsiveContainer width="100%" height={90}>
      <BarChart data={data.trend} margin={{ top: 4, right: 4, bottom: 0, left: -20 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
        <XAxis
          dataKey="date"
          tickFormatter={(d: string) => d.slice(5)}
          tick={{ fontSize: 10, fill: '#64748b' }}
        />
        <YAxis tick={{ fontSize: 10, fill: '#64748b' }} />
        <Tooltip
          contentStyle={{ background: '#0f172a', border: '1px solid #334155', borderRadius: 6, fontSize: 12 }}
          labelStyle={{ color: '#94a3b8' }}
          formatter={(v: number) => [v, 'Bookings']}
        />
        <Bar dataKey="bookings" fill="#6366f1" radius={[3, 3, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function AdminDashboardPage() {
  const { data: usersData } = useListUsers({ limit: 1 });
  const { data: tokenData } = useTokens({ limit: 1 });
  const { data: rolesData } = useRoles();
  const { data: summary, isLoading } = useAdminAnalyticsSummary();

  const totalUsers = usersData?.total ?? summary?.users.total ?? 0;
  const activeSessions = tokenData?.total ?? 0;
  const totalRoles = rolesData?.length ?? 0;

  const kpis = [
    {
      name: 'Total Users',
      value: String(totalUsers),
      sub: `+${summary?.users.new_last_7d ?? 0} this week`,
      icon: Users,
      href: '/admin/users',
      color: 'text-indigo-400 bg-indigo-900',
    },
    {
      name: 'Active Subscriptions',
      value: String(summary?.subscriptions.active ?? '—'),
      sub: `NPR ${(summary?.revenue.subscription_monthly ?? 0).toLocaleString()}/mo`,
      icon: CheckCircle,
      href: '/admin/subscriptions',
      color: 'text-emerald-400 bg-emerald-900',
    },
    {
      name: 'Platform Revenue (30d)',
      value: `NPR ${(summary?.revenue.platform_fee_30d ?? 0).toLocaleString()}`,
      sub: `Gross NPR ${(summary?.revenue.gross_30d ?? 0).toLocaleString()}`,
      icon: TrendingUp,
      href: '/admin/analytics',
      color: 'text-violet-400 bg-violet-900',
    },
    {
      name: 'Bookings Today',
      value: String(summary?.bookings.today ?? '—'),
      sub: `${summary?.bookings.last_7d ?? 0} this week`,
      icon: BarChart2,
      href: '/admin/analytics',
      color: 'text-blue-400 bg-blue-900',
    },
    {
      name: 'Grounds',
      value: String(summary?.grounds.total ?? '—'),
      sub: `${summary?.grounds.verified ?? 0} verified`,
      icon: MapPin,
      href: '/admin/grounds',
      color: 'text-orange-400 bg-orange-900',
    },
    {
      name: 'Payouts On Hold',
      value: String(summary?.payouts.on_hold ?? '—'),
      sub: `${summary?.payouts.failed ?? 0} failed`,
      icon: summary?.payouts.on_hold ? AlertTriangle : Wallet,
      href: '/admin/payouts',
      color: summary?.payouts.on_hold ? 'text-red-400 bg-red-900' : 'text-green-400 bg-green-900',
    },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Admin Dashboard</h1>
          <p className="text-indigo-300 mt-1">Platform overview &amp; management</p>
        </div>
        <Link href="/admin/analytics" className="text-sm text-indigo-400 hover:text-indigo-300 flex items-center gap-1">
          <BarChart2 className="h-4 w-4" /> Full Analytics →
        </Link>
      </div>

      {/* Business KPI cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {kpis.map((kpi) => (
          <Link key={kpi.name} href={kpi.href}>
            <Card className="bg-slate-900 border-slate-700 hover:border-indigo-600 transition-colors cursor-pointer">
              <CardContent className="pt-5 pb-4">
                {isLoading && kpi.value === '—' ? (
                  <Skeleton className="h-12 w-full" />
                ) : (
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-xs text-slate-400 uppercase tracking-wide">{kpi.name}</p>
                      <p className="text-2xl font-bold text-white mt-1 truncate">{kpi.value}</p>
                      <p className="text-xs text-slate-500 mt-0.5">{kpi.sub}</p>
                    </div>
                    <div className={`h-10 w-10 shrink-0 rounded-lg flex items-center justify-center ${kpi.color}`}>
                      <kpi.icon className="h-5 w-5" />
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 7-day booking mini trend */}
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm flex items-center gap-2">
              <BarChart2 className="h-4 w-4 text-indigo-400" /> Bookings — Last 7 Days
            </CardTitle>
          </CardHeader>
          <CardContent className="pt-0">
            <MiniTrendChart />
          </CardContent>
        </Card>

        {/* Quick Actions */}
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm flex items-center gap-2">
              <Activity className="h-4 w-4 text-indigo-400" /> Quick Actions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              {[
                { href: '/admin/users',         icon: Users,     label: 'Manage Users',        desc: `${totalUsers} total`,      color: 'text-indigo-400' },
                { href: '/admin/subscriptions', icon: CheckCircle, label: 'Subscriptions',     desc: `${summary?.subscriptions.active ?? 0} active`, color: 'text-emerald-400' },
                { href: '/admin/payouts',        icon: Wallet,    label: 'Payouts',             desc: `${summary?.payouts.on_hold ?? 0} on hold`,  color: 'text-amber-400' },
                { href: '/admin/analytics',      icon: BarChart2, label: 'Full Analytics',      desc: 'Charts & trends',          color: 'text-violet-400' },
                { href: '/rbac',                 icon: Shield,    label: 'Roles & Permissions', desc: `${totalRoles} roles`,       color: 'text-blue-400' },
                { href: '/tokens',               icon: Key,       label: 'Sessions',            desc: `${activeSessions} active`, color: 'text-purple-400' },
              ].map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex flex-col gap-1.5 p-3 rounded-lg border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 transition-colors"
                >
                  <item.icon className={`h-4 w-4 ${item.color}`} />
                  <div>
                    <p className="text-xs font-medium text-white">{item.label}</p>
                    <p className="text-xs text-slate-500">{item.desc}</p>
                  </div>
                </Link>
              ))}
            </div>
          </CardContent>
        </Card>
      </div>

      {/* IAM strip */}
      <Card className="bg-slate-900 border-slate-700">
        <CardHeader>
          <CardTitle className="text-white text-sm flex items-center gap-2">
            <UserCheck className="h-4 w-4 text-indigo-400" /> IAM Overview
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-4">
            {[
              { label: 'Total Users',     value: totalUsers,      href: '/admin/users', icon: Users     },
              { label: 'Active Sessions', value: activeSessions,  href: '/tokens',      icon: Key       },
              { label: 'Roles',           value: totalRoles,      href: '/rbac',        icon: Shield    },
              { label: 'Ground Owners',   value: summary?.grounds.total_owners ?? '—', href: '/admin/users', icon: UserX },
            ].map((item) => (
              <Link
                key={item.label}
                href={item.href}
                className="flex items-center gap-3 p-3 rounded-lg border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 transition-colors min-w-[140px]"
              >
                <item.icon className="h-4 w-4 text-indigo-400" />
                <div>
                  <p className="text-xs text-slate-400">{item.label}</p>
                  <p className="text-sm font-bold text-white">{item.value}</p>
                </div>
              </Link>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
