/// Temporary product switches — flip without deleting routes/screens.
///
/// Set [kHideEvmScanning] to `false` to restore inventory + scanner tabs
/// and profile device stats.
const bool kHideEvmScanning = true;

/// Hides the dashboard stat strip (total surveys / sync counts).
const bool kHideDashboardStats = true;

/// Hides the reports screen and all navigation entry points.
const bool kHideReports = true;

/// Hides Online Nomination tile (dashboard + related entry points).
const bool kHideOnlineNomination = false;

/// Hides Election Expenditure Account (व्यय लेखा) tile.
const bool kHideExpenditureAccount = true;

/// Skips green onboarding slides + first-run language bottomsheet.
/// Splash continues as guest straight to the home/dashboard.
const bool kSkipOnboarding = true;

/// Until `po-party-details` / `save-po-party` are stable on prod, allow OTP when
/// save returns HTTP 404/401. Set to `false` after backend auth is confirmed.
const bool kBypassPoPartySaveOn404 = true;
