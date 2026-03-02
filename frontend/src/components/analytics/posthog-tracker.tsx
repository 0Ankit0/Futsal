'use client';

import { useEffect, useRef } from 'react';
import { usePathname, useSearchParams } from 'next/navigation';
import { posthog, initPostHog } from '@/lib/posthog';
import { useAuthStore } from '@/store/auth-store';

/**
 * Initialises PostHog once, fires a $pageview on every navigation,
 * and identifies/resets users when auth state changes.
 *
 * Mount this inside a <Suspense> boundary because useSearchParams()
 * requires one in Next.js App Router.
 */
export function PostHogTracker() {
  const pathname = usePathname();
  const searchParams = useSearchParams();
  const { user, isAuthenticated } = useAuthStore();
  const prevUserIdRef = useRef<string | null>(null);

  // One-time init
  useEffect(() => {
    initPostHog();
  }, []);

  // Track page views
  useEffect(() => {
    if (typeof window === 'undefined' || !posthog.__loaded) return;
    const url = pathname + (searchParams?.toString() ? `?${searchParams}` : '');
    posthog.capture('$pageview', { $current_url: window.location.origin + url });
  }, [pathname, searchParams]);

  // Identify user on login, reset on logout
  useEffect(() => {
    if (typeof window === 'undefined' || !posthog.__loaded) return;

    if (isAuthenticated && user) {
      if (prevUserIdRef.current !== user.id) {
        const name = [user.first_name, user.last_name].filter(Boolean).join(' ') || user.username;
        posthog.identify(String(user.id), {
          email: user.email,
          name,
          username: user.username,
          is_superuser: user.is_superuser ?? false,
        });
        prevUserIdRef.current = user.id;
      }
    } else if (!isAuthenticated && prevUserIdRef.current !== null) {
      posthog.reset();
      prevUserIdRef.current = null;
    }
  }, [isAuthenticated, user]);

  return null;
}
