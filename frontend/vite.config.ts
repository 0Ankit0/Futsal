import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const posthogHost = env.VITE_POSTHOG_HOST || env.NEXT_PUBLIC_POSTHOG_HOST || 'https://us.i.posthog.com';

  return {
    plugins: [react()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src'),
        'next/link': path.resolve(__dirname, 'src/compat/next-link.tsx'),
        'next/navigation': path.resolve(__dirname, 'src/compat/next-navigation.ts'),
        'next/font/google': path.resolve(__dirname, 'src/compat/next-font-google.ts'),
        'next/image': path.resolve(__dirname, 'src/compat/next-image.tsx'),
        next: path.resolve(__dirname, 'src/compat/next.ts'),
      },
    },
    server: {
      proxy: {
        '/api/v1': {
          target: 'http://localhost:8000',
          changeOrigin: true,
        },
        '/ingest': {
          target: posthogHost,
          changeOrigin: true,
          rewrite: (p) => p.replace(/^\/ingest/, ''),
        },
      },
    },
  };
});
