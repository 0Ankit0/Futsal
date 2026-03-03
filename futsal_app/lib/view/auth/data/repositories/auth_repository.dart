import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui/core/service/api_service.dart';
import 'package:ui/core/service/api_const.dart';
import 'package:ui/view/auth/data/model/auth_model.dart';

import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  // SharedPreferences keys
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryTimeKey = 'expiry_time';

  // ── Email / password login ──────────────────────────────────────────────────
  /// FastAPI login accepts {username, password} — username may be an email too.
  Future<AuthResponseModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConst.login,
        data: {'username': username, 'password': password},
      );
      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // ── Native Google Sign-In (mobile only) ────────────────────────────────────
  /// Uses google_sign_in to obtain a Google ID token, then exchanges it with
  /// the backend's /auth/social/google/mobile endpoint for JWT tokens.
  /// No Firebase dependency — the backend verifies the token directly.
  Future<AuthResponseModel> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final String? idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception(
          'Failed to obtain Google ID token. '
          'Make sure OAuth client ID is configured correctly.',
        );
      }

      // Exchange the Google ID token for our backend JWT tokens
      final response = await _apiService.post(
        ApiConst.mobileGoogleLogin,
        data: {'id_token': idToken},
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // ── Registration ────────────────────────────────────────────────────────────
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String username,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConst.signup,
        data: {
          'email': email,
          'username': username,
          'password': password,
          'confirm_password': password,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        },
      );
      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // ── Token refresh ───────────────────────────────────────────────────────────
  Future<AuthResponseModel> refreshToken() async {
    try {
      final storedRefresh = await _getRefreshToken();
      if (storedRefresh == null) {
        throw ApiException('No refresh token found');
      }

      final response = await _apiService.post(
        ApiConst.refresh,
        data: {'refresh': storedRefresh},
      );

      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      await _clearAuthData();
      rethrow;
    }
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      try {
        await _apiService.post(ApiConst.logout);
      } catch (_) {
        // Ignore API errors during logout
      }
      // Sign out of Google if applicable
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      await _clearAuthData();
    } catch (e) {
      await _clearAuthData();
      rethrow;
    }
  }

  // ── Password reset ──────────────────────────────────────────────────────────
  Future<void> requestPasswordReset(String email) async {
    await _apiService.post(
      ApiConst.passwordResetRequest,
      data: {'email': email},
    );
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    await _apiService.post(
      ApiConst.passwordResetConfirm,
      data: {
        'token': token,
        'new_password': newPassword,
        'confirm_password': newPassword,
      },
    );
  }

  // ── Token helpers ───────────────────────────────────────────────────────────
  Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTimeString = prefs.getString(_expiryTimeKey);
      if (expiryTimeString == null) return true;
      final expiryTime = DateTime.parse(expiryTimeString);
      return DateTime.now().isAfter(
        expiryTime.subtract(const Duration(minutes: 1)),
      );
    } catch (_) {
      return true;
    }
  }

  Future<void> ensureValidToken() async {
    if (await isTokenExpired()) {
      await refreshToken();
    }
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> _saveAuthData(AuthResponseModel auth) async {
    final prefs = await SharedPreferences.getInstance();
    await _apiService.saveToken(auth.accessToken);
    await prefs.setString(_refreshTokenKey, auth.refreshToken);
    // Store a 60-minute expiry (FastAPI access tokens are typically 60 min)
    await prefs.setString(
      _expiryTimeKey,
      DateTime.now().add(const Duration(minutes: 55)).toIso8601String(),
    );
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await _apiService.clearToken();
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiryTimeKey);
  }

  Future<bool> isAuthenticated() async {
    final hasToken = _apiService.isAuthenticated;
    if (!hasToken) return false;
    return !(await isTokenExpired());
  }
}
  // SharedPreferences keys
  static const String _refreshTokenKey = 'refresh_token';
  static const String _expiryTimeKey = 'expiry_time';

  // Login with email and password
  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConst.login,
        data: {'email': email, 'password': password},
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      // Save tokens and expiry time
      await _saveAuthData(authResponse);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Login with Google
  Future<AuthResponseModel> loginWithGoogle() async {
    try {
      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in aborted');
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Print Google tokens
      print('*********************************************');
      print('**        GOOGLE SIGN-IN TOKENS          **');
      print('*********************************************');
      print('Google ID Token: ${googleAuth.idToken}');
      print('---------------------------------------------');
      print('Google Access Token: ${googleAuth.accessToken}');
      print('*********************************************');

      // Print user details
      print('*********************************************');
      print('**        GOOGLE USER DETAILS            **');
      print('*********************************************');
      print('Full Name: ${googleUser.displayName}');
      print('Email: ${googleUser.email}');
      print('Profile Picture URL: ${googleUser.photoUrl}');
      print('Google User ID: ${googleUser.id}');
      print('*********************************************');

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // Sign in to Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Firebase user is null');
      }

      // Print Firebase user details
      print('*********************************************');
      print('**         FIREBASE USER DETAILS         **');
      print('*********************************************');
      print('UID: ${user.uid}');
      print('Display Name: ${user.displayName}');
      print('Email: ${user.email}');
      print('Email Verified: ${user.emailVerified}');
      print('Is Anonymous: ${user.isAnonymous}');
      print('Phone Number: ${user.phoneNumber}');
      print('Photo URL: ${user.photoURL}');
      print('Tenant ID: ${user.tenantId}');
      if (user.metadata != null) {
        print('Creation Time: ${user.metadata.creationTime}');
        print('Last Sign-In Time: ${user.metadata.lastSignInTime}');
      }
      print('Provider Data:');
      for (var info in user.providerData) {
        print('  - Provider ID: ${info.providerId}');
        print('    UID: ${info.uid}');
        print('    Display Name: ${info.displayName}');
        print('    Email: ${info.email}');
        print('    Phone Number: ${info.phoneNumber}');
        print('    Photo URL: ${info.photoURL}');
      }
      print('*********************************************');

      // Get Firebase ID token
      final String? firebaseIdToken = await user.getIdToken();
      if (firebaseIdToken == null) {
        throw Exception('Failed to get Firebase ID token');
      }

      // Print the token with design
      print('*********************************************');
      print('**          FIREBASE ID TOKEN            **');
      print('*********************************************');
      print(firebaseIdToken);
      print('*********************************************');

      // Send Google ID token to backend API
      final response = await _apiService.post(
        ApiConst.google,
        data: {'idToken': googleAuth.idToken},
      );
      final authResponse = AuthResponseModel.fromJson(response.data);
      await _saveAuthData(authResponse);
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Refresh token
  Future<AuthResponseModel> refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        throw ApiException('No refresh token found');
      }

      final response = await _apiService.post(
        ApiConst.refresh,
        data: {'refreshToken': refreshToken},
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      // Update tokens and expiry time
      await _saveAuthData(authResponse);

      return authResponse;
    } catch (e) {
      // If refresh fails, clear all auth data
      await _clearAuthData();
      rethrow;
    }
  }

  // Register new user
  Future<AuthResponseModel> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _apiService.post(
        ApiConst.register,
        data: {'email': email, 'password': password, 'name': name},
      );

      final authResponse = AuthResponseModel.fromJson(response.data);

      // Save tokens and expiry time
      await _saveAuthData(authResponse);

      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      // Call logout API (optional, depends on backend)
      try {
        await _apiService.post(ApiConst.logout);
      } catch (e) {
        // Ignore API errors during logout
      }

      // Clear all stored auth data
      await _clearAuthData();
    } catch (e) {
      // Ensure data is cleared even if there's an error
      await _clearAuthData();
      rethrow;
    }
  }

  // Check if token is expired or about to expire (within 1 minute)
  Future<bool> isTokenExpired() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryTimeString = prefs.getString(_expiryTimeKey);

      if (expiryTimeString == null) return true;

      final expiryTime = DateTime.parse(expiryTimeString);
      final now = DateTime.now();

      // Consider expired if within 1 minute of expiry (buffer time)
      return now.isAfter(expiryTime.subtract(const Duration(minutes: 1)));
    } catch (e) {
      return true;
    }
  }

  // Auto-refresh token if expired
  Future<void> ensureValidToken() async {
    final isExpired = await isTokenExpired();
    if (isExpired) {
      await refreshToken();
    }
  }

  // Get stored refresh token
  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Save all auth data to SharedPreferences
  Future<void> _saveAuthData(AuthResponseModel authResponse) async {
    final prefs = await SharedPreferences.getInstance();

    // Save access token via ApiService
    await _apiService.saveToken(authResponse.accessToken);

    // Save refresh token and expiry time
    await prefs.setString(_refreshTokenKey, authResponse.refreshToken);
    await prefs.setString(
      _expiryTimeKey,
      authResponse.expiryTime.toIso8601String(),
    );
  }

  // Clear all auth data from SharedPreferences
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear access token via ApiService
    await _apiService.clearToken();

    // Clear refresh token and expiry time
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_expiryTimeKey);
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final hasToken = _apiService.isAuthenticated;
    if (!hasToken) return false;

    // Check if token is expired
    final isExpired = await isTokenExpired();
    return !isExpired;
  }
}
