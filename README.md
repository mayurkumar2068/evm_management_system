# EVM Management System

A production-grade Flutter application for the **Election Commission of India** to manage
Electronic Voting Machines (EVMs) — Control Units, Ballot Units, stock registers, QR/barcode
scanning, audit trails, reporting, notifications, offline synchronization and inventory.

Built to be maintained for 10+ years and scaled nationwide: Clean Architecture, Feature-First
modularization, SOLID/DRY/KISS, offline-first, and an enterprise security posture.

---

## Highlights

| Concern | Implementation |
| --- | --- |
| Architecture | Clean Architecture + Feature-First (`data` / `domain` / `presentation`) |
| State management | **Riverpod only** (`Notifier`, `AsyncNotifier`, `FutureProvider`, `StreamProvider`) |
| Routing | GoRouter with auth + role guards, nested (shell) navigation, deep-link ready |
| Network | Dio + interceptor stack (auth, retry, logging, connectivity, network, SSL pinning) |
| Config | `.env` per flavor (DEV/UAT/PROD) via `flutter_dotenv`, no hardcoded URLs |
| Local DB | `LocalDatabase` abstraction (JSON adapter default, Isar adapter drop-in) |
| Offline-first | Durable `SyncQueue` + `SyncManager` + `RetryPolicy` + `ConflictResolver` |
| Security | Secure storage, token vault + refresh, biometrics, SSL pinning, device-integrity & screen-security hooks, session timeout |
| Errors | `Result` pattern + sealed `Failure`/`AppException`, centralized `ErrorMapper` (no nulls thrown to UI) |
| Localization | `easy_localization` (English + Hindi), type-safe `LocaleKeys`, zero hardcoded strings |
| Design system | Tokens (colors/typography/spacing/radius/icons) + reusable widgets |
| Logging | `AppLogger` (environment-based, no `print`) |
| Analytics / Push | `AnalyticsService` / `NotificationService` abstractions (Firebase-ready) |
| Testing | Unit + widget + integration, 80%+ target enforced in CI |
| CI/CD | GitHub Actions: analyze/test + Android & iOS DEV/UAT/PROD builds |

## Getting started

```bash
flutter pub get

# Single entrypoint — flavor resolved by AppConfig.
# DEV is the default; override at build/run time with --dart-define.
flutter run
flutter run --dart-define=APP_FLAVOR=uat
flutter run --dart-define=APP_FLAVOR=prod
```

> The flavor is selected in one place: `AppConfig.defaultFlavor` (`lib/config/app_config.dart`) for
> local development, or `--dart-define=APP_FLAVOR=...` for builds/CI. Point the flavor `.env`
> `API_BASE_URL` at a real server to use live data.

## Quality gates

```bash
flutter analyze            # 0 issues
flutter test               # unit + widget
flutter test integration_test
flutter test --coverage    # coverage report
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Folder Structure](docs/FOLDER_STRUCTURE.md)
- [API Integration Guide](docs/API_INTEGRATION.md)
- [State Management Guide](docs/STATE_MANAGEMENT.md)
- [Coding Standards](docs/CODING_STANDARDS.md)
- [Security Guide](docs/SECURITY.md)
- [Deployment Guide](docs/DEPLOYMENT.md)

## Sample modules

`Auth` and `Dashboard` are implemented end-to-end across all three layers and serve as the
reference template for the remaining feature modules (Scanner is also wired with a reusable
scanner widget; Settings demonstrates runtime locale switching; Sync Management shows the live
queue depth). All other modules are scaffolded with the full folder structure ready for
implementation.
