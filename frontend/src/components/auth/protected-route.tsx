'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/store/auth-store';
import { apiClient } from '@/lib/api-client';

interface ProtectedRouteProps {
  children: React.ReactNode;
}

const AUTH_CHECKED_AT_KEY = 'auth_checked_at';
const AUTH_CHECKED_TOKEN_KEY = 'auth_checked_token';
const AUTH_CHECK_TTL_MS = 5 * 60_000;
let validatingUserPromise: Promise<unknown> | null = null;

export function ProtectedRoute({ children }: ProtectedRouteProps) {
  const router = useRouter();
  const { _hasHydrated, setUser, logout } = useAuthStore();
  const [isInitializing, setIsInitializing] = useState(true);

  useEffect(() => {
    if (!_hasHydrated) return;

    async function initAuth() {
      const accessToken = typeof window !== 'undefined' ? localStorage.getItem('access_token') : null;
      const hasAccessToken = !!accessToken;
      const hasRefreshToken = typeof window !== 'undefined' && !!localStorage.getItem('refresh_token');

      if (!hasAccessToken && !hasRefreshToken) {
        router.push('/login');
        setIsInitializing(false);
        return;
      }

      if (hasAccessToken && typeof window !== 'undefined' && accessToken) {
        const lastCheckedAt = Number(sessionStorage.getItem(AUTH_CHECKED_AT_KEY) || '0');
        const lastCheckedToken = sessionStorage.getItem(AUTH_CHECKED_TOKEN_KEY);
        if (lastCheckedToken === accessToken && Date.now() - lastCheckedAt < AUTH_CHECK_TTL_MS) {
          setIsInitializing(false);
          return;
        }
      }

      try {
        // Deduplicate user validation when multiple protected routes mount together.
        if (!validatingUserPromise) {
          validatingUserPromise = apiClient.get('/users/me').finally(() => {
            validatingUserPromise = null;
          });
        }
        const userRes = await validatingUserPromise;
        setUser(userRes.data);
        if (typeof window !== 'undefined') {
          const freshAccessToken = localStorage.getItem('access_token');
          if (freshAccessToken) {
            sessionStorage.setItem(AUTH_CHECKED_AT_KEY, String(Date.now()));
            sessionStorage.setItem(AUTH_CHECKED_TOKEN_KEY, freshAccessToken);
          }
        }
      } catch {
        logout();
        router.push('/login');
      } finally {
        setIsInitializing(false);
      }
    }

    initAuth();
  }, [_hasHydrated, router, setUser, logout]);

  // While Zustand is rehydrating from localStorage or we're attempting a refresh
  if (!_hasHydrated || isInitializing) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
      </div>
    );
  }

  return <>{children}</>;
}
