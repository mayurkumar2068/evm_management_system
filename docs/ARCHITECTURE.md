# Architecture

The app follows **Clean Architecture** organized **feature-first**. Dependencies point inward:
`presentation → domain ← data`. The domain layer has no Flutter or package dependencies beyond
the `Result`/`Failure` primitives.

```
┌──────────────────────────────────────────────────────────────┐
│                        Presentation                           │
│  Screens / Widgets · Riverpod Controllers (Notifier/Async)    │
│  States · Providers (DI)                                      │
└───────────────▲───────────────────────────┬──────────────────┘
                │ calls                       │ watches state
                │                             ▼
┌───────────────┴──────────────────────────────────────────────┐
│                          Domain                               │
│  Entities · Repository interfaces · Use Cases                 │
│  (pure Dart, returns Result<T>, never throws)                 │
└───────────────▲───────────────────────────────────────────────┘
                │ implements
┌───────────────┴──────────────────────────────────────────────┐
│                           Data                                │
│  Models (DTO) · Mappers · Remote/Local DataSources            │
│  RepositoryImpl (maps exceptions → Failure via ErrorMapper)   │
└───────────────▲───────────────────────────────────────────────┘
                │ uses
┌───────────────┴──────────────────────────────────────────────┐
│                           Core                                │
│  network · storage · security · database · sync · error       │
│  logging · analytics · notifications · providers (DI)         │
└───────────────────────────────────────────────────────────────┘
```

## Layer responsibilities

- **Presentation** — Riverpod controllers orchestrate use cases and expose immutable state
  (`AuthState`, `AsyncValue<DashboardSummary>`). No business logic, no direct API/DB access.
- **Domain** — `Entities`, `Repository` interfaces, and single-responsibility `UseCase`s. Returns
  `Result<T>`; depends on abstractions only (Dependency Inversion).
- **Data** — `Model` DTOs + `Mapper`s, `RemoteDataSource` (Dio) and `LocalDataSource`
  (secure storage / `LocalDatabase`), and `RepositoryImpl` which converts any thrown
  `AppException`/`DioException` into a `Failure` through `ErrorMapper`.
- **Core** — cross-cutting infrastructure shared by all features. Core never imports a feature;
  feature-specific reactions (e.g. session expiry) are delivered via the `SessionEventBus`.

## Dependency injection

All wiring is via Riverpod providers. The composition root is `bootstrap()`, which overrides
`environmentConfigProvider` and `localDatabaseProvider` with initialized instances. Feature
providers (`auth_providers.dart`, `dashboard_providers.dart`) compose datasources → repository →
use cases → controller.

## Offline-first flow

`save local → mark pending → background sync → server success → update local`

`SyncManager` watches connectivity and a periodic timer, drains the durable `SyncQueue`, applies
`RetryPolicy` backoff for transient errors, and reconciles 409s through `ConflictResolver`.

## Scaling to 100+ screens / web admin

- Each feature is self-contained and addable without touching others.
- Navigation is data-driven (`AppDestinations`) — adding a module is a list entry + a route.
- The `LocalDatabase`/`AnalyticsService`/`NotificationService`/`DeviceIntegrityService`
  abstractions let implementations (Isar, Firebase, native detectors) be swapped without
  refactoring callers, and the same domain/data layers can back a future Flutter Web admin.
