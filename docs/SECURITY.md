# Security Guide

Designed to pass an enterprise/government security audit. Security concerns are centralized in
`core/security`, `core/storage`, and the network interceptor stack.

## Controls

| Requirement | Implementation | Location |
| --- | --- | --- |
| Secure storage | iOS Keychain / Android Keystore | `SecureStorageService` |
| Token storage | Encrypted at rest, never in SharedPreferences | `TokenVault` |
| Token refresh | Single-flight refresh on 401, interceptor-free client | `TokenRefresher`, `AuthInterceptor` |
| Token encryption | Platform keystore-backed encryption | `SecureStorageService` |
| Biometric auth | Fingerprint / Face ID gate over stored session | `BiometricAuthenticator` |
| SSL pinning | SHA-256 public-key pin per flavor | `SslPinningService` |
| Certificate validation | Adapter-level `validateCertificate` | `SslPinningService` |
| Root / jailbreak detection | Pluggable integrity assessment | `DeviceIntegrityService` |
| Screenshot detection | `FLAG_SECURE` / iOS hooks via MethodChannel | `ScreenSecurityService` |
| Session timeout | Idle countdown → forced logout | `SessionTimeoutManager` |
| Centralized 401/403 handling | `ErrorMapper` + `SessionEventBus` | `core/error`, `core/providers` |

## Policies

- **Never** store tokens or credentials in `SharedPreferences` or the app database.
- **Never** log secrets — `LoggingInterceptor` redacts `Authorization`/`Cookie` headers and logging
  is disabled in production by `EnvironmentConfig.enableLogging`.
- Production builds enable SSL pinning and shorter session timeouts via `prod.env`.

## Wiring native detectors

`DeviceIntegrityService` and `ScreenSecurityService` ship with default implementations that are the
integration points for native code (Play Integrity / DeviceCheck, `flutter_jailbreak_detection`,
`FLAG_SECURE`). Because callers depend on the interfaces, swapping in a real detector requires no
changes outside the provider binding.

## SSL pin rotation

1. Compute the new leaf/intermediate SHA-256 public-key hash (base64).
2. Update `SSL_PIN_SHA256` in the relevant `.env`.
3. Ship with both old and new pins during the rotation window (extend `SslPinningService` to a set).

## Threat-model notes

- Compromised-device access is denied when `DeviceIntegrityReport.isCompromised` is true.
- All transport errors are mapped to safe, localized messages; raw exceptions never reach the UI.
- Deep links are guarded: unauthenticated users are redirected to `/login`, and role-restricted
  routes (e.g. Audit Trail) are guarded by `AppDestination.requiredRoles`.
