import posthog from 'posthog-js';

const POSTHOG_KEY = process.env.NEXT_PUBLIC_POSTHOG_KEY ?? '';
const POSTHOG_HOST = process.env.NEXT_PUBLIC_POSTHOG_HOST ?? 'https://us.i.posthog.com';

/**
 * Initialize PostHog. Safe to call multiple times — guards against double-init
 * and skips entirely when running in Node (SSR) or when no key is set.
 */
export function initPostHog() {
  if (typeof window === 'undefined' || !POSTHOG_KEY) return;
  if (posthog.__loaded) return;

  posthog.init(POSTHOG_KEY, {
    api_host: '/ingest',            // proxied through Next.js to avoid ad-blockers
    ui_host: POSTHOG_HOST,
    capture_pageview: false,        // we do this manually in PostHogProvider
    capture_pageleave: true,
    persistence: 'localStorage+cookie',
    person_profiles: 'identified_only',
    loaded: (ph) => {
      // In development, disable to avoid noise
      if (process.env.NODE_ENV === 'development') {
        ph.opt_out_capturing();
      }
    },
  });
}

export { posthog };
