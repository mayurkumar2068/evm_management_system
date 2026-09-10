# AUDIT_REPORT.md — MPSeCNet code optimisation

Branch: `chore/code-optimisation`  
Date: 2026-09-10  
Scope: Flutter `lib/`, `test/`, `pubspec.yaml` (read-only Phase 1)

---

# Executive Summary

The codebase is already partially cleaned (`chore: code quality optimization` history). Remaining **SAFE** work is narrow: delete verified-unused widgets, prune barrel exports, remove unused dev deps (`mocktail`, `build_runner`), and consolidate a few identical JSON/privacy helpers. Feature-flagged modules (nomination, EVM, reports, etc.) must stay. Almost no obsolete commented-out code blocks exist; comment removal is limited to files we touch (redundant noise only), not mass doc-comment deletion.

---

# Codebase Overview

- Flutter + GetX app for MP State Election Commission (guest dashboard + officer flows).
- Dual design systems: `lib/shared/design_system/` + `lib/design_system/mpsec/` (both live).
- Masters `card-list` drives dashboard tiles; static `_buildServices` is offline/API fallback.
- Many modules gated by `kHide*` flags — code intentionally retained.

---

# Duplicate Files

| Path | Why | Related | Evidence | Risk | Action |
|------|-----|---------|----------|------|--------|
| `mpsec_gradient_header.dart` | Unused gradient header | `app_gradient_header.dart` (used) | Class never constructed | SAFE | Delete unused MPSEC file + export |
| CU vs BU screens | Thin wrappers | `DeviceRegistrationView` | Intentional | HIGH RISK | Do not merge |
| Dual DS banners/cards | Overlap look | shared + mpsec | Both referenced | NEEDS VERIFICATION | Do not merge |

---

# Duplicate Code

| Finding | Paths | Risk | Action |
|---------|-------|------|--------|
| `_asMap` JSON coerce | dashboard_cards_repository, feature_flags, sync, voter_search | SAFE | Shared `json_map.dart` |
| Scalar parsers | dashboard_card_model, service_session, etc. | SAFE | Shared parsers (preserve defaults) |
| API Status hand-parse vs `ApiEnvelope` | dashboard cards, service_auth | SAFE with care | Extend carefully later |
| Dio message extract | ErrorMapper, PO, auth, nomination | NEEDS VERIFICATION | Defer unify |
| `login_screen` soft chrome vs `service_auth_chrome` | auth screens | SAFE | Optional reuse (defer if large) |
| Privacy URL string | `privacy_policy.dart` + `environment_config.dart` | SAFE | Single constant |
| `categoryLabel` double scan | `dashboard_card_mapper.dart` | SAFE | One-pass helper |

---

# Unused Files

| Path | Evidence | Risk | Action |
|------|----------|------|--------|
| `presiding_booth_map_card.dart` | Zero imports | SAFE | Delete |
| `busy_state_mixin.dart` | Zero refs | SAFE | Delete |
| `app_scaffold.dart` | Export only | SAFE | Delete + unexport |
| `app_search_field.dart` | Export only | SAFE | Delete + unexport |
| `mpsec_gradient_header.dart` | Export only | SAFE | Delete + unexport |
| `dashboard_activity_list.dart` | Export only | SAFE | Delete + unexport |
| `dashboard_alert_banner.dart` | Export only | SAFE | Delete + unexport |
| `dashboard_welcome_card.dart` | Export only | SAFE | Delete + unexport |
| `nomination_feature_bullet.dart` | Export only under nomination | NEEDS VERIFICATION | Keep (flagged tree) |

---

# Unused Code

- No `flutter analyze` unused_import / dead_code on main lib (aside infos).
- Barrel exports of unused widgets = primary dead surface.

---

# Unused Dependencies

| Package | Evidence | Risk | Action |
|---------|----------|------|--------|
| `mocktail` | Zero usage | SAFE | Remove |
| `build_runner` | No codegen / `*.g.dart` | SAFE | Remove |
| `cupertino_icons` | Font package | NEEDS VERIFICATION | Keep |
| `flutter_launcher_icons` | Tooling config | NEEDS VERIFICATION | Keep |

---

# Localization Audit

- Do **not** change any `en.json` / `hi.json` values (text safety rule).
- Unused key purge deferred (dynamic `.tr()` risk).

---

# Hardcoded Values Audit

- Privacy URL duplicated — SAFE consolidate to one constant.
- Env URLs / API endpoints — leave (behavior).
- Secrets in `.env` — do not commit/alter as cleanup.

---

# Performance Optimization Opportunities

| Item | Risk | Action |
|------|------|--------|
| Dashboard `_rebuildAsync` thrash | NEEDS VERIFICATION | Defer |
| `json_local_database` flush batching | HIGH RISK | Leave |
| Mapper `categoryLabel` double scan | SAFE | One pass |

---

# Architecture Improvements

- Do not redesign dual DS or merge dashboard fallback with API mapper (HIGH RISK).
- Prefer minimal SAFE deletions + helpers.

---

# Risk Assessment

- **SAFE:** unused widgets, barrel prune, mocktail/build_runner, privacy constant, json helper, categoryLabel.
- **NEEDS VERIFICATION:** nomination unused bullet, mobile validator unify, Dio ErrorMapper unify, dashboard debounce.
- **HIGH RISK:** delete `kHide*` modules, merge CU/BU, change APIs/text, split huge files for size.

---

# Recommended Cleanup Opportunities

1. Delete 8 SAFE unused files; prune exports.
2. Remove `mocktail` + `build_runner`.
3. Add `lib/core/utils/json_map.dart` and wire 2–3 callers.
4. Single privacy URL constant.
5. One-pass category labels in mapper.

---

# Items That Must NOT Be Changed

- All `kHide*` feature trees and routes.
- Localization values / user-visible text.
- API contracts, auth, WebView, permissions.
- Platform assets, PrivacyInfo, env secrets.
- Dashboard static fallback tile set semantics.

---

# Final Audit Conclusion

Safe optimisation surface is small and high-confidence. Proceed with PLAN.md Phase A (+ limited Phase B helpers). Skip aggressive refactors.

---

# Comment policy (user request)

- No large commented-out dead blocks found under `lib/`.
- During implementation: remove redundant/obsolete comments only in files we edit; keep non-obvious intent comments that prevent regressions.
