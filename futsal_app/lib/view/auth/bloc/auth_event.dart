import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Login event — FastAPI accepts username (which may also be an email)
class LoginRequested extends AuthEvent {
  final String username; // can be email or username
  final String password;

  const LoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

// Google login event
class LoginWithGoogleRequested extends AuthEvent {
  const LoginWithGoogleRequested();
}

// Register event
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String? firstName;
  final String? lastName;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.username,
    this.firstName,
    this.lastName,
  });

  @override
  List<Object?> get props => [email, password, username, firstName, lastName];
}

// Logout event
class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

// Refresh token event
class RefreshTokenRequested extends AuthEvent {
  const RefreshTokenRequested();
}

// Check auth status event
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}
