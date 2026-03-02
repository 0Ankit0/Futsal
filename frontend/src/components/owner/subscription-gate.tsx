'use client';

import Link from 'next/link';
import { useSubscription } from '@/hooks/use-subscription';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { LockKeyhole } from 'lucide-react';

interface SubscriptionGateProps {
  children: React.ReactNode;
}

export function SubscriptionGate({ children }: SubscriptionGateProps) {
  const { data: subscription, isLoading } = useSubscription();

  if (isLoading) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full" />
      </div>
    );
  }

  if (!subscription?.is_active) {
    const status = subscription?.status ?? 'UNKNOWN';

    const statusColors: Record<string, string> = {
      EXPIRED: 'bg-red-100 text-red-700',
      GRACE: 'bg-yellow-100 text-yellow-700',
      CANCELLED: 'bg-gray-100 text-gray-600',
      TRIALING: 'bg-blue-100 text-blue-700',
      UNKNOWN: 'bg-gray-100 text-gray-600',
    };

    return (
      <div className="flex min-h-[60vh] items-center justify-center p-6">
        <Card className="w-full max-w-md shadow-md">
          <CardContent className="flex flex-col items-center gap-4 py-10 text-center">
            <div className="flex h-14 w-14 items-center justify-center rounded-full bg-red-50">
              <LockKeyhole className="h-7 w-7 text-red-500" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-900">Subscription Required</h2>
              <p className="mt-2 text-sm text-gray-500">
                Your subscription has expired or is not active. Subscribe to access your owner
                dashboard.
              </p>
            </div>
            <span
              className={`rounded-full px-3 py-1 text-xs font-semibold uppercase ${
                statusColors[status] ?? statusColors.UNKNOWN
              }`}
            >
              {status}
            </span>
            <Link href="/owner/subscription">
              <Button className="mt-2 bg-green-600 hover:bg-green-700">View Plans</Button>
            </Link>
          </CardContent>
        </Card>
      </div>
    );
  }

  return <>{children}</>;
}
