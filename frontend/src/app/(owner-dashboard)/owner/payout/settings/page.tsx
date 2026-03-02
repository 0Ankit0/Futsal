'use client';

import { useState } from 'react';
import { usePayoutGateway, useConfigureGateway } from '@/hooks/use-futsal';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Shield, CheckCircle, AlertTriangle } from 'lucide-react';

type Provider = 'khalti' | 'esewa' | 'bank_transfer';

export default function PaymentSettingsPage() {
  const { data: gateway, isLoading } = usePayoutGateway();
  const { mutate: configure, isPending } = useConfigureGateway();

  const [provider, setProvider] = useState<Provider>('khalti');
  const [accountName, setAccountName] = useState('');
  const [mobile, setMobile] = useState('');
  const [secretKey, setSecretKey] = useState('');
  const [bankName, setBankName] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    let credentials: Record<string, string> = {};
    if (provider === 'khalti') {
      credentials = { mobile, secret_key: secretKey };
    } else if (provider === 'esewa') {
      credentials = { mobile, merchant_code: secretKey };
    } else {
      credentials = { bank_name: bankName, account_number: accountNumber, account_name: accountName };
    }
    configure({ provider, account_name: accountName, credentials }, {
      onSuccess: () => setSuccess(true),
      onError: () => setError('Failed to save gateway configuration. Please try again.'),
    });
  };

  return (
    <div className="max-w-2xl space-y-6">
      <h1 className="text-2xl font-bold text-gray-900">Payment Gateway Settings</h1>

      {gateway && (
        <Card className="border-green-200 bg-green-50">
          <CardContent className="p-4 flex items-center gap-3">
            {gateway.is_verified ? (
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0" />
            ) : (
              <AlertTriangle className="h-5 w-5 text-yellow-600 flex-shrink-0" />
            )}
            <div>
              <p className="font-medium text-sm">
                {gateway.provider.toUpperCase()} — {gateway.account_name}
              </p>
              <p className="text-xs text-gray-500">
                Account: {gateway.account_number_hint} ·{' '}
                {gateway.is_verified ? (
                  <span className="text-green-600 font-medium">Verified ✓</span>
                ) : (
                  <span className="text-yellow-600">Awaiting superuser verification</span>
                )}
              </p>
            </div>
          </CardContent>
        </Card>
      )}

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Shield className="h-5 w-5 text-green-600" />
            Configure Payout Gateway
          </CardTitle>
          <p className="text-sm text-gray-500">
            Your credentials are encrypted with AES-256 and never exposed in plain text.
            A superuser will verify your gateway before the first payout is processed.
          </p>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <Label>Gateway Provider</Label>
              <select
                className="w-full border rounded-lg px-3 py-2 mt-1 text-sm"
                value={provider}
                onChange={(e) => setProvider(e.target.value as Provider)}
              >
                <option value="khalti">Khalti</option>
                <option value="esewa">eSewa</option>
                <option value="bank_transfer">Bank Transfer</option>
              </select>
            </div>

            <div>
              <Label>Account Holder Name</Label>
              <Input
                value={accountName}
                onChange={(e) => setAccountName(e.target.value)}
                placeholder="Full name on account"
                required
              />
            </div>

            {(provider === 'khalti' || provider === 'esewa') && (
              <>
                <div>
                  <Label>Registered Mobile Number</Label>
                  <Input
                    value={mobile}
                    onChange={(e) => setMobile(e.target.value)}
                    placeholder="98XXXXXXXX"
                    required
                  />
                </div>
                <div>
                  <Label>{provider === 'khalti' ? 'Secret Key' : 'Merchant Code'}</Label>
                  <Input
                    type="password"
                    value={secretKey}
                    onChange={(e) => setSecretKey(e.target.value)}
                    placeholder="Your secret key"
                    required
                  />
                </div>
              </>
            )}

            {provider === 'bank_transfer' && (
              <>
                <div>
                  <Label>Bank Name</Label>
                  <Input value={bankName} onChange={(e) => setBankName(e.target.value)} required />
                </div>
                <div>
                  <Label>Account Number</Label>
                  <Input value={accountNumber} onChange={(e) => setAccountNumber(e.target.value)} required />
                </div>
              </>
            )}

            {error && <p className="text-red-500 text-sm">{error}</p>}
            {success && <p className="text-green-600 text-sm">✓ Gateway configured! Awaiting verification.</p>}

            <Button
              type="submit"
              disabled={isPending}
              className="bg-green-600 hover:bg-green-700"
            >
              {isPending ? 'Saving...' : gateway ? 'Update Gateway' : 'Save Gateway'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  );
}
