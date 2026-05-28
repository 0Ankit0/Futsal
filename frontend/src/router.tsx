import { BrowserRouter, Navigate, Outlet, Route, Routes, useParams } from 'react-router-dom';
import { Providers } from '@/components/providers';
import AuthLayout from '@/app/(auth)/layout';
import UserDashboardLayout from '@/app/(user-dashboard)/layout';
import OwnerDashboardLayout from '@/app/(owner-dashboard)/layout';
import AdminDashboardLayout from '@/app/(admin-dashboard)/layout';

import PublicLandingPage from '@/app/(public)/page';
import GroundsPage from '@/app/(public)/grounds/page';
import GroundDetailPage from '@/app/(public)/grounds/[slug]/page';
import BookingFormPage from '@/app/(public)/grounds/[slug]/book/page';
import BookingConfirmationPage from '@/app/(public)/booking/[id]/confirmation/page';

import LoginPage from '@/app/(auth)/login/page';
import SignupPage from '@/app/(auth)/signup/page';
import VerifyEmailPage from '@/app/(auth)/verify-email/page';
import ForgotPasswordPage from '@/app/(auth)/forgot-password/page';
import ResetPasswordPage from '@/app/(auth)/reset-password/page';
import OTPVerifyPage from '@/app/(auth)/otp-verify/page';
import AcceptInvitationPage from '@/app/(auth)/accept-invitation/page';
import AuthCallbackPage from '@/app/(auth)/auth-callback/page';
import PaymentCallbackPage from '@/app/(auth)/payment-callback/page';

import UserDashboardPage from '@/app/(user-dashboard)/dashboard/page';
import MyBookingsPage from '@/app/(user-dashboard)/my-bookings/page';
import FavouritesPage from '@/app/(user-dashboard)/favourites/page';
import LoyaltyPage from '@/app/(user-dashboard)/loyalty/page';
import NotificationsPage from '@/app/(user-dashboard)/notifications/page';
import SettingsPage from '@/app/(user-dashboard)/settings/page';
import ProfilePage from '@/app/(user-dashboard)/profile/page';
import FinancesPage from '@/app/(user-dashboard)/finances/page';
import RBACPage from '@/app/(user-dashboard)/rbac/page';
import RoleManagePage from '@/app/(user-dashboard)/rbac/[roleId]/page';
import TenantsPage from '@/app/(user-dashboard)/tenants/page';
import TokensPage from '@/app/(user-dashboard)/tokens/page';

import OwnerDashboardPage from '@/app/(owner-dashboard)/owner/dashboard/page';
import OwnerGroundsPage from '@/app/(owner-dashboard)/owner/grounds/page';
import OwnerGroundCreatePage from '@/app/(owner-dashboard)/owner/grounds/new/page';
import OwnerGroundEditPage from '@/app/(owner-dashboard)/owner/grounds/[id]/page';
import OwnerBookingsPage from '@/app/(owner-dashboard)/owner/bookings/page';
import OwnerPayoutPage from '@/app/(owner-dashboard)/owner/payout/page';
import OwnerPayoutSettingsPage from '@/app/(owner-dashboard)/owner/payout/settings/page';
import OwnerAnalyticsPage from '@/app/(owner-dashboard)/owner/analytics/page';
import OwnerReviewsPage from '@/app/(owner-dashboard)/owner/reviews/page';
import OwnerSubscriptionPage from '@/app/(owner-dashboard)/owner/subscription/page';
import OwnerTeamPage from '@/app/(owner-dashboard)/owner/team/page';

import AdminDashboardPage from '@/app/(admin-dashboard)/admin/dashboard/page';
import AdminUsersPage from '@/app/(admin-dashboard)/admin/users/page';
import AdminGroundsPage from '@/app/(admin-dashboard)/admin/grounds/page';
import AdminPayoutsPage from '@/app/(admin-dashboard)/admin/payouts/page';
import AdminSubscriptionsPage from '@/app/(admin-dashboard)/admin/subscriptions/page';
import AdminAnalyticsPage from '@/app/(admin-dashboard)/admin/analytics/page';

