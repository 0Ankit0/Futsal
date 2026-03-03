'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  Users,
  Shield,
  Settings,
  Activity,
  MapPin,
  Wallet,
  BadgeCheck,
  BarChart2,
} from 'lucide-react';
import { OrgSwitcher } from './org-switcher';

const adminNavigation = [
  { name: 'Admin Dashboard', href: '/admin/dashboard',    icon: LayoutDashboard },
  { name: 'Analytics',       href: '/admin/analytics',    icon: BarChart2 },
  { name: 'Manage Users',    href: '/admin/users',        icon: Users },
  { name: 'Roles & Permissions', href: '/rbac',           icon: Shield },
  { name: 'Active Sessions', href: '/tokens',             icon: Activity },
  { name: 'Grounds',         href: '/admin/grounds',      icon: MapPin },
  { name: 'Payouts',         href: '/admin/payouts',      icon: Wallet },
  { name: 'Subscriptions',   href: '/admin/subscriptions',icon: BadgeCheck },
  { name: 'Settings',        href: '/settings',           icon: Settings },
];

export function AdminSidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed inset-y-0 left-0 z-10 w-64 bg-indigo-950 border-r border-indigo-800">
      <div className="flex h-16 items-center justify-center border-b border-indigo-800">
        <Link href="/admin/dashboard" className="text-xl font-bold text-indigo-300">
          Admin Panel
        </Link>
      </div>
      <OrgSwitcher />
      <nav className="flex flex-col gap-1 p-4 pt-0">
        <div className="mb-2 px-3 py-1 text-xs font-semibold text-indigo-400 uppercase tracking-wider">
          Administration
        </div>
        {adminNavigation.map((item) => {
          const isActive =
            pathname === item.href || pathname.startsWith(`${item.href}/`);
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-indigo-700 text-white'
                  : 'text-indigo-200 hover:bg-indigo-800 hover:text-white'
              }`}
            >
              <item.icon className="h-5 w-5" />
              {item.name}
            </Link>
          );
        })}
      </nav>
    </aside>
  );
}
