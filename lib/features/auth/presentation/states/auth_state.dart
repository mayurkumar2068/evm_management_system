import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';

enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

/// Immutable UI state for the authentication flow.
class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user, this.failure});

  const AuthState.unknown() : this();
  const AuthState.authenticating() : this(status: AuthStatus.authenticating);
  const AuthState.authenticated(AuthUser user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated({Failure? failure})
    : this(status: AuthStatus.unauthenticated, failure: failure);

  final AuthStatus status;
  final AuthUser? user;
  final Failure? failure;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isBusy => status == AuthStatus.authenticating;
}
