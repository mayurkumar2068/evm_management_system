# Folder Structure

```
lib/
├── app/                     # App widget, router, shell, DI provider for router
│   ├── router/              # AppRouter, RouteNames, RoutePaths, guards, shell, destinations
│   ├── app.dart             # EvmApp (MaterialApp.router + theme + localization)
│   ├── app_providers.dart   # routerProvider
│   └── app_splash_screen.dart
├── bootstrap/
│   └── bootstrap.dart       # Composition root: env load, DI overrides, runApp
├── config/
│   ├── flavor.dart          # DEV / UAT / PRODUCTION
│   └── environment_config.dart
├── core/
│   ├── analytics/           # AnalyticsService abstraction (+ logging impl)
│   ├── database/            # LocalDatabase interface + JSON adapter
│   ├── error/               # AppException, Failure, Result, ErrorMapper
│   ├── logging/             # AppLogger
│   ├── network/             # ApiClient, ApiEndpoints, interceptors/, TokenRefresher
│   ├── notifications/       # NotificationService abstraction
│   ├── providers/           # core_providers (DI), SessionEventBus
│   ├── security/            # TokenVault, biometrics, SSL pinning, device integrity, screen security, session timeout
│   ├── storage/             # SecureStorageService
│   ├── sync/                # SyncQueue, SyncService, SyncManager, RetryPolicy, ConflictResolver
│   ├── usecase/             # UseCase base contracts
│   └── utils/               # Validators, AppLocaleHolder
├── localization/
│   └── locale_keys.dart     # Type-safe i18n keys
├── shared/
│   ├── design_system/       # tokens/, theme/, widgets/, design_system.dart (barrel)
│   └── widgets/             # App-wide composite widgets (nav drawer, module placeholder)
├── features/
│   └── <feature>/
│       ├── data/
│       │   ├── datasource/      # remote + local data sources
│       │   ├── models/          # DTOs
│       │   ├── repository_impl/ # Repository implementation
│       │   └── mapper/          # DTO ↔ entity
│       ├── domain/
│       │   ├── entities/
│       │   ├── repository/      # interfaces
│       │   └── usecases/
│       └── presentation/
│           ├── screens/
│           ├── widgets/
│           ├── controllers/     # Riverpod Notifier / AsyncNotifier
│           ├── providers/       # feature DI
│           └── states/          # immutable UI state
└── main.dart                # single entrypoint; flavor via AppConfig / --dart-define

assets/
├── env/                     # dev.env / uat.env / prod.env
├── translations/            # en.json / hi.json
└── certs/                   # SSL pinning certificates

test/ · integration_test/ · .github/workflows/ · docs/
```

## Feature modules

`auth`, `dashboard`, `master_stock_register`, `control_unit`, `ballot_unit`, `scanner`,
`reports`, `notifications`, `profile`, `settings`, `audit_trail`, `sync_management`, `search`,
`help_support`, `about` — each with the full `data/domain/presentation` tree.
