# MPSeCNet — L1 Security Assessment Remediation

**App:** MPSeCNet (`com.mpsec.mpsecnet`)  
**Report:** L1 Security Assessment Report (MobSF SAST)  
**Branch:** `chore/code-optimisation`  
**Date:** 11 September 2026  

This document lists which L1 findings were fixed in code, which remain partial, and which require process / vendor follow-up. Application workflows (PO, survey, voter search, portals) were kept intact.

---

## Summary

| Status | Count | IDs |
| --- | ---: | --- |
| Fixed | 12 | VULN-001, 002, 003, 005, 006, 008, 009, 010, 011, 012, 017, 019 |
| Partial | 2 | VULN-004, 007 |
| Open (process / vendor) | 5 | VULN-013, 014, 015, 016, 018 |
| **Total** | **19** | |

---

## Fixed findings

### VULN-001 — Cleartext network traffic (HIGH)
**Status:** Fixed  

- `android:usesCleartextTraffic="false"` in the main manifest  
- Production `network_security_config.xml` sets `cleartextTrafficPermitted="false"`  
- WebView cleartext / mixed-content allowed only on non-production builds  

### VULN-002 — Low minSdkVersion (HIGH)
**Status:** Fixed  

- `minSdk` raised to **API 29 (Android 10+)** in `android/app/build.gradle.kts`  
- Aligns with MobSF guidance for a supported OS security-update floor  

### VULN-003 — AES-CBC padding-oracle risk (HIGH)
**Status:** Fixed  

- `flutter_secure_storage` uses **AES-GCM** (`StorageCipherAlgorithm.AES_GCM_NoPadding`)  
- Key wrapping uses RSA OAEP SHA-256  
- `migrateOnAlgorithmChange: true` preserves existing secure-storage data  

### VULN-005 — Insecure / predictable RNG (MEDIUM)
**Status:** Fixed  

- Retry jitter now uses `Random.secure()` instead of `Random()`  

### VULN-006 — Weak hash SHA-1 (MEDIUM)
**Status:** Fixed (app-owned code)

- Application crypto / pinning paths use **SHA-256**  
- No SHA-1 usage remains in first-party Dart code  

### VULN-008 — Backup not disabled (MEDIUM)
**Status:** Fixed  

- `android:allowBackup="false"`  
- Restrictive `fullBackupContent` and `dataExtractionRules` exclude app data domains  
- Dependency-merged broad storage / media permissions are stripped via `tools:node="remove"`  

### VULN-009 — Exported ProfileInstallReceiver (MEDIUM)
**Status:** Fixed  

- `androidx.profileinstaller.ProfileInstallReceiver` forced to `android:exported="false"` via manifest merge  

### VULN-010 — Clipboard sensitive-data exposure (LOW)
**Status:** Fixed  

- WebView bridge copy uses a sensitive-clipboard path  
- On Android 13+, clipboard items are marked with `ClipDescription.EXTRA_IS_SENSITIVE`  
- Other platforms fall back to the standard Flutter clipboard API  

### VULN-011 — Insecure temporary files (LOW)
**Status:** Fixed (app-owned paths)

- Temp / cache files use the app-private temporary directory  
- Startup cache cleanup removes disposable WebView / temp artefacts  

### VULN-012 — Sensitive logging (LOW)
**Status:** Fixed  

- Production: `ENABLE_LOGGING=false`  
- `AppLogger` is gated by environment; verbose logs are not enabled in production  

### VULN-017 — Dangerous permissions justification (INFO)
**Status:** Fixed (documented in product behaviour)

- Location, Camera, and Notifications remain mapped to election field features  
- Permissions are requested at time of use where applicable  
- Unnecessary broad storage / media permissions are removed from the merged manifest  

### VULN-019 — Private RFC1918 IP in release artefact (INFO)
**Status:** Fixed  

- Private LAN IP (`10.115.197.192`) removed from Dart source and iOS `Info.plist`  
- Production / UAT env files use public HTTPS hosts  
- `assets/env/dev.env` (LAN endpoints) is bundled only for the **dev** Android flavor  
- Dev cleartext LAN access remains available via the `dev` network-security overlay  

---

## Partial findings

### VULN-004 — Hardcoded sensitive information (MEDIUM)
**Status:** Partial  

**Done**
- Hardcoded secret / key string literals removed from Dart source  
- Voter-search keys are required from environment configuration  

**Remaining**
- Operational keys still ship inside `assets/env/prod.env` (required for current voter-search API design)  
- Full remediation needs backend-issued / runtime-fetched secrets (no app rebuild to rotate)  

### VULN-007 — Raw SQL against SQLite (MEDIUM)
**Status:** Partial  

**Done**
- First-party local persistence uses `JsonLocalDatabase` (JSON files), not concatenated raw SQL  

**Remaining**
- Third-party libraries may still contain SQLite usage flagged by MobSF  
- SQLCipher for app JSON storage is not required with the current design  

---

## Open findings (process / vendor)

| ID | Severity | Why still open | Owner |
| --- | --- | --- | --- |
| VULN-013 | LOW | FORTIFY_SOURCE missing in vendor JNI `.so` files (CameraX / ML Kit / similar) | Dependency vendors |
| VULN-014 | INFO | APK signing certificate uses personal / placeholder DN fields | Release governance |
| VULN-015 | INFO | Anti-VM signatures need formal attribution in security design docs | Security / Dev |
| VULN-016 | INFO | APKiD “Resources Confusion” needs build-pipeline confirmation | Build / Dev |
| VULN-018 | INFO | MobSF high-entropy native-string triage (mostly binary false positives) | Security triage |

---

## Validation build

A production release APK was generated after these changes:

```text
build/app/outputs/flutter-apk/app-prod-release.apk
```

Suggested next step: re-run MobSF / L1 static analysis on this artefact and confirm HIGH findings are cleared.

---

## Change map (main files)

| Area | Files |
| --- | --- |
| Manifest / SDK | `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts` |
| Secure storage | `lib/core/storage/secure_storage_service.dart` |
| Env / secrets / hosts | `lib/config/environment_config.dart`, `assets/env/*`, `pubspec.yaml` |
| Clipboard | `lib/core/security/sensitive_clipboard.dart`, `MainActivity.kt`, `webview_bridge.dart` |
| RNG | `lib/core/sync/retry_policy.dart` |
| WebView / ATS | `webview_config.dart`, `webview_security.dart`, `web_view_screen.dart`, `ios/Runner/Info.plist` |
| Tests | `test/unit/l1_env_security_test.dart` |
