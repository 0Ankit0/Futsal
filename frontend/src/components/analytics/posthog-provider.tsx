import { Suspense } from 'react';
import { PostHogTracker } from './posthog-tracker';

/**
 * Wraps PostHogTracker in a Suspense boundary (required by Next.js App Router
 * because PostHogTracker uses useSearchParams).
 * Add this once inside your root layout.
 */
export function PostHogProvider() {
  return (
    <Suspense fallback={null}>
      <PostHogTracker />
    </Suspense>
  );
}