function DynamicGroundDetailPage() {
  const { slug = '' } = useParams();
  return <GroundDetailPage params={{ slug }} />;
}

function DynamicBookingFormPage() {
  const { slug = '' } = useParams();
  return <BookingFormPage params={{ slug }} />;
}

function DynamicBookingConfirmationPage() {
  const { id = '' } = useParams();
  return <BookingConfirmationPage params={{ id }} />;
}

function DynamicRoleManagePage() {
  const { roleId = '' } = useParams();
  return <RoleManagePage params={Promise.resolve({ roleId })} />;
}

function RootLayout() {
  return (
    <Providers>
      <Outlet />
    </Providers>
  );
}

function NotFoundPage() {
  return <Navigate to="/" replace />;
}

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<RootLayout />}>
          <Route path="/" element={<PublicLandingPage />} />
          <Route path="/grounds" element={<GroundsPage />} />
          <Route path="/grounds/:slug" element={<DynamicGroundDetailPage />} />
          <Route path="/grounds/:slug/book" element={<DynamicBookingFormPage />} />
          <Route path="/booking/:id/confirmation" element={<DynamicBookingConfirmationPage />} />

          <Route element={<AuthLayout><Outlet /></AuthLayout>}>
            <Route path="/login" element={<LoginPage />} />
            <Route path="/signup" element={<SignupPage />} />
            <Route path="/verify-email" element={<VerifyEmailPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />
            <Route path="/otp-verify" element={<OTPVerifyPage />} />
            <Route path="/accept-invitation" element={<AcceptInvitationPage />} />
            <Route path="/auth-callback" element={<AuthCallbackPage />} />
            <Route path="/payment-callback" element={<PaymentCallbackPage />} />
          </Route>

          <Route element={<UserDashboardLayout><Outlet /></UserDashboardLayout>}>
            <Route path="/dashboard" element={<UserDashboardPage />} />
            <Route path="/my-bookings" element={<MyBookingsPage />} />
            <Route path="/favourites" element={<FavouritesPage />} />
            <Route path="/loyalty" element={<LoyaltyPage />} />
            <Route path="/notifications" element={<NotificationsPage />} />
            <Route path="/settings" element={<SettingsPage />} />
            <Route path="/profile" element={<ProfilePage />} />
            <Route path="/finances" element={<FinancesPage />} />
            <Route path="/rbac" element={<RBACPage />} />
            <Route path="/rbac/:roleId" element={<DynamicRoleManagePage />} />
            <Route path="/tenants" element={<TenantsPage />} />
            <Route path="/tokens" element={<TokensPage />} />
          </Route>

          <Route element={<OwnerDashboardLayout><Outlet /></OwnerDashboardLayout>}>
            <Route path="/owner/dashboard" element={<OwnerDashboardPage />} />
            <Route path="/owner/grounds" element={<OwnerGroundsPage />} />
            <Route path="/owner/grounds/new" element={<OwnerGroundCreatePage />} />
            <Route path="/owner/grounds/:id" element={<OwnerGroundEditPage />} />
            <Route path="/owner/bookings" element={<OwnerBookingsPage />} />
            <Route path="/owner/payout" element={<OwnerPayoutPage />} />
            <Route path="/owner/payout/settings" element={<OwnerPayoutSettingsPage />} />
            <Route path="/owner/analytics" element={<OwnerAnalyticsPage />} />
            <Route path="/owner/reviews" element={<OwnerReviewsPage />} />
            <Route path="/owner/subscription" element={<OwnerSubscriptionPage />} />
            <Route path="/owner/team" element={<OwnerTeamPage />} />
          </Route>

          <Route element={<AdminDashboardLayout><Outlet /></AdminDashboardLayout>}>
            <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
            <Route path="/admin/users" element={<AdminUsersPage />} />
            <Route path="/admin/grounds" element={<AdminGroundsPage />} />
            <Route path="/admin/payouts" element={<AdminPayoutsPage />} />
            <Route path="/admin/subscriptions" element={<AdminSubscriptionsPage />} />
            <Route path="/admin/analytics" element={<AdminAnalyticsPage />} />
          </Route>

          <Route path="*" element={<NotFoundPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
