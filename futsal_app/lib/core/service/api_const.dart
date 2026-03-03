class ApiConst {
  // Update to your FastAPI server address (no trailing slash on base URL)
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator → host
  // Use 'http://localhost:8000' for iOS simulator / web
  // Use your production URL in production builds

  static const String _v1 = '/api/v1';

  // ── Auth ────────────────────────────────────────────────────────────────────
  static const String login = '$_v1/auth/login/';
  static const String signup = '$_v1/auth/signup/';
  static const String refresh = '$_v1/auth/refresh/';
  static const String logout = '$_v1/auth/logout/';
  static const String verifyEmail = '$_v1/auth/verify-email/';
  static const String resendVerification = '$_v1/auth/resend-verification/';
  static const String passwordResetRequest = '$_v1/auth/password-reset-request/';
  static const String passwordResetConfirm = '$_v1/auth/password-reset-confirm/';
  static const String changePassword = '$_v1/auth/change-password/';

  /// Mobile-only Google Sign-In — accepts {id_token} from google_sign_in SDK
  static const String mobileGoogleLogin = '$_v1/auth/social/google/mobile';

  // ── Users ───────────────────────────────────────────────────────────────────
  static const String userInfo = '$_v1/users/me';
  static const String uploadAvatar = '$_v1/users/me/avatar';

  // ── Futsal grounds ──────────────────────────────────────────────────────────
  static const String grounds = '$_v1/futsal/grounds';
  static String groundDetail(int id) => '$_v1/futsal/grounds/$id';
  static String groundSlots(int id) => '$_v1/futsal/grounds/$id/slots';
  static String groundImages(int id) => '$_v1/futsal/grounds/$id/images';
  static String groundReviews(int id) => '$_v1/futsal/grounds/$id/reviews';

  // ── Bookings ─────────────────────────────────────────────────────────────
  static const String bookings = '$_v1/futsal/bookings';
  static String bookingDetail(int id) => '$_v1/futsal/bookings/$id';
  static String cancelBooking(int id) => '$_v1/futsal/bookings/$id/cancel';
  static String bookingQr(int id) => '$_v1/futsal/bookings/$id/qr';
  static String checkInBooking(int id) => '$_v1/futsal/bookings/$id/checkin';

  // ── Favourites ────────────────────────────────────────────────────────────
  static const String favourites = '$_v1/futsal/favourites';
  static String addFavourite(int groundId) => '$_v1/futsal/favourites/$groundId';
  static String removeFavourite(int groundId) => '$_v1/futsal/favourites/$groundId';

  // ── Reviews ───────────────────────────────────────────────────────────────
  static String createReview(int groundId) => '$_v1/futsal/grounds/$groundId/reviews';
  static String reviewDetail(int reviewId) => '$_v1/futsal/reviews/$reviewId';

  // ── Loyalty ───────────────────────────────────────────────────────────────
  static const String loyaltyAccount = '$_v1/futsal/loyalty';
  static const String loyaltyHistory = '$_v1/futsal/loyalty/history';

  // ── Waitlist ──────────────────────────────────────────────────────────────
  static const String waitlist = '$_v1/futsal/waitlist';
  static String removeWaitlist(int entryId) => '$_v1/futsal/waitlist/$entryId';
}
