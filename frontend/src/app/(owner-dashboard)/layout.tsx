'use client';

import { ProtectedRoute } from '@/components/auth/protected-route';
import { OwnerSidebar } from '@/components/layout/owner-sidebar';
import { Header } from '@/components/layout/header';

export default function OwnerDashboardLayout({ children }: { children: React.ReactNode }) {
  return (
    <ProtectedRoute>
      <div className="min-h-screen bg-gray-50">
        <OwnerSidebar />
        <Header />
        <main className="ml-64 pt-16 p-6">{children}</main>
      </div>
    </ProtectedRoute>
  );
}
