# State Management Guide

**Riverpod only.** Provider, GetX, Bloc and business logic in `setState` are not used.

## Provider types

| Use | Type |
| --- | --- |
| Stateless DI (services, repos, use cases) | `Provider` |
| Mutable UI state with explicit commands | `Notifier` (e.g. `AuthController`) |
| Async-loaded state with loading/error | `AsyncNotifier` (e.g. `DashboardController`) |
| One-shot async value | `FutureProvider` (e.g. `biometricEnabledProvider`) |
| Reactive streams | `StreamProvider` (e.g. `pendingSyncCountProvider`, connectivity) |

## Patterns

- **Constructor-free notifiers.** `Notifier`/`AsyncNotifier` resolve dependencies through `ref`
  (e.g. `ref.read(loginUseCaseProvider)`), so providers stay the single composition point.
- **Immutable state.** UI state classes are immutable; controllers replace `state` wholesale.
- **No logic in widgets.** Widgets `watch` state and call controller methods only.
- **Result mapping.** Controllers `fold` a `Result` into UI state; `AsyncNotifier`s throw the
  `Failure` so it surfaces as `AsyncError` for `AppErrorState`.

## Example — command controller

```dart
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState.unknown();

  Future<void> signIn(LoginCredentials c) async {
    state = const AuthState.authenticating();
    final result = await ref.read(loginUseCaseProvider)(c);
    state = result.fold(
      onSuccess: AuthState.authenticated,
      onFailure: (f) => AuthState.unauthenticated(failure: f),
    );
  }
}
```

## Example — async controller

```dart
class DashboardController extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load(forceRefresh: true));
  }
}
```

## Riverpod code generation (optional)

Providers are hand-written so the project compiles with **no `build_runner` step**. When the
toolchain is on Dart ≥ 3.9, `riverpod_generator` + `@riverpod` can be reintroduced without
changing consumers, since everything is already provider-based.
