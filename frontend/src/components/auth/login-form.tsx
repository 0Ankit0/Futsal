'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useAuth } from '@/hooks/use-auth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardHeader, CardTitle, CardDescription, CardContent, CardFooter } from '@/components/ui/card';

const loginSchema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export function LoginForm() {
  const router = useRouter();
  const { loginAsync, isLoading, loginError } = useAuth();
  const [twoFactorError, setTwoFactorError] = useState<string | null>(null);
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = async (data: LoginFormData) => {
    try {
      setTwoFactorError(null);
      const result = await loginAsync(data);
      if (result && 'requires_otp' in result) {
        setTwoFactorError('Two-factor authentication is not enabled in the simplified booking app.');
        return;
      }
      router.push('/dashboard');
    } catch {
      return;
    }
  };

  const getErrorMessage = () => {
    if (!loginError) return null;
    const err = loginError as { response?: { data?: { detail?: string } } };
    return err?.response?.data?.detail || 'Invalid username or password. Please try again.';
  };

  return (
    <Card className="w-full max-w-md">
      <CardHeader className="text-center">
        <CardTitle>Welcome back</CardTitle>
        <CardDescription>Sign in to manage your futsal bookings.</CardDescription>
      </CardHeader>
      <form onSubmit={handleSubmit(onSubmit)}>
        <CardContent className="space-y-4">
          {(loginError || twoFactorError) && (
            <div className="rounded-lg bg-red-50 p-3 text-sm text-red-600">
              {twoFactorError ?? getErrorMessage()}
            </div>
          )}
          <Input
            id="username"
            type="text"
            label="Username"
            placeholder="your_username"
            {...register('username')}
            error={errors.username?.message}
          />
          <Input
            id="password"
            type="password"
            label="Password"
            placeholder="••••••••"
            {...register('password')}
            error={errors.password?.message}
          />
        </CardContent>
        <CardFooter className="flex flex-col gap-4">
          <Button type="submit" className="w-full bg-green-600 hover:bg-green-700" isLoading={isLoading}>
            Sign in
          </Button>

          <p className="text-center text-sm text-gray-600">
            Don&apos;t have an account?{' '}
            <Link href="/signup" className="text-green-600 hover:underline">
              Sign up
            </Link>
          </p>
        </CardFooter>
      </form>
    </Card>
  );
}
