'use client';

import { useState } from 'react';
import { useAdminAnalyticsSummary, useAdminDailyTrend } from '@/hooks/use-admin-analytics';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';
import {
  TrendingUp, Users, MapPin, Wallet, BarChart2, AlertTriangle,
  CheckCircle, DollarSign, Calendar, Activity,
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart, Bar,
  LineChart, Line,
  AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend,
  PieChart, Pie, Cell,
} from 'recharts';

// ── Palette ───────────────────────────────────────────────────────────────────

const COLORS = ['#6366f1', '#10b981', '#f59e0b', '#ef4444', '#8b5cf6', '#06b6d4'];

// ── Helpers ───────────────────────────────────────────────────────────────────

function fmtDate(iso: string): string {
  return iso.slice(5); // MM-DD
}

function fmtNPR(v: number): string {
  if (v >= 1_000_000) return `${(v / 1_000_000).toFixed(1)}M`;
  if (v >= 1_000) return `${(v / 1_000).toFixed(0)}K`;
  return String(v);
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

function KpiCard({
  label, value, sub, icon: Icon, color, loading,
}: {
  label: string; value: string; sub?: string;
  icon: React.ElementType; color: string; loading?: boolean;
}) {
  return (
    <Card className="bg-slate-900 border-slate-700">
      <CardContent className="pt-5 pb-4">
        {loading ? (
          <Skeleton className="h-14 w-full bg-slate-700" />
        ) : (
          <div className="flex items-start justify-between gap-2">
            <div className="min-w-0">
              <p className="text-xs text-slate-400 uppercase tracking-wide">{label}</p>
              <p className="text-2xl font-bold text-white mt-1 truncate">{value}</p>
              {sub && <p className="text-xs text-slate-500 mt-0.5">{sub}</p>}
            </div>
            <div className={`h-10 w-10 shrink-0 rounded-lg flex items-center justify-center ${color}`}>
              <Icon className="h-5 w-5" />
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

// ── Custom tooltip ────────────────────────────────────────────────────────────

function DarkTooltip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div className="bg-slate-800 border border-slate-600 rounded-lg p-3 text-xs shadow-xl">
      <p className="text-slate-300 font-medium mb-1">{label}</p>
      {payload.map((p: any, i: number) => (
        <p key={i} style={{ color: p.color }}>
          {p.name}: {p.name === 'revenue' ? `NPR ${p.value.toLocaleString()}` : p.value}
        </p>
      ))}
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function AdminAnalyticsPage() {
  const [trendDays, setTrendDays] = useState<7 | 14 | 30>(30);
  const { data: summary, isLoading: sumLoading } = useAdminAnalyticsSummary();
  const { data: trendData, isLoading: trendLoading } = useAdminDailyTrend(trendDays);

  // Booking status pie data
  const bookingPie = summary
    ? [
        { name: 'Today',  value: summary.bookings.today },
        { name: 'Week',   value: Math.max(0, summary.bookings.last_7d - summary.bookings.today) },
        { name: 'Older',  value: Math.max(0, summary.bookings.last_30d - summary.bookings.last_7d) },
      ].filter((d) => d.value > 0)
    : [];

  // Payout status pie data
  const payoutPie = summary
    ? [
        { name: 'Completed', value: summary.payouts.completed_30d },
        { name: 'On Hold',   value: summary.payouts.on_hold },
        { name: 'Failed',    value: summary.payouts.failed },
      ].filter((d) => d.value > 0)
    : [];

  // Revenue breakdown pie
  const revPie = summary
    ? [
        { name: 'Platform Fees', value: summary.revenue.platform_fee_30d },
        { name: 'Subscription',  value: summary.revenue.subscription_monthly },
      ].filter((d) => d.value > 0)
    : [];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white">Platform Analytics</h1>
          <p className="text-slate-400 text-sm mt-0.5">Superuser — full platform metrics</p>
        </div>
        <div className="flex gap-2">
          {([7, 14, 30] as const).map((d) => (
            <button
              key={d}
              onClick={() => setTrendDays(d)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-colors ${
                trendDays === d
                  ? 'bg-indigo-600 text-white'
                  : 'bg-slate-800 text-slate-400 hover:bg-slate-700'
              }`}
            >
              {d}d
            </button>
          ))}
        </div>
      </div>

      {/* KPI row 1 — Users & Grounds */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
        <KpiCard label="Total Users"    value={String(summary?.users.total ?? '—')}    sub={`+${summary?.users.new_last_7d ?? 0} this week`}    icon={Users}        color="text-indigo-400 bg-indigo-900" loading={sumLoading} />
        <KpiCard label="New Users (30d)" value={String(summary?.users.new_last_30d ?? '—')} sub={`+${summary?.users.new_last_7d ?? 0} last 7d`}  icon={Activity}     color="text-blue-400 bg-blue-900"    loading={sumLoading} />
        <KpiCard label="Total Grounds"  value={String(summary?.grounds.total ?? '—')}  sub={`${summary?.grounds.verified ?? 0} verified`}       icon={MapPin}       color="text-orange-400 bg-orange-900" loading={sumLoading} />
        <KpiCard label="Ground Owners"  value={String(summary?.grounds.total_owners ?? '—')} sub="unique owners"                                 icon={Users}        color="text-amber-400 bg-amber-900"  loading={sumLoading} />
        <KpiCard label="Active Subs"    value={String(summary?.subscriptions.active ?? '—')} sub={`NPR ${(summary?.revenue.subscription_monthly ?? 0).toLocaleString()}/mo`} icon={CheckCircle} color="text-emerald-400 bg-emerald-900" loading={sumLoading} />
        <KpiCard label="Payouts On Hold" value={String(summary?.payouts.on_hold ?? '—')} sub={`${summary?.payouts.failed ?? 0} failed`}          icon={AlertTriangle} color={summary?.payouts.on_hold ? 'text-red-400 bg-red-900' : 'text-green-400 bg-green-900'} loading={sumLoading} />
      </div>

      {/* KPI row 2 — Revenue & Bookings */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <KpiCard label="Platform Fees (30d)"  value={`NPR ${(summary?.revenue.platform_fee_30d ?? 0).toLocaleString()}`}  sub={`Gross NPR ${(summary?.revenue.gross_30d ?? 0).toLocaleString()}`} icon={DollarSign}  color="text-violet-400 bg-violet-900" loading={sumLoading} />
        <KpiCard label="Sub Revenue / Month"  value={`NPR ${(summary?.revenue.subscription_monthly ?? 0).toLocaleString()}`} sub="recurring"                                                      icon={TrendingUp}  color="text-emerald-400 bg-emerald-900" loading={sumLoading} />
        <KpiCard label="Bookings (30d)"       value={String(summary?.bookings.last_30d ?? '—')}   sub={`${summary?.bookings.last_7d ?? 0} last 7d`}                                               icon={Calendar}    color="text-blue-400 bg-blue-900"    loading={sumLoading} />
        <KpiCard label="Completed Payouts"    value={String(summary?.payouts.completed_30d ?? '—')} sub="last 30 days"                                                                             icon={Wallet}      color="text-green-400 bg-green-900"  loading={sumLoading} />
      </div>

      {/* Booking + Revenue trend chart */}
      <Card className="bg-slate-900 border-slate-700">
        <CardHeader>
          <CardTitle className="text-white text-sm flex items-center gap-2">
            <BarChart2 className="h-4 w-4 text-indigo-400" />
            Booking Volume &amp; Revenue — Last {trendDays} Days
          </CardTitle>
        </CardHeader>
        <CardContent>
          {trendLoading ? (
            <Skeleton className="h-64 w-full bg-slate-700" />
          ) : !trendData ? (
            <p className="text-slate-400 text-sm text-center py-12">No data available.</p>
          ) : (
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={trendData.trend} margin={{ top: 8, right: 8, bottom: 0, left: 0 }}>
                <defs>
                  <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#6366f1" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#6366f1" stopOpacity={0} />
                  </linearGradient>
                  <linearGradient id="bkGrad" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="5%"  stopColor="#10b981" stopOpacity={0.3} />
                    <stop offset="95%" stopColor="#10b981" stopOpacity={0} />
                  </linearGradient>
                </defs>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
                <XAxis
                  dataKey="date"
                  tickFormatter={fmtDate}
                  tick={{ fontSize: 11, fill: '#64748b' }}
                  interval={trendDays <= 7 ? 0 : trendDays <= 14 ? 1 : 4}
                />
                <YAxis yAxisId="rev" orientation="right" tick={{ fontSize: 11, fill: '#64748b' }} tickFormatter={fmtNPR} />
                <YAxis yAxisId="bk"  orientation="left"  tick={{ fontSize: 11, fill: '#64748b' }} />
                <Tooltip content={<DarkTooltip />} />
                <Legend wrapperStyle={{ fontSize: 12, color: '#94a3b8' }} />
                <Area yAxisId="rev" type="monotone" dataKey="revenue"  name="revenue"  stroke="#6366f1" fill="url(#revGrad)" strokeWidth={2} dot={false} />
                <Area yAxisId="bk"  type="monotone" dataKey="bookings" name="bookings" stroke="#10b981" fill="url(#bkGrad)"  strokeWidth={2} dot={false} />
              </AreaChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>

      {/* Pie charts row */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Booking distribution */}
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm">Booking Distribution</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center">
            {sumLoading ? (
              <Skeleton className="h-40 w-40 rounded-full bg-slate-700" />
            ) : bookingPie.length === 0 ? (
              <p className="text-slate-400 text-sm py-10">No bookings yet.</p>
            ) : (
              <>
                <ResponsiveContainer width="100%" height={180}>
                  <PieChart>
                    <Pie data={bookingPie} dataKey="value" cx="50%" cy="50%" outerRadius={70} label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`} labelLine={false} fontSize={10}>
                      {bookingPie.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip contentStyle={{ background: '#0f172a', border: '1px solid #334155', fontSize: 12 }} />
                  </PieChart>
                </ResponsiveContainer>
                <div className="flex flex-wrap gap-3 justify-center mt-2">
                  {bookingPie.map((d, i) => (
                    <span key={d.name} className="flex items-center gap-1 text-xs text-slate-400">
                      <span className="h-2 w-2 rounded-full inline-block" style={{ background: COLORS[i % COLORS.length] }} />
                      {d.name}: {d.value}
                    </span>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Payout status */}
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm">Payout Status (30d)</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center">
            {sumLoading ? (
              <Skeleton className="h-40 w-40 rounded-full bg-slate-700" />
            ) : payoutPie.length === 0 ? (
              <p className="text-slate-400 text-sm py-10">No payout data.</p>
            ) : (
              <>
                <ResponsiveContainer width="100%" height={180}>
                  <PieChart>
                    <Pie data={payoutPie} dataKey="value" cx="50%" cy="50%" outerRadius={70} label={({ name, percent }) => `${(percent * 100).toFixed(0)}%`} labelLine={false} fontSize={10}>
                      {payoutPie.map((entry, i) => (
                        <Cell key={i} fill={
                          entry.name === 'Completed' ? '#10b981' :
                          entry.name === 'On Hold'   ? '#f59e0b' : '#ef4444'
                        } />
                      ))}
                    </Pie>
                    <Tooltip contentStyle={{ background: '#0f172a', border: '1px solid #334155', fontSize: 12 }} />
                  </PieChart>
                </ResponsiveContainer>
                <div className="flex flex-wrap gap-3 justify-center mt-2">
                  {payoutPie.map((d) => (
                    <span key={d.name} className="flex items-center gap-1 text-xs text-slate-400">
                      <span className="h-2 w-2 rounded-full inline-block" style={{
                        background: d.name === 'Completed' ? '#10b981' : d.name === 'On Hold' ? '#f59e0b' : '#ef4444'
                      }} />
                      {d.name}: {d.value}
                    </span>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>

        {/* Revenue breakdown */}
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm">Revenue Sources</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col items-center">
            {sumLoading ? (
              <Skeleton className="h-40 w-40 rounded-full bg-slate-700" />
            ) : revPie.length === 0 ? (
              <p className="text-slate-400 text-sm py-10">No revenue yet.</p>
            ) : (
              <>
                <ResponsiveContainer width="100%" height={180}>
                  <PieChart>
                    <Pie data={revPie} dataKey="value" cx="50%" cy="50%" innerRadius={45} outerRadius={70} paddingAngle={3} label={({ percent }) => `${(percent * 100).toFixed(0)}%`} labelLine={false} fontSize={10}>
                      {revPie.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
                    </Pie>
                    <Tooltip
                      contentStyle={{ background: '#0f172a', border: '1px solid #334155', fontSize: 12 }}
                      formatter={(v: number) => [`NPR ${v.toLocaleString()}`, '']}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <div className="flex flex-wrap gap-3 justify-center mt-2">
                  {revPie.map((d, i) => (
                    <span key={d.name} className="flex items-center gap-1 text-xs text-slate-400">
                      <span className="h-2 w-2 rounded-full inline-block" style={{ background: COLORS[i % COLORS.length] }} />
                      {d.name}: NPR {d.value.toLocaleString()}
                    </span>
                  ))}
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* Daily bookings bar chart */}
      <Card className="bg-slate-900 border-slate-700">
        <CardHeader>
          <CardTitle className="text-white text-sm flex items-center gap-2">
            <Calendar className="h-4 w-4 text-indigo-400" /> Daily Booking Count — Last {trendDays} Days
          </CardTitle>
        </CardHeader>
        <CardContent>
          {trendLoading ? (
            <Skeleton className="h-48 w-full bg-slate-700" />
          ) : !trendData ? null : (
            <ResponsiveContainer width="100%" height={220}>
              <BarChart data={trendData.trend} margin={{ top: 8, right: 8, bottom: 0, left: -10 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" />
                <XAxis
                  dataKey="date"
                  tickFormatter={fmtDate}
                  tick={{ fontSize: 11, fill: '#64748b' }}
                  interval={trendDays <= 7 ? 0 : trendDays <= 14 ? 1 : 4}
                />
                <YAxis tick={{ fontSize: 11, fill: '#64748b' }} allowDecimals={false} />
                <Tooltip content={<DarkTooltip />} />
                <Bar dataKey="bookings" name="bookings" fill="#6366f1" radius={[3, 3, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          )}
        </CardContent>
      </Card>

      {/* User growth vs ground growth side by side */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm flex items-center gap-2">
              <Users className="h-4 w-4 text-indigo-400" /> User Growth Summary
            </CardTitle>
          </CardHeader>
          <CardContent>
            {sumLoading ? <Skeleton className="h-24 w-full bg-slate-700" /> : (
              <div className="space-y-4">
                {[
                  { label: 'Total Registered', value: summary?.users.total ?? 0, max: summary?.users.total ?? 1, color: 'bg-indigo-500' },
                  { label: 'New Last 30 Days', value: summary?.users.new_last_30d ?? 0, max: summary?.users.total ?? 1, color: 'bg-blue-500' },
                  { label: 'New Last 7 Days',  value: summary?.users.new_last_7d ?? 0,  max: summary?.users.total ?? 1, color: 'bg-violet-500' },
                ].map((row) => (
                  <div key={row.label}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-slate-400">{row.label}</span>
                      <span className="text-white font-medium">{row.value.toLocaleString()}</span>
                    </div>
                    <div className="h-2 rounded-full bg-slate-700">
                      <div
                        className={`h-2 rounded-full transition-all ${row.color}`}
                        style={{ width: `${Math.min(100, row.max > 0 ? (row.value / row.max) * 100 : 0)}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white text-sm flex items-center gap-2">
              <MapPin className="h-4 w-4 text-orange-400" /> Ground &amp; Owner Summary
            </CardTitle>
          </CardHeader>
          <CardContent>
            {sumLoading ? <Skeleton className="h-24 w-full bg-slate-700" /> : (
              <div className="space-y-4">
                {[
                  { label: 'Total Grounds',    value: summary?.grounds.total ?? 0,        max: summary?.grounds.total ?? 1,        color: 'bg-orange-500' },
                  { label: 'Verified Grounds', value: summary?.grounds.verified ?? 0,     max: summary?.grounds.total ?? 1,        color: 'bg-green-500' },
                  { label: 'Unique Owners',    value: summary?.grounds.total_owners ?? 0, max: summary?.grounds.total_owners ?? 1, color: 'bg-amber-500' },
                ].map((row) => (
                  <div key={row.label}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-slate-400">{row.label}</span>
                      <span className="text-white font-medium">{row.value.toLocaleString()}</span>
                    </div>
                    <div className="h-2 rounded-full bg-slate-700">
                      <div
                        className={`h-2 rounded-full transition-all ${row.color}`}
                        style={{ width: `${Math.min(100, row.max > 0 ? (row.value / row.max) * 100 : 0)}%` }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
