'use client';

import { useListUsers } from '@/hooks/use-users';
import { useTokens } from '@/hooks/use-tokens';
import { useRoles } from '@/hooks/use-rbac';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Users, Key, Shield, Activity, UserCheck, UserX } from 'lucide-react';
import Link from 'next/link';

export default function AdminDashboardPage() {
  const { data: usersData } = useListUsers({ limit: 1 });
  const { data: tokenData } = useTokens({ limit: 1 });
  const { data: rolesData } = useRoles();

  const totalUsers = usersData?.total ?? 0;
  const activeSessions = tokenData?.total ?? 0;
  const totalRoles = rolesData?.length ?? 0;

  const stats = [
    {
      name: 'Total Users',
      value: String(totalUsers),
      icon: Users,
      href: '/admin/users',
      color: 'text-indigo-400 bg-indigo-900',
    },
    {
      name: 'Active Sessions',
      value: String(activeSessions),
      href: '/tokens',
      icon: Key,
      color: 'text-purple-400 bg-purple-900',
    },
    {
      name: 'Roles',
      value: String(totalRoles),
      href: '/rbac',
      icon: Shield,
      color: 'text-emerald-400 bg-emerald-900',
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Admin Dashboard</h1>
        <p className="text-indigo-300 mt-1">Platform overview &amp; management</p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {stats.map((stat) => (
          <Link key={stat.name} href={stat.href}>
            <Card className="bg-slate-900 border-slate-700 hover:border-indigo-600 transition-colors cursor-pointer">
              <CardContent className="pt-6">
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-sm text-slate-400">{stat.name}</p>
                    <p className="text-3xl font-bold text-white mt-1">{stat.value}</p>
                  </div>
                  <div className={`h-12 w-12 rounded-lg flex items-center justify-center ${stat.color}`}>
                    <stat.icon className="h-6 w-6" />
                  </div>
                </div>
              </CardContent>
            </Card>
          </Link>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Activity className="h-5 w-5 text-indigo-400" />
              Quick Actions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 gap-3">
              {[
                { href: '/admin/users', icon: Users, label: 'Manage Users', desc: 'View, edit, delete users', color: 'text-indigo-400' },
                { href: '/rbac', icon: Shield, label: 'Roles & Permissions', desc: 'Manage access control', color: 'text-emerald-400' },
                { href: '/tokens', icon: Key, label: 'Active Sessions', desc: 'Monitor & revoke tokens', color: 'text-purple-400' },
                { href: '/settings', icon: Activity, label: 'Settings', desc: 'Platform configuration', color: 'text-amber-400' },
              ].map((item) => (
                <Link
                  key={item.href}
                  href={item.href}
                  className="flex flex-col gap-2 p-4 rounded-lg border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 transition-colors"
                >
                  <item.icon className={`h-5 w-5 ${item.color}`} />
                  <div>
                    <p className="text-sm font-medium text-white">{item.label}</p>
                    <p className="text-xs text-slate-400">{item.desc}</p>
                  </div>
                </Link>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="bg-slate-900 border-slate-700">
          <CardHeader>
            <CardTitle className="text-white flex items-center gap-2">
              <Users className="h-5 w-5 text-indigo-400" />
              User Management
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Link
              href="/admin/users"
              className="flex items-center justify-between p-3 rounded-lg border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 transition-colors"
            >
              <div className="flex items-center gap-3">
                <UserCheck className="h-5 w-5 text-green-400" />
                <span className="text-sm text-slate-200">View All Users</span>
              </div>
              <span className="text-xs text-slate-400">{totalUsers} total</span>
            </Link>
            <Link
              href="/admin/users"
              className="flex items-center justify-between p-3 rounded-lg border border-slate-700 hover:border-indigo-500 hover:bg-slate-800 transition-colors"
            >
              <div className="flex items-center gap-3">
                <UserX className="h-5 w-5 text-red-400" />
                <span className="text-sm text-slate-200">Manage Superusers</span>
              </div>
              <span className="text-xs text-slate-400">Edit roles</span>
            </Link>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
