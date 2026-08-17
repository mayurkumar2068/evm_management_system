# Remediation Plan — Security, Architecture & Code Quality Audit

Generated from a read-only audit of branch `fix/survey-dynamic-ans-type` (262 Dart files,
~44,590 LOC) on 2026-08-14. Nothing in this repo was modified to produce this plan — every
item below is a proposed change, not a change already made. File:line references reflect the
audited commit (`c884db9`) and should be re-verified before starting work, since the branch
moves.

Full findings with evidence/quotes: see the published audit report (severity-tagged C1–C6 /
H1–H11 / M1–M6 / L1–L3 — IDs below match that report 1:1).

Legend: **Effort** is a rough size (S = <1 day, M = 1–3 days, L = 3+ days / needs design).

---

## Phase 0 — Do today, outside of sprint planning

These are live exposures, not backlog items.

- [ ] **C1 — Rotate the leaked voter-search credentials.** `VOTER_SEARCH_AES_KEY` and
      `VOTER_SEARCH_PASS_KEY` are public (committed to `assets/env/*.env` in a public GitHub
      repo, and hardcoded again as source fallbacks in `lib/config/environment_config.dart:120-127`).
      1. Rotate both values at the SECSearchAPI backend (mpsecerms.mp.gov.in) immediately.
      2. Remove the hardcoded fallback literals from `environment_config.dart` — fail closed
         (`throw StateError`) instead of falling back to a baked-in secret.
      3. Move `assets/env/{uat,prod}.env` out of version control (see Phase 1 for the
         supporting CI change); if `dev.env` must stay for onboarding, it must never carry
         a value that also protects UAT/prod.
      4. Scrub git history (`git filter-repo` / BFG) of the old key values — rotation alone
         doesn't remove them from history, but rotation is what makes the history no longer
         dangerous. Do the rotation first, don't block on history-scrubbing.
      — **Effort:** S (rotation) + M (history scrub, coordinate with backend team).

- [ ] **C2 — Confirm production signing status.** `android/app/build.gradle.kts:41` points the
      `release` build type at `signingConfigs.getByName("debug")` with no release
      `signingConfig` defined anywhere in the file.
      1. Establish whether a real release keystore exists outside this repo. If yes, wire it
         in via `signingConfigs { release { ... } }` reading from CI secrets / a
         `key.properties` file that is gitignored, never from a literal.
      2. If no release keystore exists, generate one, store it in a secrets manager, and treat
         every artifact built before this fix as unpublishable to Google Play.
      — **Effort:** S–M depending on whether a keystore already exists.

---

## Phase 1 — This sprint

- [ ] **C3 — Turn SSL pinning on where it matters, with a real pin.**
      - `assets/env/prod.env`: set `ENABLE_SSL_PINNING=true` and compute the real SHA-256
        public-key pin for `mplocalelection.mp.gov.in`.
      - `assets/env/uat.env`: replace the placeholder `SSL_PIN_SHA256=AAAA...=` with the real
        UAT endpoint's pin.
      - Add a **second (backup) pin** per environment (M2) so a certificate rotation doesn't
        cause a hard outage — `SslPinningService` currently only supports a single hash
        (`lib/core/security/ssl_pinning_service.dart:37`); extend it to accept a set.
      - Add a Android `network_security_config.xml` restricting `usesCleartextTraffic` to only
        the specific dev-only internal IP, instead of the current blanket
        `android:usesCleartextTraffic="true"`; tighten the iOS ATS exception domain list the
        same way.
      — **Effort:** M.

- [ ] **C4 — Implement the native screen-security channel.** Dart side
      (`lib/core/security/screen_security_service.dart`) already calls
      `MethodChannel('evm/screen_security')` with `enableSecure`/`disableSecure`; nothing on
      the native side answers it.
      - Android: in `MainActivity`, set/clear `WindowManager.LayoutParams.FLAG_SECURE` in
        response to the channel calls.
      - iOS: post screenshot-taken notifications (`UIApplication.userDidTakeScreenshotNotification`)
        back through the channel at minimum; full capture-prevention on iOS is not possible via
        `FLAG_SECURE`-equivalent, so document that gap explicitly rather than implying parity.
      - Add a smoke test (even a manual QA checklist item) since this can't be meaningfully
        unit-tested — CI won't catch a regression here on its own.
      — **Effort:** M.

