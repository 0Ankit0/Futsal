import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui/view/auth/bloc/auth_event.dart';
import 'package:ui/view/auth/bloc/auth_state.dart';
import 'package:ui/view/auth/data/model/auth_model.dart';
import 'package:ui/view/auth/data/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository(),
      super(const AuthInitial()) {
    // Register event handlers
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RefreshTokenRequested>(_onRefreshTokenRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<LoginWithGoogleRequested>(_onLoginWithGoogleRequested);
  }

  // Handle Google login
  Future<void> _onLoginWithGoogleRequested(
    LoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final authResponse = await _authRepository.loginWithGoogle();
      emit(Authenticated(authResponse));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Handle login
  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final authResponse = await _authRepository.login(
        email: event.email,
        password: event.password,
      );

      emit(Authenticated(authResponse));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Handle register
  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final authResponse = await _authRepository.register(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      emit(Authenticated(authResponse));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // Handle logout
  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _authRepository.logout();
      emit(const Unauthenticated());
    } catch (e) {
      // Even if logout fails, set state to unauthenticated
      emit(const Unauthenticated());
    }
  }

  // Handle token refresh
  Future<void> _onRefreshTokenRequested(
    RefreshTokenRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const TokenRefreshing());

    try {
      final authResponse = await _authRepository.refreshToken();
      emit(TokenRefreshed(authResponse));
    } catch (e) {
      // If refresh fails, user needs to login again
      emit(const Unauthenticated());
      emit(AuthError('Session expired. Please login again.'));
    }
  }

  // Check authentication status
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final isAuthenticated = await _authRepository.isAuthenticated();

      if (isAuthenticated) {
        // Check if token needs refresh
        final isExpired = await _authRepository.isTokenExpired();
        if (isExpired) {
          // Auto-refresh token
          try {
            final authResponse = await _authRepository.refreshToken();
            emit(Authenticated(authResponse));
          } catch (e) {
            // Refresh failed, user needs to login
            emit(const Unauthenticated());
          }
        } else {
          // Token is valid and loaded, user is authenticated
          // Create a minimal auth response (token already loaded in ApiService)
          emit(
            Authenticated(
              AuthResponseModel(
                tokenType: 'Bearer',
                accessToken: 'loaded',
                expiresIn: 3600,
                refreshToken: 'loaded',
              ),
            ),
          );
        }
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(const Unauthenticated());
    }
  }
}
