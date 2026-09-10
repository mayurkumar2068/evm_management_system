# PLAN.md — Safe optimisation (from AUDIT_REPORT.md)

Branch: `chore/code-optimisation`

Baseline locked: guest dashboard, card-list API, voter search, claims WebView, PS/PO login+register, PO logout/cache, privacy links, store builds. No text/API/navigation changes.

---

## Phase A — Safe Cleanup

### A1. Delete verified unused widgets
- **What:** Remove unused Dart files and barrel exports.
- **Files:**
  - Delete: `lib/features/presiding_concern/presentation/widgets/presiding_booth_map_card.dart`
  - Delete: `lib/shared/mixins/busy_state_mixin.dart`
  - Delete: `lib/shared/design_system/widgets/app_scaffold.dart`
  - Delete: `lib/shared/design_system/widgets/app_search_field.dart`
  - Delete: `lib/design_system/mpsec/widgets/mpsec_gradient_header.dart`
  - Delete: `lib/features/dashboard/presentation/widgets/dashboard_activity_list.dart`
  - Delete: `lib/features/dashboard/presentation/widgets/dashboard_alert_banner.dart`
  - Delete: `lib/features/dashboard/presentation/widgets/dashboard_welcome_card.dart`
  - Edit: `dashboard_widgets.dart`, `design_system.dart`, `mpsec_design_system.dart` (drop exports)
- **Why safe:** Zero construction / import refs (verified).
- **Validation:** `dart analyze` on `lib/`; grep class names = zero.
- **Rollback:** git restore deleted paths.

### A2. Remove unused dev dependencies
- **What:** Drop `mocktail`, `build_runner` from `pubspec.yaml`; `flutter pub get`.
- **Why safe:** Zero code references; docs say hand-written providers.
- **Validation:** `flutter pub get`; tests still run.
- **Rollback:** restore pubspec + lock.

---

## Phase B — Duplicate Consolidation (verified SAFE only)

### B1. Shared JSON map helper
- **What:** Add `lib/core/utils/json_map.dart` with `asStringKeyedMap`.
- **Files:** Wire `dashboard_cards_repository.dart`, `app_feature_flags_controller.dart` (same semantics).
- **Why safe:** Pure extract; no behavior change.
- **Validation:** unit tests for dashboard mapper; analyze.

### B2. Privacy URL single constant
- **What:** Use `PrivacyPolicy.defaultUrl` (or shared const) from `environment_config` default.
- **Why safe:** Same URL string.
- **Validation:** privacy_policy_test.

### B3. Dashboard category labels one-pass
- **What:** Mapper returns both category labels in one scan; controller uses it.
- **Why safe:** Same labels, fewer loops.
- **Validation:** `dashboard_card_mapper_test.dart`.

---

## Phase C — Unused Code/File Removal

Covered by A1. Nomination bullet **deferred** (NEEDS VERIFICATION).

---

## Phase D — Dependency Cleanup

Covered by A2. Keep `cupertino_icons`, `flutter_launcher_icons`.

---

## Phase E — Performance

Only B3. No debounce of dashboard rebuild (NEEDS VERIFICATION).

---

## Phase F — Hardcoding

Only B2 privacy URL.

---

## Phase G — Final Validation

1. `dart analyze lib/`
2. `flutter test test/unit/dashboard_card_mapper_test.dart test/unit/privacy_policy_test.dart`
3. Grep deleted symbols = empty
4. Append post-cleanup notes to this file

---

## Intentionally NOT in this plan

- Delete online nomination / EVM / reports / audit trees
- Merge static dashboard fallback with API mapper
- Unify all Dio error mappers
- Split large files for size
- Localization key purge / text edits
- Mass removal of documentation comments

---

## Post-Cleanup Optimization Opportunities

Completed on `chore/code-optimisation`:
- Phase A1 unused widgets deleted; barrels pruned
- Phase A2 `mocktail` + `build_runner` removed
- Phase B1 `asStringKeyedMap` shared
- Phase B2 `PrivacyUrls.statement` single constant
- Phase B3 `categoryLabels` one-pass

Deferred (still valid for later):
- ~~Wire more `_asMap` call sites to `asStringKeyedMap`~~ (sync + survey_report done; voter_search kept — string JSON decode)
- ~~Reuse `ServiceAuthChrome` backdrop on main `login_screen`~~ (hero kept local — different layout)
- Dashboard rebuild debounce (needs measurement)
- Nomination `NominationFeatureBullet` unused check under flag tree

### Phase 2 follow-up (2026-09-10)
- `sync_service.dart` / `survey_report_analytics.dart` → `asStringKeyedMap`
- `login_screen` → `ServiceAuthBackdrop(leftOrbTop: 140)`; removed duplicate `_SoftBackdrop`
- `ServiceAuthBackdrop` accepts `leftOrbTop` so guest gateway layout stays identical
