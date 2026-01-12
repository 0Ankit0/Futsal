import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Login event
class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

// Google login event
class LoginWithGoogleRequested extends AuthEvent {
  const LoginWithGoogleRequested();
}

// Register event
class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const RegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
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
