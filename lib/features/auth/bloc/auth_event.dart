part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthCheckStatus extends AuthEvent {}

class AuthSignOut extends AuthEvent {}

class AuthLoginWithEmail extends AuthEvent {
  final String email;
  final String password;

  AuthLoginWithEmail({required this.email, required this.password});
}

class AuthSignUpWithEmail extends AuthEvent {
  final String name;
  final String email;
  final String password;

  AuthSignUpWithEmail({
    required this.name,
    required this.email,
    required this.password,
  });
}
