'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { apiClient } from '@/lib/api-client';
import type {
  InitiatePaymentRequest,
  InitiatePaymentResponse,
  VerifyPaymentRequest,
  VerifyPaymentResponse,
  PaymentTransaction,
  PaymentProvider,
} from '@/types';

export function usePaymentProviders() {
  return useQuery({
    queryKey: ['payment-providers'],
    queryFn: async () => {
      const response = await apiClient.get<PaymentProvider[]>('/payments/providers/');
      return response.data;
    },
  });
}

export function useInitiatePayment() {
  return useMutation({
    mutationFn: async (data: InitiatePaymentRequest) => {
      const response = await apiClient.post<InitiatePaymentResponse>('/payments/initiate/', data);
      return response.data;
    },
  });
}

export function useVerifyPayment() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (data: VerifyPaymentRequest) => {
      const response = await apiClient.post<VerifyPaymentResponse>('/payments/verify/', data);
      return response.data;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transactions'] });
    },
  });
}

export function useTransaction(transactionId: number) {
  return useQuery({
    queryKey: ['transactions', transactionId],
    queryFn: async () => {
      const response = await apiClient.get<PaymentTransaction>(`/payments/${transactionId}/`);
      return response.data;
    },
    enabled: !!transactionId,
  });
}

/** Backend returns list (not paginated). Uses offset/limit params. */
export function useTransactions(params?: { limit?: number; offset?: number; provider?: string }) {
  return useQuery({
    queryKey: ['transactions', params],
    queryFn: async () => {
      const response = await apiClient.get<PaymentTransaction[]>('/payments/', { params });
      return response.data;
    },
  });
}
