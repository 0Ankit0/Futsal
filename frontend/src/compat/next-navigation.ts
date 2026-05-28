import {
  useLocation,
  useNavigate,
  useParams as useReactRouterParams,
  useSearchParams as useReactRouterSearchParams,
} from 'react-router-dom';

interface NextLikeRouter {
  push: (href: string) => void;
  replace: (href: string) => void;
  back: () => void;
  forward: () => void;
  refresh: () => void;
  prefetch: (_href: string) => Promise<void>;
}

export function useRouter(): NextLikeRouter {
  const navigate = useNavigate();

  return {
    push: (href) => navigate(href),
    replace: (href) => navigate(href, { replace: true }),
    back: () => navigate(-1),
    forward: () => navigate(1),
    refresh: () => window.location.reload(),
    prefetch: async () => undefined,
  };
}

export function usePathname(): string {
  return useLocation().pathname;
}

export function useSearchParams(): URLSearchParams {
  const [params] = useReactRouterSearchParams();
  return params;
}

export function useParams<T extends Record<string, string | string[] | undefined>>() {
  return useReactRouterParams() as T;
}
