import { useQuery } from '@tanstack/react-query';
import apiClient from '@/lib/api-client';

export type SocialProvider = 'google' | 'github' | 'facebook';

async function fetchEnabledProviders(): Promise<SocialProvider[]> {
  const { data } = await apiClient.get<{ providers: SocialProvider[] }>('/auth/social/providers');
  return data.providers;
}

/**
 * Returns the list of social login providers that are enabled on the backend.
 * Components use this to conditionally render social login buttons.
 */
export function useSocialProviders() {
  const { data = [], isLoading } = useQuery({
    queryKey: ['social-providers'],
    queryFn: fetchEnabledProviders,
    staleTime: 5 * 60 * 1000, // cache for 5 minutes
  });

  return {
    enabledProviders: data,
    isGoogle: data.includes('google'),
    isGithub: data.includes('github'),
    isFacebook: data.includes('facebook'),
    hasAny: data.length > 0,
    isLoading,
  };
}
