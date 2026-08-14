# Feature Cleanup — Dormant Modules & Unused Code

Branch: `chore/deactivate-unused-features` (off `fix/survey-dynamic-ans-type`).
Date: 2026-08-14.

Goal: keep everything the app actually uses today working exactly as-is, and make the
modules that aren't currently used **dormant instead of live**, without deleting any code —
so nothing is lost and every one of these can be switched back on by flipping one constant.

**Nothing was deleted.** All changes are additive: new `if (!flag)` guards around existing
entry points, plus doc-comments on the affected screens pointing back to this file. Every
screen, controller and route below still exists, still compiles, and is one flag flip away
from being live again.

---

## 1. What's active vs. dormant right now

Before touching anything, I traced every navigation path in the app (bottom nav, login
quick-tiles, drawer/role table, and every `Get.toNamed`/`Get.offNamed` call site) to see what's
actually reachable today — not just what's plausible from the folder names.

| Feature | Status | Governing flag | Why |
|---|---|---|---|
| Presiding Officer | **Active** | — | Explicitly required; untouched. |
| Online Nomination | **Active** | `kHideOnlineNomination` | Was `true` on this branch's in-progress work (see §3) — flipped back to `false` because you explicitly said Nomination is needed. |
| Search (Voter / SECSearchAPI) | **Active** | — | Explicitly required; untouched. |
| Booth / Polling Survey (WebView) | **Active** | — | Explicitly required; untouched. Note: `lib/features/polling_survey/` (the native-Dart module by that name) is empty scaffolding unrelated to this — see §4. |
| Control Unit | **Dormant** | `kHideEvmScanning` | Already unreachable *before* this change — no nav tile, drawer item, or `Get.toNamed(AppRoute.controlUnit...)` exists anywhere in the app. |
| Ballot Unit | **Dormant** | `kHideEvmScanning` | Same as Control Unit — already unreachable before this change. |
| EVM Scanner | **Dormant** | `kHideEvmScanning` | Already off — `kHideEvmScanning` was already `true` on this branch. Bottom nav, login quick-tile and Profile's inventory stats already respected it; only the drawer/role table (`AppDestinations`) had missed it (fixed in §2). |
| Master Stock Register | **Dormant** | `kHideEvmScanning` | Same flag/state as Scanner. |
| Audit Trail | **Dormant** | `kHideAuditTrail` (**new flag**) | Had no flag before. Was already unreachable via any live nav (only listed in the unrendered role-guard table), so this was already dead in practice — now it's explicit and documented instead of accidental. |

**Net effect on the running app: none.** Every feature that was reachable before this branch
is still reachable exactly the same way. The dormant features were, with the sole exception of
the `AppDestinations` inconsistency below, already unreachable — this change makes that state
intentional, flagged, and documented instead of an artifact of scattered `if` checks.

---

## 2. What actually changed (files)

| File | Change |
|---|---|
| `lib/core/constants/feature_flags.dart` | Added `kHideAuditTrail = true` with a doc-comment explaining the underlying `ActivityLogController` stays wired. Flipped `kHideOnlineNomination` back to `false` (see §3). |
| `lib/app/router/app_destinations.dart` | Gated the Master Stock Register / Control Unit / Ballot Unit / Scanner entries behind `!kHideEvmScanning`, and the Audit Trail entry behind `!kHideAuditTrail`. **This is the one real inconsistency fixed**: the bottom nav, login screen and profile screen already hid these behind `kHideEvmScanning`, but this table (used for role-based route guarding in `auth_navigation_guard.dart` / `auth_middleware.dart`) still listed them unconditionally. |
| `lib/features/control_unit/presentation/screens/control_unit_screen.dart` | Doc-comment only: marked dormant, explains why, points here. |
| `lib/features/ballot_unit/presentation/screens/ballot_unit_screen.dart` | Same. |
| `lib/features/master_stock_register/presentation/screens/master_stock_register_screen.dart` | Same. |
| `lib/features/audit_trail/presentation/screens/audit_trail_screen.dart` | Same. |
| `lib/features/scanner/presentation/screens/scanner_screen.dart` | Same, plus a note about its empty sibling folders (§4). |