- [ ] **C5 — Constrain the WebView bridge's `apiRequest`.**
      `lib/core/webview/service/webview_bridge.dart:136-186`.
      - Add a destination allowlist (derived from `EnvironmentConfig`'s known base URLs —
        `apiBaseUrl`, `poElectionApiBaseUrl`, `olinApiBaseUrl`, `surveyApiBaseUrl`, etc.) and
        reject any `apiRequest` call whose host isn't in that set.
      - Reuse the same `WebNavigationPolicy` already used for page navigation
        (`lib/core/webview/widget/app_webview.dart:313`) so there's one source of truth for
        "trusted origin," not two.
      — **Effort:** M.

- [ ] **H2 — Move `SURVEY_WEB_BASE_URL` off personal infrastructure.** Replace
      `https://mayurkumar2068.github.io/...` in `assets/env/uat.env` with a
      government-controlled UAT host before the next UAT cycle.
      — **Effort:** S (once a real host exists).

- [ ] **H1 — Fix the broken test suite so CI's coverage gate can run at all.**
      `test/unit/webview_url_utils_test.dart:24` references `appendWebViewLang`, which doesn't
      exist. Either implement that helper in `lib/core/webview/url/webview_url_utils.dart` if
      the behavior is still wanted, or delete the stale test block. Then confirm
      `flutter test --coverage` actually completes and the 80% gate in `ci.yml` evaluates for
      the first time.
      — **Effort:** S.

---

## Phase 2 — Next 2–3 sprints

- [ ] **C6 — Encrypt the local database at rest.**
      `lib/core/database/json_local_database.dart` currently writes plaintext JSON.
      `SecureStorageKeys.encryptionKey` is already declared but unused — wire it up:
      1. Generate a per-install AES key on first run, store it via `SecureStorageService`
         (Keychain/Keystore-backed).
      2. Encrypt the JSON payload before `_flush()` writes to disk, decrypt in `_load()`.
      3. Migrate existing on-disk collections on first launch after the update (read plaintext
         once, re-write encrypted).
      — **Effort:** L.

- [ ] **H4 — Sync queue: stop retrying dead tasks.** `lib/core/sync/sync_queue.dart:26-31`
      `pending()` should exclude `SyncStatus.failed` and `SyncStatus.conflict`, matching
      `WebSubmissionRepository.pending()` in `lib/core/offline/web_submission_repository.dart`.
      Add a `SyncManager`-level test that would have caught this (ties into H10).
      — **Effort:** S.

- [ ] **H5 — Sync queue: apply exponential backoff.** `lib/core/sync/sync_manager.dart:113-138`
      never calls `RetryPolicy.delayFor(...)`. Wire it in the same way
      `lib/core/offline/offline_sync_service.dart:185` already does, but without blocking the
      whole queue drain sequentially (see M4 below — fix both together).
      — **Effort:** M.

- [ ] **H6 — Clear session-scoped state on sign-out.** `ActivityLogController` and
      `DeviceRecordsController` (both `permanent: true` in
      `lib/core/di/app_services.dart:165-169`) must be reset when
      `AuthController.signOut()` (`auth_controller.dart:132-151`) and
      `ServiceAuthController.signOut()` (`service_auth_controller.dart:532-559`) run. Either
      add an explicit `.clear()` call to both controllers on sign-out, or subscribe them to
      `SessionEventBus` and clear on the sign-out event so the fix doesn't have to be
      duplicated at every sign-out call site in the future.
      — **Effort:** M.

- [ ] **M4 — Don't block the offline-sync drain on one flaky item's backoff delay.**
      `lib/core/offline/offline_sync_service.dart:141-186` awaits `delayFor(...)` inside the
      per-item loop. Move the delayed item to the back of the queue / skip it for this pass
      instead of blocking subsequent items behind it.
      — **Effort:** M. (Bundle with H5.)

- [ ] **M5 — Purge synced offline submissions.** Nothing currently deletes rows from
      `LocalCollections.webSubmissions` once `synced`. Add a purge (either immediate on
      success, or a periodic sweep) so the collection — and the whole-file JSON rewrite cost in
      `JsonLocalDatabase` — doesn't grow unbounded over an install's lifetime across elections.
      — **Effort:** S.

- [ ] **M6 — Surface manual sync conflicts somewhere.** `SyncStatus.conflict`
      (`lib/core/sync/sync_manager.dart:109`) is written but never read by any screen. Add a
      minimal "Sync issues" list (even inside the existing Sync Management feature) so
      conflicted records are visible and actionable instead of silently stuck forever.
      — **Effort:** M.

---

