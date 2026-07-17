# Deployment Guide

## Flavors & entrypoint

There is a **single entrypoint** — `lib/main.dart`. The flavor is resolved by `AppConfig`:

| Flavor | Env file |
| --- | --- |
| DEV | `assets/env/dev.env` |
| UAT | `assets/env/uat.env` |
| PRODUCTION | `assets/env/prod.env` |

- For local development, change `AppConfig.defaultFlavor` in `lib/config/app_config.dart`.
- For builds/CI, pass `--dart-define=APP_FLAVOR=dev|uat|prod` to override the default at build time.

The active flavor selects the `.env` loaded at bootstrap; `EnvironmentConfig` exposes it as a
typed, immutable object. There are no hardcoded URLs anywhere in the codebase.

## Local builds

```bash
# Android
flutter build apk       --release --dart-define=APP_FLAVOR=uat
flutter build appbundle --release --dart-define=APP_FLAVOR=prod

# iOS
flutter build ipa       --release --dart-define=APP_FLAVOR=prod
```

## Versioning

CI sets the version from the git tag and the run number:

```bash
flutter build apk --release --dart-define=APP_FLAVOR=prod \
  --build-name=$TAG --build-number=$RUN_NUMBER
```

Tag releases as `vMAJOR.MINOR.PATCH` (e.g. `v1.2.0`) to trigger the `Build` workflow.

## CI/CD (GitHub Actions)

- **`ci.yml`** — on every push/PR: `dart format` check, `flutter analyze`, `flutter test --coverage`,
  and an 80% line-coverage gate.
- **`build.yml`** — on `v*` tags / manual dispatch: matrix builds of Android (APK) and iOS
  (no-codesign) for DEV/UAT/PROD, uploading artifacts.

For store releases, add signing config (Android keystore secrets / iOS provisioning profiles) and
extend `build.yml` with `fastlane` or `flutter build ipa --export-options-plist` plus an upload
step (Play Store / TestFlight).

## Release checklist

1. `prod.env` reviewed — correct `API_BASE_URL`, `ENABLE_SSL_PINNING=true`, valid `SSL_PIN_SHA256`,
   `ENABLE_LOGGING=false`.
2. `flutter analyze` clean, tests green, coverage ≥ 80%.
3. Native security handlers (screen security, device integrity) registered for the target.
4. App version/build bumped; release tag pushed.
5. Smoke-test the signed artifact on a physical device (login, dashboard, scan, offline sync).
