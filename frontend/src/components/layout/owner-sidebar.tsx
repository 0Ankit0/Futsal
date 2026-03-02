'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  MapPin,
  Calendar,
  BarChart3,
  Star,
  Wallet,
  CreditCard,
  Users,
  BadgeCheck,
} from 'lucide-react';

const navigation = [
  { name: 'Dashboard', href: '/owner/dashboard', icon: LayoutDashboard },
  { name: 'My Grounds', href: '/owner/grounds', icon: MapPin },
  { name: 'Bookings', href: '/owner/bookings', icon: Calendar },
  { name: 'Analytics', href: '/owner/analytics', icon: BarChart3 },
  { name: 'Reviews', href: '/owner/reviews', icon: Star },
  { name: 'Team', href: '/owner/team', icon: Users },
  { name: 'Payouts', href: '/owner/payout', icon: Wallet },
  { name: 'Payment Settings', href: '/owner/payout/settings', icon: CreditCard },
  { name: 'Subscription', href: '/owner/subscription', icon: BadgeCheck },
];

export function OwnerSidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed inset-y-0 left-0 z-10 w-64 bg-white border-r border-gray-200">
      <div className="flex h-16 items-center justify-center border-b border-gray-200">
        <Link href="/owner/dashboard" className="text-xl font-bold text-green-600">
          ⚽ Futsal Owner
        </Link>
      </div>
      <nav className="flex flex-col gap-1 p-4">
        {navigation.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(`${item.href}/`);
          return (
            <Link
              key={item.name}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-green-50 text-green-600'
                  : 'text-gray-700 hover:bg-gray-100'
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
