import 'dart:async';

import 'package:evm_management_system/app/routes/auth_navigation_guard.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/config/app_config.dart';
import 'package:evm_management_system/config/flavor.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/usecase/usecase.dart';
import 'package:evm_management_system/core/webview/service/webview_cookie_service.dart';
import 'package:evm_management_system/features/auth/di/auth_module.dart';
import 'package:evm_management_system/features/auth/domain/entities/auth_user.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';
import 'package:evm_management_system/features/auth/domain/entities/user_role.dart';
import 'package:evm_management_system/features/auth/presentation/states/auth_state.dart';
import 'package:get/get.dart' hide Trans;

/// GetX controller that owns authentication state and exposes the only
/// methods the UI may call. Business logic lives in use cases.
class AuthController extends GetxController {
  final Rx<AuthState> authState = AuthState.unknown().obs;
  final Rxn<bool> biometricEnabled = Rxn<bool>();

  @override
  void onInit() {
    super.onInit();
    ever<AuthState>(authState, (_) => AuthNavigationGuard.apply());
    unawaited(_loadBiometricFlag());
  }

  Future<void> _loadBiometricFlag() async {
    try {
      biometricEnabled.value = await AuthModule.repository.isBiometricEnabled();
    } catch (_) {
      biometricEnabled.value = false;
    }
  }

  /// Restores any persisted session on app start.
  Future<void> restoreSession() async {
    final bool valid = await AuthModule.repository.hasValidSession();
    if (valid) {
      final result = await AuthModule.getCurrentUser(const NoParams());
      final AuthState restored = result.fold(
        onSuccess: AuthState.authenticated,
        onFailure: (_) => const AuthState.unauthenticated(),
      );
      if (restored.isAuthenticated) {
        authState.value = restored;
        return;
      }
    }

    if (AppServices.onboarding.seen) {
      await continueAsGuest();
    } else {
      authState.value = const AuthState.unauthenticated();
    }
  }

  static const AuthUser _guestUser = AuthUser(
    id: 'guest-mp-001',
    officerId: 'MP-OBS-2026-0001',
    fullName: 'राजेश शर्मा',
    role: UserRole.districtOfficer,
    designation: 'जिला पर्यवेक्षक',
    stateCode: 'MP',
    districtCode: 'MP-BHOPAL',
  );

  /// Enters the app without a login by establishing a local guest session.
  Future<void> continueAsGuest() async {
    await AuthModule.repository.establishLocalSession(_guestUser);
    authState.value = const AuthState.authenticated(_guestUser);
  }

  static const String _devOfficerId = 'admin';
  static const String _devPassword = 'admin123';
  static const AuthUser _devUser = AuthUser(
    id: 'dev-0147',
    officerId: 'ECI-DEL-2024-0147',
    fullName: 'Raj Kumar',
    role: UserRole.districtOfficer,
    designation: 'Election Officer • Grade A',
    stateCode: 'DL',
    districtCode: 'DL-CENTRAL',
  );

  Future<void> signIn(LoginCredentials credentials) async {
    authState.value = const AuthState.authenticating();

    final int? electionId =
        credentials.electionId ?? AppServices.config.electionId;
    final LoginCredentials resolved = LoginCredentials(
      officerId: credentials.officerId,
      password: credentials.password,
      electionId: electionId,
    );

    if (AppConfig.environment == Flavor.dev &&
        resolved.officerId.trim() == _devOfficerId &&
        resolved.password == _devPassword) {
      await AuthModule.repository.establishLocalSession(_devUser);
      authState.value = const AuthState.authenticated(_devUser);
      return;
    }

    final result = await AuthModule.login(resolved);
    authState.value = result.fold(
      onSuccess: AuthState.authenticated,
      onFailure: (failure) => AuthState.unauthenticated(failure: failure),
    );
  }

  Future<void> signInWithBiometrics() async {
    authState.value = const AuthState.authenticating();
    final result = await AuthModule.biometricLogin(const NoParams());
    authState.value = result.fold(
      onSuccess: AuthState.authenticated,
      onFailure: (failure) => AuthState.unauthenticated(failure: failure),
    );
  }

  Future<void> signOut() async {
    // Survey / PO officer session (shared secure storage + token vault).
    await AppServices.serviceAuth.signOut();
    try {
      await Get.find<WebViewCookieService>().clearSessionCookiesFor(
        AppServices.config,
      );
    } catch (_) {
      // WebView cookie manager may be unavailable during teardown.
    }
    await AuthModule.logout(const NoParams());
    authState.value = const AuthState.unauthenticated();
    AuthNavigationGuard.apply();
    if (Get.currentRoute != AppRoute.login.path) {
      await Get.offAllNamed<dynamic>(AppRoute.login.path);
    }
  }

  /// Invoked when the session is invalidated externally (e.g. 401 / timeout).
  void onSessionExpired() =>
      authState.value = const AuthState.unauthenticated();
}
