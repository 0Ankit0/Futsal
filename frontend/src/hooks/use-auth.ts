'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import { useAuthStore } from '@/store/auth-store';
import type {
  LoginCredentials,
  SignupData,
  AuthTokens,
  User,
  OTPLoginResponse,
  VerifyOTPData,
  OTPSetupResponse,
  ChangePasswordData,
  ResetPasswordRequestData,
  ResetPasswordConfirmData,
} from '@/types';

export function useAuth() {
  const queryClient = useQueryClient();
  const { user, setUser, setTokens, logout: storeLogout } = useAuthStore();

  const loginMutation = useMutation({
    mutationFn: async (credentials: LoginCredentials) => {
      const response = await apiClient.post<AuthTokens | OTPLoginResponse>(
        '/auth/login/',
        credentials,
        { params: { set_cookie: false } }
      );
      return response.data;
    },
    onSuccess: (data) => {
      if ('requires_otp' in data) return;
      const tokens = data as AuthTokens;
      setTokens(tokens.access, tokens.refresh);
      queryClient.invalidateQueries({ queryKey: ['currentUser'] });
    },
  });

  const signupMutation = useMutation({
    mutationFn: async (data: SignupData) => {
      const response = await apiClient.post<AuthTokens>(
        '/auth/signup/',
        data,
        { params: { set_cookie: false } }
      );
      return response.data;
    },
    onSuccess: (data) => {
      setTokens(data.access, data.refresh);
      queryClient.invalidateQueries({ queryKey: ['currentUser'] });
    },
  });

  const { data: currentUser, refetch: refetchUser } = useQuery({
    queryKey: ['currentUser'],
    queryFn: async () => {
      const response = await apiClient.get<User>('/users/me/');
      setUser(response.data);
      return response.data;
    },
    enabled: typeof window !== 'undefined' && !!localStorage.getItem('access_token'),
  });

  const logout = async () => {
    try {
      await apiClient.post('/auth/logout/');
    } catch {
      // ignore logout errors
    } finally {
      storeLogout();
      queryClient.clear();
      if (typeof window !== 'undefined') {
        window.location.href = '/login';
      }
    }
  };

  return {
    user: currentUser || user,
    isAuthenticated: !!(currentUser || user),
    login: loginMutation.mutate,
    loginAsync: loginMutation.mutateAsync,
    signup: signupMutation.mutate,
    signupAsync: signupMutation.mutateAsync,
    logout,
    refetchUser,
    isLoading: loginMutation.isPending || signupMutation.isPending,
    loginError: loginMutation.error,
    signupError: signupMutation.error,
  };
}

export function useVerifyOTP() {
  const { setTokens } = useAuthStore();
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (data: VerifyOTPData) => {
      const response = await apiClient.post<AuthTokens>(
        '/auth/otp/validate/',
        data,
        { params: { set_cookie: false } }
      );
      return response.data;
    },
    onSuccess: (data) => {
      setTokens(data.access, data.refresh);
      queryClient.invalidateQueries({ queryKey: ['currentUser'] });
    },
  });
}

export function useEnableOTP() {
  return useMutation({
    mutationFn: async () => {
      const response = await apiClient.post<OTPSetupResponse>('/auth/otp/enable/');
      return response.data;
    },
  });
}

export function useConfirmOTP() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (otp_code: string) => {
      const response = await apiClient.post('/auth/otp/verify/', { otp_code, temp_token: '' });
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['currentUser'] });
    },
  });
}

export function useDisableOTP() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (password: string) => {
      const response = await apiClient.post('/auth/otp/disable/', { password });
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['currentUser'] });
    },
  });
}

export function useRequestPasswordReset() {
  return useMutation({
    mutationFn: async (data: ResetPasswordRequestData) => {
      const response = await apiClient.post('/auth/password-reset-request/', data);
      return response.data;
    },
  });
}

export function useConfirmPasswordReset() {
  return useMutation({
    mutationFn: async (data: ResetPasswordConfirmData) => {
      const response = await apiClient.post('/auth/password-reset-confirm/', data);
      return response.data;
    },
  });
}

export function useChangePassword() {
  return useMutation({
    mutationFn: async (data: ChangePasswordData) => {
      const response = await apiClient.post('/auth/change-password/', data);
      return response.data;
    },
  });
}

export function useVerifyEmail() {
  return useMutation({
    mutationFn: async (t: string) => {
      const response = await apiClient.post('/auth/verify-email/', null, { params: { t } });
      return response.data;
    },
  });
}

export function useResendVerification() {
  return useMutation({
    mutationFn: async () => {
      const response = await apiClient.post('/auth/resend-verification/');
      return response.data;
    },
  });
}
