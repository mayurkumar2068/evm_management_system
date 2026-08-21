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

Native store package IDs:

| Build | Android `applicationId` | iOS bundle ID |
| --- | --- | --- |
| prod flavor | `com.mpsec.mpsecnet` | `com.mpsec.mpsecnet` |
| dev flavor | `com.mpsec.mpsecnet.dev` | `com.mpsec.mpsecnet.dev` |

The active flavor selects the `.env` loaded at bootstrap; `EnvironmentConfig` exposes it as a
typed, immutable object. There are no hardcoded URLs anywhere in the codebase.

## Local builds

```bash
# Android (debug / non-store)
flutter build apk --debug --flavor dev --dart-define=APP_FLAVOR=dev

# Google Play AAB (requires android/key.properties + upload keystore)
./scripts/build_prod_aab.sh
# equivalent:
flutter build appbundle --release --flavor prod --dart-define=APP_FLAVOR=prod
# → build/app/outputs/bundle/prodRelease/app-prod-release.aab

# App Store / TestFlight IPA (requires Xcode team signing on Mac)
./scripts/build_prod_ipa.sh
# equivalent:
flutter build ipa --release --flavor prod --dart-define=APP_FLAVOR=prod \
  --export-options-plist=ios/ExportOptions.plist
```

### Android release signing

1. Copy `android/key.properties.example` → `android/key.properties` (gitignored).
2. Create `android/upload-keystore.jks` with `keytool` (see `docs/STORE_RELEASE_CHECKLIST.md`).
3. `android/app/build.gradle.kts` loads `signingConfigs.release` from `key.properties`.
4. `assemble*Release` / `bundle*Release` **fail fast** if `key.properties` or the keystore file is missing (debug builds still work).

Never commit `key.properties`, `*.jks`, or `*.keystore`.

### iOS signing

1. In Xcode, open `ios/Runner.xcworkspace`, select the **Runner** target and **prod** scheme.
2. Enable Automatic Signing and choose your Apple Developer **Team**.
3. Copy `ios/ExportOptions.plist.example` → `ios/ExportOptions.plist` and set `teamID` (gitignored).
4. Privacy usage strings are in `ios/Runner/Info.plist` (camera, photos, location, Face ID, microphone). Android gallery uses Photo Picker — no Photos/storage permission.

Full Play / App Store console steps: **`docs/STORE_RELEASE_CHECKLIST.md`**.

## Versioning

CI sets the version from the git tag and the run number:

```bash
flutter build apk --release --flavor prod --dart-define=APP_FLAVOR=prod \
  --build-name=$TAG --build-number=$RUN_NUMBER
```

Tag releases as `vMAJOR.MINOR.PATCH` (e.g. `v1.2.0`) to trigger the `Build` workflow.
Bump `pubspec.yaml` before each store binary upload (e.g. `1.0.0+2`).

## CI/CD (GitHub Actions)

- **`ci.yml`** — on every push/PR: `dart format` check, `flutter analyze`, `flutter test --coverage`,
  and an 80% line-coverage gate.
- **`build.yml`** — on `v*` tags / manual dispatch: matrix builds of Android (APK) and iOS
  (no-codesign) for DEV/UAT/PROD, uploading artifacts.

For automated store uploads, add GitHub secrets for the Android keystore / `key.properties` values and
iOS certificates, then extend `build.yml` with `fastlane` or
`flutter build ipa --export-options-plist` plus Play / TestFlight upload steps.

## Release checklist

1. `prod.env` reviewed — correct `API_BASE_URL`, `ENABLE_SSL_PINNING=true`, valid `SSL_PIN_SHA256`,
   `ENABLE_LOGGING=false`.
2. `flutter analyze` clean, tests green, coverage ≥ 80%.
3. Native security handlers (screen security, device integrity) registered for the target.
4. App version/build bumped; release tag pushed.
5. Smoke-test the **signed** artifact on a physical device (login, PO, survey WebView, location/camera).
6. Complete store console items in `docs/STORE_RELEASE_CHECKLIST.md` (Data safety, privacy policy URL, screenshots).
