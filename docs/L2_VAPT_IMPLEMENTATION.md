# MPSeCNet — L2 VAPT Security Audit Implementation Plan

**App:** MPSeCNet (`com.mpsec.mpsecnet`), APK `MPSECNETapp-prod-release.apk` v1.0.0 (Build 5)
**Source report:** `20260916-181733__MPSeCNet_L2_VAPT_Security_Audit_Report.pdf` (Level 2 VAPT, 19 findings)
**Related:** [`docs/L1_SECURITY_REMEDIATION.md`](./L1_SECURITY_REMEDIATION.md) — the earlier L1/MobSF pass. F-01 and F-06 here are the same root cause as **VULN-004** in that report, which was already logged as *Partial* pending backend work — this L2 pentest confirms it's still exploitable.
**Date:** 17 September 2026
**Status:** Partially implemented — see "Implementation status" below. Each finding is verified against the current repo state.

---

## Implementation status (17 Sep 2026)

Applied to this working tree (`dart analyze` clean on all edited files, `xmllint` clean on the manifest):

| Finding | Change | File(s) |
| --- | --- | --- |
| F-12 | Stripped deprecated `USE_FINGERPRINT` via `tools:node="remove"` | `android/app/src/main/AndroidManifest.xml` |
| F-17 | Added a `kReleaseMode` backstop to `AppLogger`'s filter — warnings/errors only in any `--release` build, regardless of `ENABLE_LOGGING` | `lib/core/logging/app_logger.dart` |
| F-15 | Validate lat/lng range + sanitize free-text before building any `geo:`/`google.navigation:`/Maps URI | `lib/core/navigation/map_navigation_service.dart` |
| F-04 / F-05 | Added an extension allowlist to the native image picker (defense-in-depth; doesn't touch the WebView gap, see F-09 below) | `lib/core/media/app_image_picker_service.dart` |
| F-16 | Added a domain-suffix (`*.mp.gov.in`, `*.eci.gov.in`) navigation allowlist enforced on initial load, `shouldOverrideUrlLoading`, and popup/new-window creation | `lib/core/webview/service/webview_trusted_hosts.dart` (new), `lib/core/webview/service/webview_dev_host.dart` (new, extracted from `webview_security.dart`), `lib/core/webview/widget/app_webview.dart` |

**F-09 — still blocked, not implemented.** The original plan (and the report) assumed `flutter_inappwebview` exposes a Dart-level `onShowFileChooser` callback to override. It doesn't — checked directly in the installed package (`flutter_inappwebview 6.1.5` / `flutter_inappwebview_android 1.1.3`): `InAppWebViewChromeClient.java`'s `onShowFileChooser` is native-only, always launches the OS picker with whatever `accept` types the loaded page requests, and has **no corresponding Dart hook** in this plugin version. The F-16 fix above narrows exposure (the file chooser can now only ever fire on a page the WebView was allowed to load, i.e. a `*.mp.gov.in`/`*.eci.gov.in` page), but it is not a per-request MIME/extension filter *within* a trusted page — that still needs a `flutter_inappwebview` version bump or a native fork, neither of which is a safe drive-by change.

**⚠️ Behavior change to be aware of:** the F-16 allowlist means the UAT survey WebView, which today points at `SURVEY_WEB_BASE_URL=https://mayurkumar2068.github.io/...` (F-11), **will now be blocked from loading** in UAT builds — that host isn't on `*.mp.gov.in`/`*.eci.gov.in`. This is the intended effect (that host was never a legitimate destination), but it means the UAT survey feature won't work again until F-11 is remediated (`SURVEY_WEB_BASE_URL` moved to an official domain). Prod and dev are unaffected — their `SURVEY_WEB_BASE_URL` already points at `mplocalelection.mp.gov.in`.

| Status | Count | IDs |
| --- | ---: | --- |
| Implemented above | 5 | F-04/F-05, F-12, F-15, F-16, F-17 |
| Blocked — plugin has no Dart hook for per-request MIME filtering | 1 | F-09 |
| Needs config/secret value (no code change) | 3 | F-02, F-03, F-11 |
| Architectural — needs backend work | 2 | F-01, F-06 |
| Accept with hardening note | 2 | F-07, F-08 |
| Already correct — no action | 4 | F-13, F-14, F-18, F-19 |
| Not confirmed in this codebase — flag to auditor | 1 | F-10 |
| **Total** | **19** | |

(F-04 and F-05 are counted together — same finding, two report entries.)

---

## Critical

### F-01 — Hardcoded AES key & passkey (`VOTER_SEARCH_AES_KEY`, `VOTER_SEARCH_PASS_KEY`)
**Status:** Architectural — needs backend work. Same root cause as L1 `VULN-004` (already logged Partial there).

**Current state:** `assets/env/{prod,dev,uat}.env` all contain the identical literal secrets, bundled as Flutter assets in every flavor's APK. Consumed by `EnvironmentConfig.load()` (`lib/config/environment_config.dart`) and used directly as the AES-GCM key in `lib/features/voter_search/data/voter_search_crypto.dart` — no derivation, no Keystore wrapping, no runtime fetch.

**Plan:**
1. **Immediate (ops, not code):** rotate `VOTER_SEARCH_AES_KEY` and `VOTER_SEARCH_PASS_KEY` server-side now that they're known-disclosed.
2. **Short term:** stop shipping the same key in prod and UAT — separate per-environment secrets at minimum, so a UAT compromise doesn't decrypt prod data.
3. **Real fix (backend-dependent, tracked, not startable from this repo alone):** serve the Voter Search key from an authenticated bootstrap endpoint after login, cached only in memory / Android Keystore-backed secure storage — never bundled in `.env`. Requires a backend change to issue session-scoped keys; app-side `VoterSearchCrypto` already isolates the key behind one constructor argument, so swapping the source is a small, contained change once the endpoint exists.
4. Add `gitleaks`/`trufflehog` to CI to catch any future re-introduction of literal secrets.

---

### F-02 — SSL pinning disabled in production
**Status:** Config-only fix — no code change needed.

**Current state:** `SslPinningService` (`lib/core/security/ssl_pinning_service.dart`) and the WebView TLS path (`lib/core/webview/service/webview_security.dart`) are both implemented correctly — they short-circuit to "trust everything" **only** when `ENABLE_SSL_PINNING=false` or `SSL_PIN_SHA256` is empty. `assets/env/prod.env` currently sets `ENABLE_SSL_PINNING=false` and `SSL_PIN_SHA256=`.

**Plan:**
1. Compute the real SPKI pin for the production host:
   ```
   openssl s_client -connect mplocalelection.mp.gov.in:443 | openssl x509 -pubkey -noout \
     | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64
   ```
2. Set `ENABLE_SSL_PINNING=true` and `SSL_PIN_SHA256=<computed hash>` in `assets/env/prod.env`.
3. Add a second (backup) pin ahead of the next cert rotation so a renewal doesn't hard-lock the app — `SslPinningService` currently only checks one pin; extend it to accept a comma-separated pin set before this ships.
4. Add a CI/release gate that fails the build if `ENABLE_SSL_PINNING=false` or `SSL_PIN_SHA256` is empty/placeholder in any non-dev flavor's `.env` (covers F-02 and F-03 together).

---

### F-03 — UAT SSL pin is a placeholder (`AAAA...` / 32 zero bytes)
**Status:** Config-only fix — no code change needed.

**Current state:** `assets/env/uat.env` has `ENABLE_SSL_PINNING=true` with `SSL_PIN_SHA256=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=`. Because pinning is *enabled* but the pin can never match, this either silently breaks UAT TLS or (if there's any fallback path) silently disables pinning — either way UAT never actually testing what it claims to test.

**Plan:** same as F-02 step 1–2, targeted at the UAT host (`uat-api.evm.eci.gov.in`), plus the same CI gate from F-02 step 4 (reject placeholder/all-zero pins, not just empty ones).

---

## High

### F-04 / F-05 — Unrestricted file upload / no extension allowlist
**Status:** Fixed (native picker path only) — real gap is the WebView, see **F-09** below, which is **blocked**, not fixed.

**Current state:** There is no generic `FilePicker` anywhere in `lib/` — the only native upload path is `AppImagePickerService` (`lib/core/media/app_image_picker_service.dart`), which wraps `image_picker` and is scoped to the OS camera/gallery UI (images only). This path was low-risk to begin with because the OS picker itself only surfaces images.

The actual unrestricted-upload vector is the WebView's native file chooser triggered by hosted web content — see **F-09**, which remains open.

**Done:** `AppImagePickerService.pickCompressedImage()` now rejects any picked file whose extension isn't in an explicit allowlist (`jpg`, `jpeg`, `png`, `webp`, `heic`, `heif`) before it leaves the service.

**Still needed:** all real validation (content-type, magic bytes, size cap) must happen server-side regardless — that's outside this repo. F-09 (WebView file chooser) is unresolved.

---

### F-06 — Production & UAT API endpoint topology exposed in APK assets
**Status:** Architectural — same fix family as F-01.

**Current state:** `assets/env/prod.env` and `assets/env/uat.env` list every backend hostname in cleartext (`API_BASE_URL`, `PO_ELECTION_API_BASE_URL`, `OLIN_API_BASE_URL`, `VOTER_SEARCH_*`, `EMS_URL`, `CANDIDATE_EXPENDITURE_URL`, etc.), bundled unconditionally (not flavor-gated) in every build.

**Plan:** Hostnames alone are lower severity than F-01 (they're not secrets, and a determined attacker can often enumerate `*.mp.gov.in`/`*.eci.gov.in` subdomains anyway), but combined with F-01's hardcoded key they hand over a working, authenticated attack surface. Track under the same bootstrap-config-endpoint effort as F-01 rather than as a separate workstream — fetch endpoint URLs dynamically post-auth instead of bundling the full topology client-side. No standalone app-side action until that backend work lands.

---

### F-07 — MainActivity exported without permission restriction
**Status:** Accept with hardening note — `exported="true"` is mandatory here (Android requires it for any `LAUNCHER`/`MAIN` activity on API 31+), so it can't simply be flipped.

**Current state:** `android/app/src/main/AndroidManifest.xml` — `MainActivity` has only the standard `MAIN`/`LAUNCHER` intent filter, no custom deep-link `VIEW` filters, and no code path in `lib/` was found parsing incoming `Intent` extras. So the theoretical PoC in the report (a malicious app sending a crafted Intent) has nothing to land on today.

**Plan:**
1. Add a code comment in `MainActivity.kt` / the manifest documenting that no Intent extras are trusted, so this stays true as the codebase evolves.
2. If any future feature reads `Intent.getData()`/`getExtras()` in `MainActivity`, it must validate/sanitize before use — flag this as a review checklist item, not a build blocker today.

---

### F-08 — WebView `allowFileAccess` / `allowContentAccess` enabled
**Status:** Design trade-off — required for the existing FileProvider-backed camera/upload flow; mitigated by fixing F-09/F-16.

**Current state:** `lib/core/webview/widget/app_webview.dart` — `allowFileAccess: true`, `allowContentAccess: true`. The two genuinely dangerous flags (`allowFileAccessFromFileURLs`, `allowUniversalAccessFromFileURLs`) are **already correctly set to `false`**. `allowFileAccess`/`allowContentAccess` remain on because the survey WebView's photo-capture flow depends on the native file chooser reaching `file://`/`content://` URIs via the app's `FileProvider`.

**Plan:** No change to these two flags — disabling them would break the existing survey photo-upload feature. Risk is bounded once F-09/F-16 restrict *which* origins are allowed to trigger the file chooser at all.

---

### F-09 — `onShowFileChooser` not overridden (no MIME restriction)
**Status:** Partially mitigated via F-16 (navigation allowlist); the per-request MIME filter itself remains blocked. Confirmed by reading the installed package source, not assumed.

**Current state:** `grep -rn "onShowFileChooser" lib/ android/` returns nothing in this repo. Checked the installed `flutter_inappwebview` package directly (`flutter_inappwebview-6.1.5`, `flutter_inappwebview_android-1.1.3`): `onShowFileChooser` **is not exposed anywhere in the Dart API surface at all** — `grep -rl "FileChooser" ~/.pub-cache/hosted/pub.dev/flutter_inappwebview*` matches exactly one file, `InAppWebViewChromeClient.java`, entirely native-side:
```java
// InAppWebViewChromeClient.java:836
public boolean onShowFileChooser(WebView webView, ValueCallback<Uri[]> filePathCallback, FileChooserParams fileChooserParams) {
    String[] acceptTypes = fileChooserParams.getAcceptTypes();
    boolean allowMultiple = fileChooserParams.getMode() == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE;
    boolean captureEnabled = fileChooserParams.isCaptureEnabled();
    return startPickerIntent(filePathCallback, acceptTypes, allowMultiple, captureEnabled);
}
```
This always launches the native OS file/camera picker using whatever `accept` types the **loaded web page** requests — there is no `onShowFileChooser`/`androidOnShowFileChooser` hook on the Dart `InAppWebView` widget in this version to intercept or restrict it. This is the actual reason the original remediation plan (an `onShowFileChooser: (controller, params) async {...}` override) doesn't compile against the installed version — it's not a real API here.

**Done (via F-16):** the WebView can now only ever load `*.mp.gov.in`/`*.eci.gov.in` pages in the first place (`WebViewTrustedHosts`, enforced at initial load, `shouldOverrideUrlLoading`, and popup/new-window creation) — so the native file chooser can now only ever be triggered by a page on that allowlist, not by an arbitrary untrusted origin. This substantially narrows F-09's exposure without touching the plugin.

**Still open:** there is no per-request MIME/extension filter *within* an allowlisted page — if a trusted government page itself has `<input type="file" accept="*/*">`, the native picker still offers any file type. Closing that needs one of:
1. **Upgrade `flutter_inappwebview`** to a version that exposes an `onShowFileChooser` Dart hook (needs checking whether any release does; a plugin major-version bump is a larger, separately-tested change).
2. **Fork/patch the plugin's native `ChromeClient`** to add MIME filtering natively — heavier, harder to maintain across plugin updates.

---

### F-10 — Google Tink `ignoreTypeHeader` JWT bypass flag
**Status:** Not confirmed in this codebase — flag back to the auditor.

**Current state:** No `Tink`, `ignoreTypeHeader`, `expectedTypeHeader`, or `JwtValidator` reference exists anywhere in `lib/`, `android/`, `pubspec.yaml`, or `pubspec.lock`. The app's only JWT-touching code is `lib/core/security/jwt_utils.dart`, a non-verifying payload decoder used solely to pull a session ID for header injection — there's no signature validation client-side to have a Tink `ignoreTypeHeader` flag on.

**Plan:**
1. Reply to the auditor asking which artifact/class path in the scanned APK surfaced this string — it may be a transitive native dependency (Firebase, Play Services, etc.) not visible from Dart source.
2. If needed, confirm via `cd android && ./gradlew :app:dependencies` whether any transitive dependency pulls in `com.google.crypto.tink`.
3. No app-side action until the source library is identified.

---

### F-11 — UAT survey webapp hosted on personal GitHub Pages
**Status:** Config value — needs an official domain, not a code change. Defense-in-depth via F-16.

**Current state:** `assets/env/uat.env` — `SURVEY_WEB_BASE_URL=https://mayurkumar2068.github.io/evm_management_system/location/`.

**Plan:**
1. Move the survey web app to official infrastructure (`*.mp.gov.in` or `*.eci.gov.in`) and update `SURVEY_WEB_BASE_URL` accordingly — needs hosting decided by the infra/ECI side, not something this repo can self-serve.
2. Until that lands, the F-16 domain allowlist limits blast radius: even if this URL is later modified maliciously, the WebView will refuse to hand it the native file chooser unless it's on the allowlist.

---

## Medium

### F-12 — Sensitive permissions incl. deprecated `USE_FINGERPRINT`
**Status:** Fixed (the rest of the flagged permissions are legitimate, no change needed).

**Current state (before fix):** `CAMERA`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` are declared directly and are genuinely used (barcode scan, survey photo capture, location-tagged surveys). `USE_BIOMETRIC`/`USE_FINGERPRINT` were **not** declared in this repo's manifest sources at all — they're merged in from `local_auth_android` (the app does use biometric login via `local_auth: ^2.3.0`), so `USE_BIOMETRIC` is expected. `USE_FINGERPRINT` is the deprecated (API 28) permission the report flags as redundant.

**Done:** stripped the deprecated permission the same way other plugin-merged broad permissions were already stripped in the manifest:
```xml
<uses-permission android:name="android.permission.USE_FINGERPRINT" tools:node="remove"/>
```

---

### F-13 — `fullBackupContent` / Auto Backup data extraction
**Status:** Already correct — no action.

**Current state:** `android:allowBackup="false"` plus both `res/xml/backup_rules.xml` and `res/xml/data_extraction_rules.xml` exclude `root`/`file`/`database`/`sharedpref`/`external` from cloud backup *and* device transfer. Belt-and-suspenders, already fully mitigated.

---

### F-14 — `Math.random()` in bundled `t-rex.html`
**Status:** Third-party asset, not first-party code — no action.

**Current state:** The Chromium offline-dino-game asset ships inside the `flutter_inappwebview` plugin package itself (`pubspec.yaml`: `flutter_inappwebview: ^6.1.5`), not under this repo's `assets/`/`lib/`. No security-sensitive first-party code uses `Math.random()`.

**Plan:** Track upstream plugin updates only; note in reply to auditor that this is out-of-repo.

---

### F-15 — Unvalidated `geo:` / `google.navigation:` deep link construction
**Status:** Fixed.

**Current state (before fix):** `lib/core/navigation/map_navigation_service.dart` built `geo:$dest?q=$dest($label)` and `google.navigation:q=$dest` from caller-supplied lat/lng (numeric, low injection risk) and free-text `label`/`query` strings that were only `Uri.encodeComponent`-escaped — no charset/length validation before being embedded and handed to `ExternalUrlLauncher`.

**Done:** added `_isValidCoordinate`/`_isValidOptionalPair` (reject non-finite or out-of-range lat/lng — `openDirections` now returns `false` instead of building a URI) and `_sanitizeFreeText` (strips control characters, caps length at 100) applied via `_normalizeQuery`, which both `_encodeLabel` (directions) and `openPlaceSearch` already route through.

---

### F-16 — WebView file upload has no domain-level restriction
**Status:** Fixed — at the navigation layer, since there's no Dart-level `onShowFileChooser` hook to attach a check to directly (see F-09).

**Current state (before fix):** No origin/domain allowlist existed anywhere in `lib/core/webview/`. `webview_navigation_policy.dart` classifies URIs by scheme/extension for *navigation* decisions only and was never consulted for file-chooser handling.

**Done:** dashboard "portal" WebView URLs are backend-driven (`DashboardCardMapper._mapOne` reads `card.url` from the dashboard cards API), so an exact-host list wasn't the right shape — a new legitimate portal card on an existing government domain shouldn't require an app release to keep working. Added `WebViewTrustedHosts` (`lib/core/webview/service/webview_trusted_hosts.dart`), a domain-*suffix* allowlist (`*.mp.gov.in`, `*.eci.gov.in`, plus the existing dev/LAN exception only when `allowCleartextLocalhost` is set), enforced in `app_webview.dart` at three points: before the initial load starts (`_prepare()`), on every `shouldOverrideUrlLoading` decision, and on popup/new-window creation (`onCreateWindow`). Refactored the LAN/dev-host heuristic that already existed in `WebViewSecurity` into a shared `WebViewDevHost` helper so both call sites use the same logic instead of duplicating it.

**Behavior change:** this blocks the current UAT `SURVEY_WEB_BASE_URL` (`mayurkumar2068.github.io`, F-11) from loading, since it's off both trusted suffixes — correct per the audit, but the UAT survey flow won't work again until F-11's URL is moved to an official domain. Prod and dev already point `SURVEY_WEB_BASE_URL` at `mplocalelection.mp.gov.in` and are unaffected.

---

### F-17 — Verbose logging enabled in UAT build, not release-gated
**Status:** Fixed.

**Current state (before fix):** `assets/env/uat.env` sets `ENABLE_LOGGING=true`; `AppLogger.configure()` (called from `lib/bootstrap/bootstrap.dart`) gated purely on the env var and `flavor.isProduction` — there was **no `kReleaseMode`/`kDebugMode` check**, so a UAT build compiled `--release` and distributed for testing still logged full request/response bodies (including auth headers, per `LoggingInterceptor`).

**Done:** `_EnvFilter.shouldLog()` in `lib/core/logging/app_logger.dart` now short-circuits to warning/error-only whenever `kReleaseMode` is true, before even looking at the `enabled`/`verbose` flags derived from `ENABLE_LOGGING`. This mirrors prod's existing behavior and now applies it to every `--release` build regardless of flavor or env config.

---

## Low / Info — already correct, no action

### F-18 — `MainActivity android:taskAffinity=""`
Confirmed present exactly as recommended. No action.

### F-19 — 5 components with intent filters, all `exported=false`
`ScheduledNotificationBootReceiver` and `ProfileInstallReceiver` are confirmed `exported="false"` directly in `AndroidManifest.xml` (the file already has an inline `VULN-009` comment from the L1 pass). `SharePlusPendingIntent` and `ModuleDependencies` aren't declared in this repo's manifest sources — they're merged from their own library AARs, which currently ship `exported="false"`. No first-party override contradicts this. Recommend confirming via a built merged manifest (`build/app/intermediates/merged_manifest/...`) if the auditor wants certainty at the APK level.

---

## Remaining work

1. **F-02 / F-03** — compute and set real SSL pins (prod + UAT) — highest impact, zero code risk, unblocks re-testing. *Needs the real hostnames' certs; not startable from this repo alone.*
2. **F-11** — move `SURVEY_WEB_BASE_URL` off personal GitHub Pages to an official `*.mp.gov.in`/`*.eci.gov.in` domain. Now also **required to restore the UAT survey WebView**, which F-16's allowlist blocks until this moves.
3. **F-09** — the remaining per-request MIME-filter gap: needs a `flutter_inappwebview` version bump (check whether a release exposes an `onShowFileChooser` Dart hook) or a native plugin fork. F-16 already narrows this to allowlisted government pages only.
4. **F-01 / F-06** — raise as tracked backend/infra work; not startable from this repo alone.
5. **F-10** — send clarifying question back to the auditor; no fix to make until the source library is identified.

**Done in this pass:** F-04/F-05 (native picker allowlist), F-12 (`USE_FINGERPRINT` removed), F-15 (geo/nav URI validation), F-16 (WebView domain-suffix navigation allowlist), F-17 (`kReleaseMode` logging backstop).

No action needed for F-07 (documented hardening note only), F-08 (accepted trade-off), F-13, F-14, F-18, F-19.
