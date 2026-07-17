# API Integration Guide

## Principles

- **No API call from the UI.** Widgets call controllers → use cases → repositories → data sources.
- **No hardcoded URLs.** The base URL comes from the flavor `.env`; only relative paths live in
  `ApiEndpoints`.
- **Centralized error handling.** Data sources throw; `RepositoryImpl` converts everything to a
  `Failure` via `ErrorMapper`. The UI only ever sees `Result<T>`.

## Network stack

`ApiClient` wraps a single configured `Dio`. Interceptors run in order:

1. `ConnectivityInterceptor` — fail fast when offline.
2. `NetworkInterceptor` — `Accept`, `Content-Type`, `Accept-Language`, `X-Request-Id`.
3. `AuthInterceptor` — attaches the bearer token; on 401, refreshes once via `TokenRefresher`
   and replays the request; otherwise emits `SessionEvent.expired`.
4. `RetryInterceptor` — exponential backoff for idempotent transient failures (timeouts, 502/3/4).
5. `LoggingInterceptor` — redacted request/response logging (DEV/UAT only).

SSL pinning is applied at the adapter level by `SslPinningService` when enabled for the flavor.

## Status code handling (`ErrorMapper`)

| HTTP | Failure |
| --- | --- |
| 401 | `UnauthorizedFailure` |
| 403 | `ForbiddenFailure` |
| 404 | `NotFoundFailure` |
| 422 | `ValidationFailure` (with per-field errors) |
| 5xx | `ApiFailure` |
| timeout / connection | `NetworkFailure` |

## Adding an endpoint

1. Add the relative path to `ApiEndpoints`.
2. Add a method to the feature's `RemoteDataSource` interface + Dio implementation.
3. Map the DTO to a domain entity in the `mapper`.
4. Call it from `RepositoryImpl`, wrapping the result in `Result` and catching with `ErrorMapper`.
5. Expose a `UseCase`; consume it from a Riverpod controller.

## Example

```dart
final Response<Map<String, dynamic>> res =
    await _apiClient.get<Map<String, dynamic>>(ApiEndpoints.dashboardSummary);
return DashboardSummaryModel.fromJson(res.data ?? <String, dynamic>{});
```

## Offline writes

Mutations are submitted through `SyncManager.submit(task, collection: ...)`, which persists
locally first and queues a `SyncTask`. The manager pushes it to the server when connectivity
returns; conflicts (409) are reconciled by `ConflictResolver`.
