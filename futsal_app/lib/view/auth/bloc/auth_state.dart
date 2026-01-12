import 'package:equatable/equatable.dart';
import 'package:ui/view/auth/data/model/auth_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Loading state
class AuthLoading extends AuthState {
  const AuthLoading();
}

// Authenticated state (logged in)
class Authenticated extends AuthState {
  final AuthResponseModel authResponse;

  const Authenticated(this.authResponse);

  @override
  List<Object?> get props => [authResponse];
}

// Unauthenticated state (logged out)
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

// Auth error state
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// Token refreshing state
class TokenRefreshing extends AuthState {
  const TokenRefreshing();
}

// Token refreshed successfully
class TokenRefreshed extends AuthState {
  final AuthResponseModel authResponse;

  const TokenRefreshed(this.authResponse);

  @override
  List<Object?> get props => [authResponse];
}
