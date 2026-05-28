import posthog from 'posthog-js';
import { getEnv } from '@/lib/env';

const POSTHOG_KEY = getEnv('VITE_POSTHOG_KEY', 'NEXT_PUBLIC_POSTHOG_KEY') ?? '';
const POSTHOG_HOST = getEnv('VITE_POSTHOG_HOST', 'NEXT_PUBLIC_POSTHOG_HOST') ?? 'https://us.i.posthog.com';
const NODE_ENV = getEnv('MODE', 'NODE_ENV') ?? 'development';

/**
 * Initialize PostHog. Safe to call multiple times — guards against double-init
 * and skips entirely when running in Node (SSR) or when no key is set.
 */
export function initPostHog() {
  if (typeof window === 'undefined' || !POSTHOG_KEY) return;
  if (posthog.__loaded) return;

  posthog.init(POSTHOG_KEY, {
    api_host: '/ingest',            // proxied through Vite dev server to avoid ad-blockers
    ui_host: POSTHOG_HOST,
    capture_pageview: false,        // we do this manually in PostHogProvider
    capture_pageleave: true,
    persistence: 'localStorage+cookie',
    person_profiles: 'identified_only',
    loaded: (ph) => {
      // In development, disable to avoid noise
      if (NODE_ENV === 'development') {
        ph.opt_out_capturing();
      }
    },
  });
}

export { posthog };
