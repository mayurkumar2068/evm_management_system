/// Temporary product switches — flip without deleting routes/screens.
///
/// Set [kHideEvmScanning] to `false` to restore inventory + scanner tabs
/// and profile device stats.
const bool kHideEvmScanning = true;

/// Hides the dashboard stat strip (total surveys / sync counts).
const bool kHideDashboardStats = true;

/// Hides the reports screen and all navigation entry points.
const bool kHideReports = true;

/// App Store 5.1.1 — Online Nomination is fully disabled for this build.
/// Screens, models, and APIs stay in the tree; routes/DI/nav are not registered.
/// Restore by setting this to `false` (routes in `AppPages`, DI in `AppServices`).
const bool kHideOnlineNomination = true;

/// Voter Registration / Claim–Objection is **not** gated by a compile-time
/// hide flag. Visibility is controlled at runtime by
/// `AppFeatureFlagsController.showRegistration` (env `SHOW_REGISTRATION`
/// baseline + public API `showRegistration`). Default = shown (App Store).

/// Hides the EMS/IMS dashboard tile.
const bool kHideEms = true;

/// Hides Election Expenditure Account (व्यय लेखा) tile.
const bool kHideExpenditureAccount = true;

/// Hides the Audit Trail entry point (drawer/role-guard table today; add any
/// future nav entry point behind this same flag). The screen and its data
/// (`ActivityLogController`) are untouched and still collect events — only
/// the standalone viewing screen is hidden, since other active screens
/// (Dashboard, Notifications, Sync Management, Device Detail) read from the
/// same activity log. See CLEANUP.md.
const bool kHideAuditTrail = true;

/// Skips green onboarding slides + first-run language bottomsheet.
/// Splash continues as guest straight to the home/dashboard.
const bool kSkipOnboarding = true;

/// Until `po-party-details` / `save-po-party` are stable on prod, allow OTP when
/// save returns HTTP 404/401. Set to `false` after backend auth is confirmed.
const bool kBypassPoPartySaveOn404 = true;