## Phase 3 — Ongoing / structural

- [ ] **H3 — Audit for other flavor-gated shortcuts.** The hardcoded dev backdoor
      (`admin`/`admin123`, `auth_controller.dart:85-114`) and the corrective code for a
      previously-shipped hardcoded guest identity (`auth_controller.dart:50-57`) suggest this
      pattern has recurred. Grep the codebase for other `Flavor.dev` / `kDebugMode` gated
      branches that bypass real auth or validation, and add a lint/CI check (e.g. a custom
      analyzer rule or a pre-release checklist item) that flags new ones.

- [ ] **H7 — Add a domain/use-case layer to `voter_search` and `online_nomination`.** Follow
      the `auth` feature's pattern (`AuthModule` → use case → `Result<T>`). Do this
      incrementally, feature by feature, starting with whichever of the two changes most often.

- [ ] **H8 — Converge on one error-handling model.** Migrate `presiding_concern`'s custom
      exceptions (`TurnoutCountValidationException`, `PoPartyApiException`,
      `PoOfficerDetailsException`) to map into `Failure`/`Result<T>` at the repository
      boundary, the way `auth` already does, instead of being caught by type in presentation
      widgets. Replace the 9 silent `catch (_) {}` sites with at minimum an `AppLogger` call.

- [ ] **H9 — Pick one DI strategy and migrate to it.** Recommend standardizing on GetX
      bindings scoped per-route/per-feature (not permanent-forever globals) rather than the
      current three-way mix of global composition root, static `??=` locators, and locators
      that themselves call `Get.find`. This is the prerequisite for H10.

- [ ] **H10 — Grow controller/use-case test coverage from ~0.** Blocked on H9 (untestable
      static locators). Once DI is consistent, prioritize tests for `SyncManager` (would have
      caught H4/H5), `AuthController`, and the two features touched by H7.

- [ ] **H11 — Consolidate the duplicated route guards.** Merge
      `lib/app/routes/auth_navigation_guard.dart` and `lib/app/routes/auth_middleware.dart`
      into a single source of truth for the auth-state redirect logic (including the
      `kHideReports` check that only one of them currently honors) so the two can't diverge
      again.

- [ ] **M1 — Add automated dependency/vulnerability scanning to CI.** Nothing in
      `.github/workflows/` currently checks for outdated or known-vulnerable packages. Add
      Dependabot (or `osv-scanner`) as a required check, and separately schedule the
      already-identified version bumps (`flutter_secure_storage`, `local_auth`,
      `permission_handler`, `share_plus`, `geolocator`, `fl_chart` are 1–2 majors behind).

- [ ] **M3 — Route repeated validation/formatting through the shared helpers.** Consolidate
      the duplicated 10-digit mobile-number checks (`po_officer_details.dart:27`,
      `presiding_party_controller.dart:62`) into `lib/core/utils/validators.dart`, and the
      repeated `DateFormat` literals into `lib/core/utils/date_time_extensions.dart`.

- [ ] **L1 — Clear the lint backlog** (25 `flutter analyze` issues: deprecated
      `withOpacity`, missing `const`, unused imports, an unclosed `Sink` in
      `json_local_database.dart:126`, `avoid_dynamic_calls` in
      `service_auth_controller.dart`). Low individually; worth a single cleanup PR once H1
      makes `flutter analyze` a meaningful CI gate again.

- [ ] **L2 — Remove dead scaffolding.** `lib/features/polling_survey/` has no files under
      `di/`, `data/`, `domain/`, or `presentation/` — delete the empty tree or fill it in, so
      the module list doesn't misrepresent what's actually implemented.

- [ ] **L3 — Repo hygiene.** Delete `backup_final_po_ps_olin_and_all.zip` (741 KB full
      source snapshot, currently untracked) and add `*.zip` to `.gitignore` so a future
      `git add -A` can't accidentally commit another full copy of the secrets addressed in
      Phase 0.

---

## Notes for whoever picks this up

- Phase 0 and Phase 1 items are independent of each other and can be parallelized across
  people; Phase 2's H4/H5/M4 should be done together since they touch the same sync loop.
- H9 (DI strategy) is a prerequisite for H10 (test coverage) — don't schedule test-writing
  sprints before the DI cleanup or the tests will fight the same untestable static locators
  this audit flagged.
- Re-run `flutter analyze` and `flutter test --coverage` locally before closing H1 — that's the
  acceptance criterion for the whole CI-gate fix, not just "the one file compiles."
