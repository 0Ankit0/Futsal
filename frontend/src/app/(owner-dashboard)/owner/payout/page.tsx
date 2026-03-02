'use client';

import { usePayoutHistory, usePayoutLedger, usePendingBalance } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Wallet, ArrowDownCircle, Clock } from 'lucide-react';
import Link from 'next/link';
import { Button } from '@/components/ui/button';

const STATUS_COLORS: Record<string, string> = {
  pending:    'bg-yellow-100 text-yellow-700',
  processing: 'bg-blue-100 text-blue-700',
  completed:  'bg-green-100 text-green-700',
  failed:     'bg-red-100 text-red-700',
  on_hold:    'bg-orange-100 text-orange-700',
};

export default function OwnerPayoutPage() {
  const { data: balance } = usePendingBalance();
  const { data: history = [], isLoading } = usePayoutHistory();
  const { data: ledger = [] } = usePayoutLedger(false);

  const totalPaid = history
    .filter((r) => r.status === 'completed')
    .reduce((s, r) => s + r.net_amount, 0);

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900">Payouts</h1>
        <Link href="/owner/payout/settings">
          <Button variant="outline">Configure Payment Gateway</Button>
        </Link>
      </div>

      {/* Balance cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="rounded-full p-3 bg-green-50">
                <Wallet className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Pending Payout</p>
                <p className="text-2xl font-bold text-green-600">
                  NPR {balance?.pending_amount?.toLocaleString() ?? 0}
                </p>
                <p className="text-xs text-gray-400">{balance?.pending_bookings ?? 0} bookings</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="rounded-full p-3 bg-blue-50">
                <ArrowDownCircle className="h-6 w-6 text-blue-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Total Paid Out</p>
                <p className="text-2xl font-bold">NPR {totalPaid.toLocaleString()}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-4">
              <div className="rounded-full p-3 bg-yellow-50">
                <Clock className="h-6 w-6 text-yellow-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Next Payout</p>
                <p className="text-lg font-semibold">Daily at midnight</p>
                <p className="text-xs text-gray-400">UTC 00:00</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Payout history */}
      <Card>
        <CardHeader><CardTitle>Payout History</CardTitle></CardHeader>
        <CardContent>
          {isLoading ? (
            <p className="text-gray-400">Loading...</p>
          ) : history.length === 0 ? (
            <p className="text-gray-400">No payouts yet. Payouts are processed daily at midnight.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-left text-gray-500">
                    <th className="pb-2 font-medium">Date</th>
                    <th className="pb-2 font-medium">Bookings</th>
                    <th className="pb-2 font-medium">Gross</th>
                    <th className="pb-2 font-medium">Platform Fee</th>
                    <th className="pb-2 font-medium">Net</th>
                    <th className="pb-2 font-medium">Status</th>
                    <th className="pb-2 font-medium">Ref</th>
                  </tr>
                </thead>
                <tbody className="divide-y">
                  {history.map((r) => (
                    <tr key={r.id}>
                      <td className="py-3">{r.period_start}</td>
                      <td className="py-3">{r.total_bookings}</td>
                      <td className="py-3">NPR {r.gross_amount.toLocaleString()}</td>
                      <td className="py-3 text-red-500">-NPR {r.platform_fee.toLocaleString()}</td>
                      <td className="py-3 font-semibold text-green-600">NPR {r.net_amount.toLocaleString()}</td>
                      <td className="py-3">
                        <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${STATUS_COLORS[r.status] ?? ''}`}>
                          {r.status}
                        </span>
                      </td>
                      <td className="py-3 text-gray-400 text-xs">{r.transaction_ref ?? '—'}</td>
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
