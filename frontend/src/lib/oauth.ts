export type OAuthProvider = 'google' | 'github' | 'facebook';

export function startOAuthLogin(provider: OAuthProvider) {
  const state = Math.random().toString(36).substring(7);
  sessionStorage.setItem('oauth_state', state);

  const backendUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1';
  const authUrl = `${backendUrl}/auth/social/${provider}/?state=${state}`;

  const width = 500;
  const height = 600;
  const left = window.screen.width / 2 - width / 2;
  const top = window.screen.height / 2 - height / 2;

  window.open(
    authUrl,
    `Sign in with ${provider}`,
    `width=${width},height=${height},left=${left},top=${top}`
  );
}