Nothing in `lib/app/routes/app_pages.dart` (the `GetPage` route table) or
`lib/core/di/app_services.dart` (DI) was touched — deliberately. The codebase's own existing
convention (see the header comment already in `feature_flags.dart`: *"Temporary product
switches — flip without deleting routes/screens"*) keeps routes registered even when their
entry points are hidden, specifically so a flag flip is the only step needed to bring a
feature back. This cleanup follows that same convention rather than introducing a second one.

**Shared services were left fully wired on purpose.** `DeviceRecordsController` and
`ActivityLogController` back the dormant screens, but they're also read by screens that stay
active: Search and Profile and Device Detail read `DeviceRecordsController`; Dashboard,
Notifications, Sync Management and Device Detail read `ActivityLogController`. Disconnecting
either service — rather than just the dormant *viewing* screens — would have been a real
functionality loss for features you asked to keep.

### Re-enabling any of these later
Flip the relevant constant in `lib/core/constants/feature_flags.dart` back to `false`
(`kHideEvmScanning` for the inventory module, `kHideAuditTrail` for Audit Trail). No other
change is required — every entry point re-appears and every route still works.

---

## 3. `kHideOnlineNomination` — flagging a conflict I resolved

This branch already had uncommitted, in-progress work (from before this task) that had flipped
`kHideOnlineNomination` from `false` to `true` — i.e. Online Nomination was about to be hidden.
That directly conflicts with this task's explicit instruction that Nomination is needed, so I
set it back to `false`. **Flagging this rather than burying it**: if that `true` value was
intentional for a reason unrelated to this cleanup, it needs to be re-applied separately — I
didn't want to silently override in-progress work without calling it out.

---

## 4. Unused code & optimization notes

Things found while tracing the above that are worth a decision, even though none of them were
touched:

- **`lib/features/scanner/{controller,data,domain,services,widgets}/`** — six empty directories
  (`controller/`, `data/datasource|mapper|models|repository_impl/`, `domain/repository|usecases|entities/`,
  `services/`, `widgets/`). The entire feature is one self-contained 762-line
  `scanner_screen.dart` that never uses this scaffolding. Either fill it in if a real
  data/domain layer is planned, or delete the empty tree — right now it misrepresents the
  feature's structure to anyone reading the folder layout.
- **`lib/features/polling_survey/{di,data,domain,presentation}/`** — same situation, fully
  empty. Unrelated to the active Booth/Polling Survey experience (that lives in the WebView +
  `presiding_concern`'s turnout/live-poll screens + the `survey_web` Angular app) — this
  native-Dart module by the `polling_survey` name was scaffolded and never built out. Worth
  deleting or renaming so it stops looking like a second, unfinished survey implementation.
- **`lib/features/control_unit/` and `lib/features/ballot_unit/`** — 12 lines each, both pure
  pass-throughs to the shared `DeviceRegistrationView` widget. Good reuse of that widget; the
  "feature" folders themselves carry no logic of their own, which is worth knowing if either
  is ever revived — the actual registration/validation/audit-logging logic to update lives in
  `lib/shared/widgets/device_registration_view.dart`, not in these two files.
- **`master_stock_register_screen.dart`** and **`audit_trail_screen.dart`** both wrap their
  *entire* `build()` in a single `Obx(...)` and render their list with a plain `for` loop
  instead of a virtualized `ListView.builder` — every mutation to `DeviceRecordsController` /
  `ActivityLogController` anywhere in the app rebuilds the whole screen and every row, even
  while dormant screens aren't being viewed the underlying lists they read from grow
  unbounded. If either is reactivated, that's worth fixing at the same time (also flagged in
  the earlier architecture/security audit — see `plan.md`, items H10/C6).
- **`DeviceRecordsController` / `ActivityLogController`** are registered `permanent: true` in
  `lib/core/di/app_services.dart` and never released or cleared on sign-out — already tracked
  as a Critical finding in `plan.md` (cross-officer data leak on shared devices). Making the
  *viewing screens* dormant here doesn't reduce that risk, since the controllers themselves
  stay wired for the active screens that depend on them; the real fix is still the one
  described in `plan.md`.
- **App size**: this cleanup does not reduce the compiled binary size. The dormant screens are
  unreachable but still imported (by `app_pages.dart`'s route table), so Dart's tree-shaker
  still includes them. Trimming binary size would mean actually deleting the files/routes,
  which trades away the "flip a flag to restore it" safety this cleanup was asked to preserve —
  a separate decision to make once a feature is confirmed permanently retired rather than
  temporarily dormant.

---

## 5. Verification

- `flutter analyze` on every changed file and directory: **no issues**.
- Full-project `flutter analyze`: same 25 pre-existing issues as before this branch (1 error —
  the already-broken `test/unit/webview_url_utils_test.dart`, tracked in `plan.md` H1 — plus 24
  pre-existing lint infos/warnings), confirming nothing here introduced a new problem.
- Confirmed by repo-wide search (not assumption) that Control Unit, Ballot Unit and Audit Trail
  had zero live navigation call sites before this change — see §1.
