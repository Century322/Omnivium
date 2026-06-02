import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthEmailLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthEmailLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthGoogleLoginRequested extends AuthEvent {
  const AuthGoogleLoginRequested();
}

class AuthAppleLoginRequested extends AuthEvent {
  const AuthAppleLoginRequested();
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

class AuthSessionRestoreRequested extends AuthEvent {
  const AuthSessionRestoreRequested();
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}
