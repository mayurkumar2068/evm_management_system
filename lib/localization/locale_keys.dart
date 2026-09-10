/// Centralized, type-safe localization keys.
abstract final class LocaleKeys {
  // App
  static const String appName = 'app.name';
  static const String appTagline = 'app.tagline';
  static const String appSystem = 'app.system';
  static const String appVersion = 'app.version';

  // Common
  static const String commonOk = 'common.ok';
  static const String commonCancel = 'common.cancel';
  static const String commonRetry = 'common.retry';
  static const String commonSave = 'common.save';
  static const String commonSaved = 'common.saved';
  static const String commonSearch = 'common.search';
  static const String commonNoData = 'common.no_data';
  static const String commonSomethingWentWrong = 'common.something_went_wrong';
  static const String commonBack = 'common.back';
  static const String commonSkip = 'common.skip';
  static const String commonContinue = 'common.continue';
  static const String commonGetStarted = 'common.get_started';
  static const String commonExport = 'common.export';
  static const String commonJustNow = 'common.just_now';
  static const String commonTakePhoto = 'common.take_photo';
  static const String commonChooseFromGallery = 'common.choose_from_gallery';
  static const String commonPickImageSource = 'common.pick_image_source';
  static const String commonNoInternet = 'common.no_internet';

  // Error
  static const String errorNetwork = 'error.network';
  static const String errorServer = 'error.server';
  static const String errorUnauthorized = 'error.unauthorized';
  static const String errorForbidden = 'error.forbidden';
  static const String errorNotFound = 'error.not_found';
  static const String errorValidation = 'error.validation';
  static const String errorUnknown = 'error.unknown';

  // Auth
  static const String authUsername = 'auth.username';
  static const String authPassword = 'auth.password';
  static const String authBiometricReason = 'auth.biometric_reason';
  static const String authInvalidCredentials = 'auth.invalid_credentials';
  static const String authPoInvalidCredentials = 'auth.po_invalid_credentials';
  static const String authDistrictInvalidCredentials =
      'auth.district_invalid_credentials';
  static const String authUsernameRequired = 'auth.username_required';
  static const String authPasswordRequired = 'auth.password_required';
  static const String authPasswordTooShort = 'auth.password_too_short';
  static const String authDistrict = 'auth.district';
  static const String authGatewayWelcome = 'auth.gateway_welcome';
  static const String authOtpSendFailed = 'auth.otp_send_failed';
  static const String authOtpInvalid = 'auth.otp_invalid';

  // Service auth
  static const String serviceAuthSubtitleDefault =
      'service_auth.subtitle_default';
  static const String serviceAuthUserId = 'service_auth.user_id';
  static const String serviceAuthUsername = 'service_auth.username';
  static const String serviceAuthUserIdHint = 'service_auth.user_id_hint';
  static const String serviceAuthUsernameHint = 'service_auth.username_hint';
  static const String serviceAuthPassword = 'service_auth.password';
  static const String serviceAuthPasswordHint = 'service_auth.password_hint';
  static const String serviceAuthUserIdRequired =
      'service_auth.user_id_required';
  static const String serviceAuthUsernameRequired =
      'service_auth.username_required';
  static const String serviceAuthPasswordRequired =
      'service_auth.password_required';
  static const String serviceAuthHintStrip = 'service_auth.hint_strip';
  static const String serviceAuthSignInButton = 'service_auth.sign_in_button';
  static const String serviceAuthGenericError = 'service_auth.generic_error';
  static const String serviceAuthLoginModePassword =
      'service_auth.login_mode_password';
  static const String serviceAuthLoginModeOtp = 'service_auth.login_mode_otp';
  static const String serviceAuthMobileNo = 'service_auth.mobile_no';
  static const String serviceAuthMobileNoHint = 'service_auth.mobile_no_hint';
  static const String serviceAuthMobileNoRequired =
      'service_auth.mobile_no_required';
  static const String serviceAuthMobileNoInvalid =
      'service_auth.mobile_no_invalid';
  static const String serviceAuthOtp = 'service_auth.otp';
  static const String serviceAuthOtpHint = 'service_auth.otp_hint';
  static const String serviceAuthOtpRequired = 'service_auth.otp_required';
  static const String serviceAuthOtpSentHint = 'service_auth.otp_sent_hint';
  static const String serviceAuthSendOtpButton = 'service_auth.send_otp_button';
  static const String serviceAuthResendOtpButton =
      'service_auth.resend_otp_button';
  static const String serviceAuthResendOtpIn = 'service_auth.resend_otp_in';
  static const String serviceAuthVerifyOtpButton =
      'service_auth.verify_otp_button';
  static const String serviceAuthOtpSentSuccess =
      'service_auth.otp_sent_success';
  static const String serviceAuthChangeMobile = 'service_auth.change_mobile';
  static const String serviceAuthNoAccount = 'service_auth.no_account';
  static const String serviceAuthRegisterButton = 'service_auth.register_button';
  static const String serviceAuthRegisterTitle = 'service_auth.register_title';
  static const String serviceAuthRegisterSubtitle =
      'service_auth.register_subtitle';
  static const String serviceAuthRegisterSubtitlePo =
      'service_auth.register_subtitle_po';
  static const String serviceAuthRegisterFullName =
      'service_auth.register_full_name';
  static const String serviceAuthRegisterFullNameHint =
      'service_auth.register_full_name_hint';
  static const String serviceAuthRegisterFullNameRequired =
      'service_auth.register_full_name_required';
  static const String serviceAuthRegisterDesignation =
      'service_auth.register_designation';
  static const String serviceAuthRegisterDesignationHint =
      'service_auth.register_designation_hint';
  static const String serviceAuthRegisterDesignationRequired =
      'service_auth.register_designation_required';
  static const String serviceAuthRegisterPasswordConfirm =
      'service_auth.register_password_confirm';
  static const String serviceAuthRegisterPasswordConfirmHint =
      'service_auth.register_password_confirm_hint';
  static const String serviceAuthRegisterPasswordMismatch =
      'service_auth.register_password_mismatch';
  static const String serviceAuthRegisterSubmit = 'service_auth.register_submit';
  static const String serviceAuthRegisterSuccess =
      'service_auth.register_success';
  static const String serviceAuthRegisterSuccessPo =
      'service_auth.register_success_po';
  static const String serviceAuthRegisterUrlMissing =
      'service_auth.register_url_missing';

  // Onboarding
  static const String onboardingSecurityTag = 'onboarding.security.tag';
  static const String onboardingSecurityTitle = 'onboarding.security.title';
  static const String onboardingSecurityDesc = 'onboarding.security.desc';
  static const String onboardingProductivityTag = 'onboarding.productivity.tag';
  static const String onboardingProductivityTitle =
      'onboarding.productivity.title';
  static const String onboardingProductivityDesc =
      'onboarding.productivity.desc';
  static const String onboardingAnalyticsTag = 'onboarding.analytics.tag';
  static const String onboardingAnalyticsTitle = 'onboarding.analytics.title';
  static const String onboardingAnalyticsDesc = 'onboarding.analytics.desc';
  static const String onboardingLanguageTitle = 'onboarding.language_title';
  static const String onboardingLanguageSubtitle =
      'onboarding.language_subtitle';
  static const String onboardingLanguageContinue =
      'onboarding.language_continue';
  static const String onboardingLanguageHindi = 'onboarding.language_hindi';
  static const String onboardingLanguageEnglish = 'onboarding.language_english';
  static const String onboardingLanguageSoon = 'onboarding.language_soon';

  // Registration
  static const String regControlUnit = 'registration.control_unit';
  static const String regBallotUnit = 'registration.ballot_unit';
  static const String regRegisterCu = 'registration.register_cu';
  static const String regInventory = 'registration.inventory';
  static const String regReports = 'registration.reports';
  static const String regInformation = 'registration.information';
  static const String regManufacturer = 'registration.manufacturer';
  static const String regAutoSave = 'registration.auto_save';
  static const String regSaveNew = 'registration.save_new';
  static const String regSaveDevice = 'registration.save_device';
  static const String regRecentEntries = 'registration.recent_entries';
  static const String regNoEntries = 'registration.no_entries';
  static const String regBarcodeNum = 'registration.barcode_num';
  static const String regBarcodeHint = 'registration.barcode_hint';
  static const String regBoxNum = 'registration.box_num';
  static const String regBoxHint = 'registration.box_hint';
  static const String regDeviceId = 'registration.device_id';
  static const String regOpenScanner = 'registration.open_scanner';
  static const String regScannerSub = 'registration.scanner_sub';

  // Dashboard
  static const String dashboardRecentActivity = 'dashboard.recent_activity';
  static const String dashboardBrandTitle = 'dashboard.brand_title';
  static const String dashboardGreeting = 'dashboard.greeting';
  static const String dashboardGuest = 'dashboard.guest';
  static const String dashboardRole = 'dashboard.role';
  static const String dashboardDistrictUnset = 'dashboard.district_unset';
  static const String dashboardStatusActive = 'dashboard.status_active';
  static const String dashboardMainServices = 'dashboard.main_services';
  static const String dashboardVoterServices = 'dashboard.voter_services';
  static const String dashboardAboutElections = 'dashboard.about_elections';
  static const String dashboardViewAll = 'dashboard.view_all';
  static const String dashboardStatSurveysTotal =
      'dashboard.stat_surveys_total';
  static const String dashboardStatSurveysToday =
      'dashboard.stat_surveys_today';
  static const String dashboardStatSurveysSynced =
      'dashboard.stat_surveys_synced';
  static const String dashboardStatSurveysPending =
      'dashboard.stat_surveys_pending';
  static const String dashboardActEmptyHint = 'dashboard.act_empty_hint';
  static const String dashboardActSurveySubmitted =
      'dashboard.act_survey_submitted';
  static const String dashboardActSurveySynced = 'dashboard.act_survey_synced';
  static const String dashboardActSurveyFailed = 'dashboard.act_survey_failed';
  static const String dashboardActSurveyDefault =
      'dashboard.act_survey_default';
  static const String dashboardNotifPendingSync =
      'dashboard.notif_pending_sync';
  static const String dashboardNotifSyncedToday =
      'dashboard.notif_synced_today';
  static const String dashboardNotifFailed = 'dashboard.notif_failed';
  static const String dashboardNotifNone = 'dashboard.notif_none';
  static const String dashboardAlertTitle = 'dashboard.alert_title';
  static const String dashboardAlertSubtitle = 'dashboard.alert_subtitle';
  static const String dashboardWeeklyRegistrations =
      'dashboard.weekly_registrations';
  static const String dashboardSearchHint = 'dashboard.search_hint';

  // Scanner
  static const String scannerTitle = 'scanner.title';
  static const String scannerDetectionCombined = 'scanner.detection_combined';
  static const String scannerScanning = 'scanner.scanning';
  static const String scannerAlignPrompt = 'scanner.align_prompt';
  static const String scannerZoomActive = 'scanner.zoom_active';
  static const String scannerSearching = 'scanner.searching';
  static const String scannerLocking = 'scanner.locking';
  static const String scannerKeepInside = 'scanner.keep_inside';
  static const String scannerVerifying = 'scanner.verifying';
  static const String scannerAlmostThere = 'scanner.almost_there';
  static const String scannerLocked = 'scanner.locked';
  static const String scannerLaserComplete = 'scanner.laser_complete';
  static const String scannerDeviceIdentified = 'scanner.device_identified';
  static const String scannerScannedCode = 'scanner.scanned_code';
  static const String scannerDetectedAs = 'scanner.detected_as';
  static const String scannerDiscard = 'scanner.discard';
  static const String scannerConfirmPrefill = 'scanner.confirm_prefill';

  // Stats
  static const String statsTotal = 'stats.total';
  static const String statsActive = 'stats.active';
  static const String statsPending = 'stats.pending';
  static const String statsIssues = 'stats.issues';
  static const String statsSynced = 'stats.synced';
  static const String statsFailed = 'stats.failed';
  static const String statsControlUnits = 'stats.control_units';
  static const String statsBallotUnits = 'stats.ballot_units';
  static const String statsTotalInventory = 'stats.total_inventory';
  static const String statsBoxWiseCount = 'stats.box_wise_count';
  static const String statsRegistered = 'stats.registered';
  static const String statsInTransit = 'stats.in_transit';
  static const String statsDefective = 'stats.defective';
  static const String statsSearchInventory = 'stats.search_inventory';

  // Profile
  static const String profileTitle = 'profile.title';
  static const String profileSettings = 'profile.settings';
  static const String profileNotifications = 'profile.notifications';
  static const String profileNotificationsSub = 'profile.notifications_sub';
  static const String profileSignOut = 'profile.sign_out';
  static const String profileSignOutTitle = 'profile.sign_out_title';
  static const String profileSignOutMessage = 'profile.sign_out_message';
  static const String profileSignOutSuccess = 'profile.sign_out_success';
  static const String profileLoginRequiredTag = 'profile.login_required_tag';
  static const String profileLoginPickTitle = 'profile.login_pick_title';
  static const String profileLoginPickSubtitle = 'profile.login_pick_subtitle';
  static const String profileLoginPickBoothSub = 'profile.login_pick_booth_sub';
  static const String profileLoginPickExpenditureSub =
      'profile.login_pick_expenditure_sub';
  static const String profileThisWeek = 'profile.this_week';
  static const String profileRegisteredBy = 'profile.registered_by';
  static const String profileTimeline = 'profile.timeline';
  static const String profileDetails = 'profile.details';
  static const String profileUserId = 'profile.user_id';
  static const String profileUserName = 'profile.user_name';
  static const String profileSection = 'profile.section';
  static const String profileUrban = 'profile.urban';
  static const String profileRural = 'profile.rural';
  static const String profileDistrict = 'profile.district';
  static const String profileBody = 'profile.body';
  static const String profileBodyJanpad = 'profile.body_janpad';
  static const String profilePresidingOfficer = 'profile.presiding_officer';
  static const String profileEmail = 'profile.email';
  static const String profilePollingStation = 'profile.polling_station';
  static const String profileState = 'profile.state';
  static const String profileActiveSession = 'profile.active_session';

  // Audit
  static const String auditTitle = 'audit.title';
  static const String auditToday = 'audit.today';
  static const String auditYesterday = 'audit.yesterday';
  static const String auditBy = 'audit.by';
  static const String auditEmpty = 'audit.empty';
  static const String auditEmptySub = 'audit.empty_sub';

  // Settings
  static const String settingsAppearance = 'settings.appearance';
  static const String settingsDarkMode = 'settings.dark_mode';
  static const String settingsLanguage = 'settings.language';
  static const String settingsEnglish = 'settings.english';
  static const String settingsHindi = 'settings.hindi';
  static const String settingsTheme = 'settings.theme';
  static const String settingsLightMode = 'settings.light_mode';
  static const String settingsPushAlerts = 'settings.push_alerts';
  static const String settingsPushAlertsSub = 'settings.push_alerts_sub';
  static const String settingsDataSync = 'settings.data_sync';
  static const String settingsOfflineStorage = 'settings.offline_storage';
  static const String settingsRecordsStored = 'settings.records_stored';
  static const String settingsLegal = 'settings.legal';

  // Legal / privacy (Apple 5.1.1(i))
  static const String legalPrivacyPolicy = 'legal.privacy_policy';
  static const String legalPrivacyPolicySub = 'legal.privacy_policy_sub';
  static const String legalPrivacyPolicyOpenFailed =
      'legal.privacy_policy_open_failed';

  // Device Detail
  static const String detailTitle = 'detail.title';
  static const String detailBoxNo = 'detail.box_no';
  static const String detailDistrict = 'detail.district';
  static const String detailMfrYear = 'detail.mfr_year';
  static const String detailNotFound = 'detail.not_found';
  static const String detailNotFoundSub = 'detail.not_found_sub';

  // Search
  static const String searchHint = 'search.hint';
  static const String searchRecent = 'search.recent';
  static const String searchRecentEmpty = 'search.recent_empty';
  static const String searchAdvancedFilters = 'search.advanced_filters';
  static const String searchNoResults = 'search.no_results';
  static const String searchResultFor = 'search.result_for';
  static const String searchResultsFor = 'search.results_for';

  // Notifications
  static const String notificationsTitle = 'notifications.title';
  static const String notificationsCount = 'notifications.count';

  // Sync
  static const String syncTitle = 'sync.title';
  static const String syncPendingRecords = 'sync.pending_records';
  static const String syncNoPending = 'sync.no_pending';
  static const String syncHeroSyncing = 'sync.hero.syncing';
  static const String syncHeroDone = 'sync.hero.done';
  static const String syncHeroPending = 'sync.hero.pending';
  static const String syncLastSync = 'sync.last_sync';
  static const String syncUpToDate = 'sync.up_to_date';
  static const String syncAgain = 'sync.again';
  static const String syncStart = 'sync.start';
  static const String syncForceOffline = 'sync.force_offline';

  // Reports
  static const String reportsTitle = 'reports.title';
  static const String reportsLast7Days = 'reports.last_7_days';
  static const String reportsWeeklyTrend = 'reports.weekly_trend';
  static const String reportsLast6Weeks = 'reports.last_6_weeks';
  static const String reportsSurveyStatus = 'reports.survey_status';
  static const String reportsUrban = 'reports.urban';
  static const String reportsRural = 'reports.rural';
  static const String reportsUnknownArea = 'reports.unknown_area';
  static const String reportsByAreaType = 'reports.by_area_type';
  static const String reportsDetailTitle = 'reports.detail_title';
  static const String reportsDetailSub = 'reports.detail_sub';
  static const String reportsDistrictMeta = 'reports.district_meta';
  static const String reportsPollingStations = 'reports.polling_stations';
  static const String reportsSurveyCount = 'reports.survey_count';
  static const String reportsEmpty = 'reports.empty';
  static const String reportsEmptySub = 'reports.empty_sub';
  static const String reportsMonth = 'reports.month';
  static const String reportsQuarter = 'reports.quarter';
  static const String reportsThisPeriod = 'reports.this_period';
  static const String reportsExportOk = 'reports.export_ok';
  static const String reportsExportEmpty = 'reports.export_empty';
  static const String reportsDayMon = 'reports.day_mon';
  static const String reportsDayTue = 'reports.day_tue';
  static const String reportsDayWed = 'reports.day_wed';
  static const String reportsDayThu = 'reports.day_thu';
  static const String reportsDayFri = 'reports.day_fri';
  static const String reportsDaySat = 'reports.day_sat';
  static const String reportsDaySun = 'reports.day_sun';
  static const String reportsWeekLabel = 'reports.week_label';

  // Time
  static const String timeJustNow = 'time.just_now';
  static const String timeMinutes = 'time.minutes';
  static const String timeHours = 'time.hours';
  static const String timeDays = 'time.days';

  // Services
  static const String serviceExpenditureTitle = 'services.expenditure.title';

  static const String serviceVoterSearchEngineTitle =
      'services.voter_search_engine.title';
  static const String serviceVoterRegistrationTitle =
      'services.voter_registration.title';
  static const String serviceEmsTitle = 'services.ems.title';
  static const String serviceBoothTitle = 'services.booth.title';
  static const String servicePresidingTitle = 'services.presiding.title';
  static const String servicePresidingDesc = 'services.presiding.desc';
  static const String serviceOnlineNominationTitle =
      'services.online_nomination.title';
  static const String serviceOnlineNominationDesc =
      'services.online_nomination.desc';

  // Voter search (native)
  static const String voterSearchTitle = 'voter_search.title';
  static const String voterSearchEngineTitle = 'voter_search.engine_title';
  static const String voterSearchInstruction = 'voter_search.instruction';
  static const String voterSearchTabDetails = 'voter_search.tab_details';
  static const String voterSearchTabEpic = 'voter_search.tab_epic';
  static const String voterSearchDistrict = 'voter_search.district';
  static const String voterSearchDistrictHint = 'voter_search.district_hint';
  static const String voterSearchUrbanRural = 'voter_search.urban_rural';
  static const String voterSearchUrban = 'voter_search.urban';
  static const String voterSearchRural = 'voter_search.rural';
  static const String voterSearchBlock = 'voter_search.block';
  static const String voterSearchBlockHint = 'voter_search.block_hint';
  static const String voterSearchUrbanBody = 'voter_search.urban_body';
  static const String voterSearchUrbanBodyHint = 'voter_search.urban_body_hint';
  static const String voterSearchElectorName = 'voter_search.elector_name';
  static const String voterSearchElectorNameHint =
      'voter_search.elector_name_hint';
  static const String voterSearchRelativeName = 'voter_search.relative_name';
  static const String voterSearchRelativeNameHint =
      'voter_search.relative_name_hint';
  static const String voterSearchGender = 'voter_search.gender';
  static const String voterSearchGenderHint = 'voter_search.gender_hint';
  static const String voterSearchGenderAny = 'voter_search.gender_any';
  static const String voterSearchAge = 'voter_search.age';
  static const String voterSearchAgeHint = 'voter_search.age_hint';
  static const String voterSearchEpicNo = 'voter_search.epic_no';
  static const String voterSearchEpicHint = 'voter_search.epic_hint';
  static const String voterSearchSearch = 'voter_search.search';
  static const String voterSearchResultsTitle = 'voter_search.results_title';
  static const String voterSearchResultsCount = 'voter_search.results_count';
  static const String voterSearchNoResults = 'voter_search.no_results';
  static const String voterSearchErrorDistrict = 'voter_search.error_district';
  static const String voterSearchErrorBlock = 'voter_search.error_block';
  static const String voterSearchErrorUrbanBody =
      'voter_search.error_urban_body';
  static const String voterSearchErrorName = 'voter_search.error_name';
  static const String voterSearchErrorEpic = 'voter_search.error_epic';
  static const String voterSearchErrorAge = 'voter_search.error_age';
  static const String voterSearchErrorGeneric = 'voter_search.error_generic';
  static const String voterSearchEpicLabel = 'voter_search.epic_label';
  static const String voterSearchAgeLabel = 'voter_search.age_label';
  static const String voterSearchBoothLabel = 'voter_search.booth_label';
  static const String voterSearchHouseLabel = 'voter_search.house_label';
  static const String voterSearchPanchayatName = 'voter_search.panchayat_name';
  static const String voterSearchBlockName = 'voter_search.block_name';
  static const String voterSearchVillageName = 'voter_search.village_name';
  static const String voterSearchUrbanBodyName = 'voter_search.urban_body_name';
  static const String voterSearchWardNo = 'voter_search.ward_no';
  static const String voterSearchUrbanWardNo = 'voter_search.urban_ward_no';
  static const String voterSearchRuralWardNo = 'voter_search.rural_ward_no';
  static const String voterSearchWardName = 'voter_search.ward_name';
  static const String voterSearchVoterNo = 'voter_search.voter_no';
  static const String voterSearchHouseNo = 'voter_search.house_no';
  static const String voterSearchMohallaNo = 'voter_search.mohalla_no';
  static const String voterSearchPartNo = 'voter_search.part_no';
  static const String voterSearchRelativeNameTable =
      'voter_search.relative_name_table';
  static const String voterSearchAddress = 'voter_search.address';
  static const String voterSearchBoothFullLabel =
      'voter_search.booth_full_label';
  static const String voterSearchBackToSearch = 'voter_search.back_to_search';
  static const String voterSearchGenerateSlip = 'voter_search.generate_slip';
  static const String voterSearchSlipGenerating =
      'voter_search.slip_generating';
  static const String voterSearchSlipFailed = 'voter_search.slip_failed';
  static const String voterSearchFilter = 'voter_search.filter';
  static const String voterSearchFilterTitle = 'voter_search.filter_title';
  static const String voterSearchFilterApply = 'voter_search.filter_apply';
  static const String voterSearchFilterClear = 'voter_search.filter_clear';
  static const String voterSearchFilterWardAll = 'voter_search.filter_ward_all';
  static const String voterSearchFilterRuralHint =
      'voter_search.filter_rural_hint';
  static const String voterSearchFilterUrbanHint =
      'voter_search.filter_urban_hint';

  // Online nomination
  static const String nominationTitle = 'nomination.title';
  static const String nominationSubtitle = 'nomination.subtitle';
  static const String nominationApplyOnline = 'nomination.apply_online';
  static const String nominationTrackStatusCta = 'nomination.track_status_cta';
  static const String nominationHeaderDepartment =
      'nomination.header_department';
  static const String nominationWelcomeTitle = 'nomination.welcome_title';
  static const String nominationTagline = 'nomination.tagline';
  static const String nominationUrbanTitle = 'nomination.urban_title';
  static const String nominationUrbanSubtitle = 'nomination.urban_subtitle';
  static const String nominationPanchayatTitle = 'nomination.panchayat_title';
  static const String nominationPanchayatSubtitle =
      'nomination.panchayat_subtitle';
  static const String nominationUrbanSelectTitle =
      'nomination.urban_select_title';
  static const String nominationUrbanSelectSubtitle =
      'nomination.urban_select_subtitle';
  static const String nominationPanchayatSelectTitle =
      'nomination.panchayat_select_title';
  static const String nominationPanchayatSelectSubtitle =
      'nomination.panchayat_select_subtitle';
  static const String nominationMahapaur = 'nomination.posts.mahapaur';
  static const String nominationAdhyaksh = 'nomination.posts.adhyaksh';
  static const String nominationParshad = 'nomination.posts.parshad';
  static const String nominationDistrictPanchayatMember =
      'nomination.posts.district_panchayat_member';
  static const String nominationJanpadPanchayatMember =
      'nomination.posts.janpad_panchayat_member';
  static const String nominationSarpanch = 'nomination.posts.sarpanch';
  static const String nominationWorkflowTitle = 'nomination.workflow_title';
  static const String nominationElectionType = 'nomination.election_type';
  static const String nominationFieldElection = 'nomination.field_election';
  static const String nominationSelectElectionHint =
      'nomination.select_election_hint';
  static const String nominationNoPostsFound = 'nomination.no_posts_found';
  static const String nominationPost = 'nomination.post';
  static const String nominationAreaSelection =
      'nomination.steps.area_selection';
  static const String nominationCandidateDetails =
      'nomination.steps.candidate_details';
  static const String nominationAddress = 'nomination.steps.address';
  static const String nominationElectionSummary =
      'nomination.steps.election_summary';
  static const String nominationDocumentUpload =
      'nomination.steps.document_upload';
  static const String nominationPreview = 'nomination.steps.preview';
  static const String nominationDeclaration = 'nomination.steps.declaration';
  static const String nominationSuccess = 'nomination.steps.success';
  static const String nominationFieldDistrict = 'nomination.fields.district';
  static const String nominationFieldBodyType = 'nomination.fields.body_type';
  static const String nominationFieldUbName = 'nomination.fields.ub_name';
  static const String nominationFieldJanpadPanchayat =
      'nomination.fields.janpad_panchayat';
  static const String nominationFieldGramPanchayat =
      'nomination.fields.gram_panchayat';
  static const String nominationFieldWard = 'nomination.fields.ward';
  static const String nominationFieldFullName = 'nomination.fields.full_name';
  static const String nominationFieldParentName =
      'nomination.fields.parent_name';
  static const String nominationFieldDob = 'nomination.fields.dob';
  static const String nominationFieldGender = 'nomination.fields.gender';
  static const String nominationFieldMobile = 'nomination.fields.mobile';
  static const String nominationFieldEmail = 'nomination.fields.email';
  static const String nominationFieldAddressLine =
      'nomination.fields.address_line';
  static const String nominationFieldPincode = 'nomination.fields.pincode';
  static const String nominationOptionMale = 'nomination.options.male';
  static const String nominationOptionFemale = 'nomination.options.female';
  static const String nominationOptionOther = 'nomination.options.other';
  static const String nominationOptionGeneral = 'nomination.options.general';
  static const String nominationOptionSc = 'nomination.options.sc';
  static const String nominationOptionSt = 'nomination.options.st';
  static const String nominationOptionObc = 'nomination.options.obc';
  static const String nominationOptionDistrictBhopal =
      'nomination.options.district_bhopal';
  static const String nominationOptionDistrictIndore =
      'nomination.options.district_indore';
  static const String nominationOptionDistrictSagar =
      'nomination.options.district_sagar';
  static const String nominationOptionBodyNagarNigam =
      'nomination.options.body_nagar_nigam';
  static const String nominationOptionBodyNagarPalikaParishad =
      'nomination.options.body_nagar_palika_parishad';
  static const String nominationOptionBodyNagarParishad =
      'nomination.options.body_nagar_parishad';
  static const String nominationOptionMunicipalityBhopalNagarNigam =
      'nomination.options.municipality_bhopal_nagar_nigam';
  static const String nominationOptionMunicipalityBerasiaPalika =
      'nomination.options.municipality_berasia_palika';
  static const String nominationOptionMunicipalityKolarParishad =
      'nomination.options.municipality_kolar_parishad';
  static const String nominationOptionMunicipalityIndoreNagarNigam =
      'nomination.options.municipality_indore_nagar_nigam';
  static const String nominationOptionMunicipalityDepalpurPalika =
      'nomination.options.municipality_depalpur_palika';
  static const String nominationOptionMunicipalityMhowParishad =
      'nomination.options.municipality_mhow_parishad';
  static const String nominationOptionMunicipalitySagarNagarNigam =
      'nomination.options.municipality_sagar_nagar_nigam';
  static const String nominationOptionMunicipalityBinaPalika =
      'nomination.options.municipality_bina_palika';
  static const String nominationOptionMunicipalityRahatgarhParishad =
      'nomination.options.municipality_rahatgarh_parishad';
  static const String nominationOptionWard12 = 'nomination.options.ward_12';
  static const String nominationOptionWard25 = 'nomination.options.ward_25';
  static const String nominationOptionWard7 = 'nomination.options.ward_7';
  static const String nominationOptionWard4 = 'nomination.options.ward_4';
  static const String nominationOptionWard31 = 'nomination.options.ward_31';
  static const String nominationOptionWard9 = 'nomination.options.ward_9';
  static const String nominationOptionJanpadPhanda =
      'nomination.options.janpad_phanda';
  static const String nominationOptionJanpadBerasia =
      'nomination.options.janpad_berasia';
  static const String nominationOptionJanpadDepalpur =
      'nomination.options.janpad_depalpur';
  static const String nominationOptionJanpadMhow =
      'nomination.options.janpad_mhow';
  static const String nominationOptionJanpadBina =
      'nomination.options.janpad_bina';
  static const String nominationOptionJanpadRahatgarh =
      'nomination.options.janpad_rahatgarh';
  static const String nominationOptionGramRatua =
      'nomination.options.gram_ratua';
  static const String nominationOptionGramIntkhedi =
      'nomination.options.gram_intkhedi';
  static const String nominationOptionGramNazirabad =
      'nomination.options.gram_nazirabad';
  static const String nominationOptionGramDongargaon =
      'nomination.options.gram_dongargaon';
  static const String nominationOptionGramGautampura =
      'nomination.options.gram_gautampura';
  static const String nominationOptionGramBetma =
      'nomination.options.gram_betma';
  static const String nominationOptionGramManpur =
      'nomination.options.gram_manpur';
  static const String nominationOptionGramChoral =
      'nomination.options.gram_choral';
  static const String nominationOptionGramKhurai =
      'nomination.options.gram_khurai';
  static const String nominationOptionGramBanagra =
      'nomination.options.gram_banagra';
  static const String nominationOptionGramRehli =
      'nomination.options.gram_rehli';
  static const String nominationOptionGramGarhakota =
      'nomination.options.gram_garhakota';
  static const String nominationNext = 'nomination.actions.next';
  static const String nominationPrevious = 'nomination.actions.previous';
  static const String nominationUpload = 'nomination.actions.upload';
  static const String nominationEdit = 'nomination.actions.edit';
  static const String nominationSubmitAction = 'nomination.actions.submit';
  static const String nominationShare = 'nomination.actions.share';
  static const String nominationPrint = 'nomination.actions.print';
  static const String nominationBackHome = 'nomination.actions.back_home';
  static const String nominationDeclarationText = 'nomination.declaration_text';
  static const String nominationDocumentsTitle = 'nomination.documents.title';
  static const String nominationDocumentPhoto = 'nomination.documents.photo';
  static const String nominationDocumentIdProof =
      'nomination.documents.id_proof';
  static const String nominationDocumentAddressProof =
      'nomination.documents.address_proof';
  static const String nominationDocumentAffidavit =
      'nomination.documents.affidavit';
  static const String nominationDocumentCaste = 'nomination.documents.caste';
  static const String nominationDocumentNoc = 'nomination.documents.noc';
  static const String nominationDocumentFileHint =
      'nomination.documents.file_hint';
  static const String nominationAllDocumentsUploaded =
      'nomination.documents.all_uploaded';
  static const String nominationSuccessTitle = 'nomination.success_title';
  static const String nominationSuccessSubtitle = 'nomination.success_subtitle';
  static const String nominationSuccessConfirmation =
      'nomination.success_confirmation';
  static const String nominationSubmittedDate = 'nomination.submitted_date';
  static const String nominationStatusLabel = 'nomination.status_label';
  static const String nominationApplicationNumber =
      'nomination.application_number';
  static const String nominationReceiptTitle = 'nomination.receipt_title';
  static const String nominationReceiptSubtitle = 'nomination.receipt_subtitle';
  static const String nominationTrackTitle = 'nomination.track_title';
  static const String nominationTrackSubtitle = 'nomination.track_subtitle';
  static const String nominationStatusSubmitted = 'nomination.status.submitted';
  static const String nominationStatusVerification =
      'nomination.status.verification';
  static const String nominationStatusScrutiny = 'nomination.status.scrutiny';
  static const String nominationStatusFinalList =
      'nomination.status.final_list';
  static const String nominationStatusInProgress =
      'nomination.status.in_progress';
  static const String nominationStatusDone = 'nomination.status.done';
  static const String nominationStatusQueued = 'nomination.status.queued';
  static const String nominationValidationRequired =
      'nomination.validation.required';
  static const String nominationValidationMobile =
      'nomination.validation.mobile';
  static const String nominationValidationEmail = 'nomination.validation.email';
  static const String nominationValidationPincode =
      'nomination.validation.pincode';
  static const String nominationValidationAadhaar =
      'nomination.validation.aadhaar';
  static const String nominationValidationVoterId =
      'nomination.validation.voter_id';
  static const String nominationValidationDob = 'nomination.validation.dob';
  static const String nominationValidationAgeMin =
      'nomination.validation.age_min';
  static const String nominationValidationDropdown =
      'nomination.validation.dropdown';
  static const String nominationValidationDocuments =
      'nomination.validation.documents';
  static const String nominationValidationDeclaration =
      'nomination.validation.declaration';
  static const String nominationFieldAadhaar = 'nomination.fields.aadhaar';
  static const String nominationFieldVoterId = 'nomination.fields.voter_id';
  static const String nominationFieldCategory = 'nomination.fields.category';
  static const String nominationFeatureSecurityTitle =
      'nomination.features.security_title';
  static const String nominationFeatureSecurityDesc =
      'nomination.features.security_desc';
  static const String nominationFeatureTransparencyTitle =
      'nomination.features.transparency_title';
  static const String nominationFeatureTransparencyDesc =
      'nomination.features.transparency_desc';
  static const String nominationTimelineOfficer = 'nomination.timeline.officer';
  static const String nominationTimelineRemarks = 'nomination.timeline.remarks';
  static const String nominationActionCopyId = 'nomination.actions.copy_id';
  static const String nominationActionStart = 'nomination.actions.start';
  static const String nominationEntryTitle = 'nomination.entry.title';
  static const String nominationEntrySubtitle = 'nomination.entry.subtitle';
  static const String nominationEntryLoginTitle =
      'nomination.entry.login_title';
  static const String nominationEntryLoginSubtitle =
      'nomination.entry.login_subtitle';
  static const String nominationEntryRegisterTitle =
      'nomination.entry.register_title';
  static const String nominationEntryRegisterSubtitle =
      'nomination.entry.register_subtitle';
  static const String nominationDraftResumeTitle =
      'nomination.draft.resume_title';
  static const String nominationDraftResumeSubtitle =
      'nomination.draft.resume_subtitle';
  static const String nominationDraftContinue = 'nomination.draft.continue';
  static const String nominationDraftStartFresh =
      'nomination.draft.start_fresh';
  static const String nominationActionSave = 'nomination.actions.save';
  static const String nominationActionReplace = 'nomination.actions.replace';
  static const String nominationActionRetry = 'nomination.actions.retry';
  static const String nominationPreviewPersonalInfo =
      'nomination.preview.personal_info';
  static const String nominationPreviewElectionInfo =
      'nomination.preview.election_info';
  static const String nominationPreviewDocumentsInfo =
      'nomination.preview.documents_info';
  static const String nominationStatusReceived = 'nomination.status.received';
  static const String nominationStatusPending = 'nomination.status.pending';
  static const String nominationCopiedId = 'nomination.copied_id';
  static const String nominationDigitalReceipt = 'nomination.digital_receipt';

  // Presiding officer (mpsec_presiding_concern)
  static const String presidingOfficerTitle = 'presiding.officer_title';
  static const String presidingPollingStation = 'presiding.polling_station';
  static const String presidingEnterInfo = 'presiding.enter_info';
  static const String presidingSectionArrival = 'presiding.section_arrival';
  static const String presidingSectionPrePoll = 'presiding.section_pre_poll';
  static const String presidingSectionDuringPoll =
      'presiding.section_during_poll';
  static const String presidingSectionPostPoll = 'presiding.section_post_poll';
  static const String presidingMale = 'presiding.male';
  static const String presidingFemale = 'presiding.female';
  static const String presidingThirdGender = 'presiding.third_gender';
  static const String presidingBack = 'presiding.back';
  static const String presidingFinishAndBack = 'presiding.finish_and_back';
  static const String presidingSavedAt = 'presiding.saved_at';
  static const String presidingMarkComplete = 'presiding.mark_complete';
  static const String presidingReachStationFirst =
      'presiding.reach_station_first';
  static const String presidingPollStartBefore7Am =
      'presiding.poll_start_before_7am';
  static const String presidingMockPollBefore7Am =
      'presiding.mock_poll_before_7am';
  static const String presidingMockPollNextDay = 'presiding.mock_poll_next_day';
  static const String presidingAlreadyRegistered =
      'presiding.already_registered';
  static const String presidingSyncRefresh = 'presiding.sync_refresh';
  static const String presidingSyncSuccess = 'presiding.sync_success';
  static const String presidingSyncFailed = 'presiding.sync_failed';
  static const String presidingSyncOffline = 'presiding.sync_offline';
  static const String presidingOnline = 'presiding.online';
  static const String presidingOffline = 'presiding.offline';
  static const String presidingLivePollTitle = 'presiding.live_poll_title';
  static const String presidingLatestTurnoutStatus =
      'presiding.latest_turnout_status';
  static const String presidingPollingStationNumber =
      'presiding.polling_station_number';
  static const String presidingServerUpdateTime =
      'presiding.server_update_time';
  static const String presidingServerConnection = 'presiding.server_connection';
  static const String presidingTotalVotes = 'presiding.total_votes';
  static const String presidingTotalPercent = 'presiding.total_percent';
  static const String presidingTurnoutIntroTitle =
      'presiding.turnout_intro_title';
  static const String presidingTurnoutIntroSubtitle =
      'presiding.turnout_intro_subtitle';
  static const String presidingAutoSaved = 'presiding.auto_saved';
  static const String presidingVoterTurnout = 'presiding.voter_turnout';
  static const String presidingCurrentQueueCount =
      'presiding.current_queue_count';
  static const String presidingQueueHint = 'presiding.queue_hint';
  static const String presidingEnterNumber = 'presiding.enter_number';
  static const String presidingQueueSummary = 'presiding.queue_summary';
  static const String presidingTotalVotesSummary =
      'presiding.total_votes_summary';
  static const String presidingSaveFailed = 'presiding.save_failed';
  static const String presidingUpdateFailed = 'presiding.update_failed';
  static const String presidingCountCannotBeNegative =
      'presiding.count_cannot_be_negative';
  static const String presidingCountMaxFourDigits =
      'presiding.count_max_four_digits';
  static const String presidingCountExceedsElectors =
      'presiding.count_exceeds_electors';
  static const String presidingCountNotLessThanPrevious =
      'presiding.count_not_less_than_previous';
  static const String presidingCountCompletionBelowLastPlusQueue =
      'presiding.count_completion_below_last_plus_queue';
  static const String presidingCountCompletionAboveLastPlusQueue =
      'presiding.count_completion_above_last_plus_queue';
  static const String presidingCountLastPlusQueueExceedsCompletion =
      'presiding.count_last_plus_queue_exceeds_completion';
  static const String presidingFill5PmBeforeNext =
      'presiding.fill_5pm_before_next';
  static const String presidingFill3PmBeforeNext =
      'presiding.fill_3pm_before_next';
  static const String presidingEarlierSlotLocked =
      'presiding.earlier_slot_locked';
  static const String presidingReportTitle = 'presiding.report_title';
  static const String presidingReportSubtitle = 'presiding.report_subtitle';
  static const String presidingReportMilestones = 'presiding.report_milestones';
  static const String presidingReportTurnout = 'presiding.report_turnout';
  static const String presidingReportShare = 'presiding.report_share';
  static const String presidingReportPrint = 'presiding.report_print';
  static const String presidingReportFooter = 'presiding.report_footer';
  static const String presidingReportFailed = 'presiding.report_failed';
  static const String presidingReportPoName = 'presiding.report_po_name';
  static const String presidingReportPoMobile = 'presiding.report_po_mobile';
  static const String presidingReportStation = 'presiding.report_station';
  static const String presidingReportArea = 'presiding.report_area';
  static const String presidingReportElectors = 'presiding.report_electors';
  static const String presidingReportGenerated = 'presiding.report_generated';
  static const String presidingReportUrban = 'presiding.report_urban';
  static const String presidingReportRural = 'presiding.report_rural';
  static const String presidingReportStep = 'presiding.report_step';
  static const String presidingReportStatus = 'presiding.report_status';
  static const String presidingReportTime = 'presiding.report_time';
  static const String presidingReportDone = 'presiding.report_done';
  static const String presidingReportPending = 'presiding.report_pending';
  static const String presidingReportSlot = 'presiding.report_slot';
  static const String presidingReportColTotal = 'presiding.report_col_total';
  static const String presidingGenerateReport = 'presiding.generate_report';
  static const String presidingGenerateReportLocked =
      'presiding.generate_report_locked';
  static const String presidingBoothPollingStation =
      'presiding.booth_polling_station';
  static const String presidingBoothLocationTitle =
      'presiding.booth_location_title';
  static const String presidingBoothNoCoords = 'presiding.booth_no_coords';
  static const String presidingBoothCurrentLocation =
      'presiding.booth_current_location';
  static const String presidingBoothNavigate = 'presiding.booth_navigate';
  static const String presidingBoothOpenMap = 'presiding.booth_open_map';
  static const String presidingBoothMapError = 'presiding.booth_map_error';
  static const String presidingPartyTitle = 'presiding.party_title';
  static const String presidingPartySubtitle = 'presiding.party_subtitle';
  static const String presidingPartyNo = 'presiding.party_no';
  static const String presidingPartyMemberP1 = 'presiding.party_member_p1';
  static const String presidingPartyMemberP2 = 'presiding.party_member_p2';
  static const String presidingPartyMemberP3 = 'presiding.party_member_p3';
  static const String presidingPartyMemberP4 = 'presiding.party_member_p4';
  static const String presidingPartyName = 'presiding.party_name';
  static const String presidingPartyMobile = 'presiding.party_mobile';
  static const String presidingPartySaveContinue =
      'presiding.party_save_continue';
  static const String presidingPartyUpdate = 'presiding.party_update';
  static const String presidingPartyP1NameRequired =
      'presiding.party_p1_name_required';
  static const String presidingPartyP1MobileRequired =
      'presiding.party_p1_mobile_required';
  static const String presidingPartyMobileInvalid =
      'presiding.party_mobile_invalid';
  static const String presidingPartySessionMissing =
      'presiding.party_session_missing';
  static const String presidingPartyLoadFailed = 'presiding.party_load_failed';
  static const String presidingPartySaveFailed = 'presiding.party_save_failed';
  static const String presidingPartyApiNotDeployed =
      'presiding.party_api_not_deployed';
  static const String presidingPartyMandatoryTitle =
      'presiding.party_mandatory_title';
  static const String presidingPartyMandatoryBanner =
      'presiding.party_mandatory_banner';
  static const String presidingPartyFilledBanner =
      'presiding.party_filled_banner';
  static const String presidingPartyRequiredMessage =
      'presiding.party_required_message';
  static const String presidingPartyFillNow = 'presiding.party_fill_now';
  static const String presidingPartyFillButton = 'presiding.party_fill_button';
  static const String presidingPartyOtpTitle = 'presiding.party_otp_title';
  static const String presidingPartyOtpSubtitle =
      'presiding.party_otp_subtitle';
  static const String presidingPartyOtpHint = 'presiding.party_otp_hint';
  static const String presidingPartyOtpRequired =
      'presiding.party_otp_required';
  static const String presidingPartyOtpInvalid = 'presiding.party_otp_invalid';
  static const String presidingPartyOtpVerify = 'presiding.party_otp_verify';
  static const String presidingPartyOtpResend = 'presiding.party_otp_resend';
  static const String presidingPartyOtpSendFailed =
      'presiding.party_otp_send_failed';
  static const String presidingPartyOtpSent = 'presiding.party_otp_sent';
  static const String presidingPartyOtpResent = 'presiding.party_otp_resent';

  static const String presidingPoDetailsTitle = 'presiding.po_details_title';
  static const String presidingPoDetailsSubtitle =
      'presiding.po_details_subtitle';
  static const String presidingPoDetailsName = 'presiding.po_details_name';
  static const String presidingPoDetailsNameHint =
      'presiding.po_details_name_hint';
  static const String presidingPoDetailsMobile = 'presiding.po_details_mobile';
  static const String presidingPoDetailsMobileHint =
      'presiding.po_details_mobile_hint';
  static const String presidingPoDetailsNameRequired =
      'presiding.po_details_name_required';
  static const String presidingPoDetailsMobileRequired =
      'presiding.po_details_mobile_required';
  static const String presidingPoDetailsMobileInvalid =
      'presiding.po_details_mobile_invalid';
  static const String presidingPoDetailsSendOtp =
      'presiding.po_details_send_otp';
  static const String presidingPoDetailsResendOtp =
      'presiding.po_details_resend_otp';
  static const String presidingPoDetailsVerify = 'presiding.po_details_verify';
  static const String presidingPoDetailsContinue =
      'presiding.po_details_continue';
  static const String presidingPoDetailsOtpLabel =
      'presiding.po_details_otp_label';
  static const String presidingPoDetailsOtpHint =
      'presiding.po_details_otp_hint';
  static const String presidingPoDetailsOtpSubtitle =
      'presiding.po_details_otp_subtitle';
  static const String presidingPoDetailsOtpRequired =
      'presiding.po_details_otp_required';
  static const String presidingPoDetailsOtpSendFailed =
      'presiding.po_details_otp_send_failed';
  static const String presidingPoDetailsOtpSent =
      'presiding.po_details_otp_sent';
  static const String presidingPoDetailsOtpResent =
      'presiding.po_details_otp_resent';
  static const String presidingPoDetailsMobileChanged =
      'presiding.po_details_mobile_changed';
  static const String presidingPoDetailsNameChanged =
      'presiding.po_details_name_changed';
  static const String presidingPoDetailsSessionMissing =
      'presiding.po_details_session_missing';
  static const String presidingPoDetailsSessionExpired =
      'presiding.po_details_session_expired';
  static const String presidingPoDetailsLoadFailed =
      'presiding.po_details_load_failed';
  static const String presidingPoDetailsSaveFailed =
      'presiding.po_details_save_failed';
  static const String presidingPoDetailsAlreadySaved =
      'presiding.po_details_already_saved';
  static const String presidingSaveFailedGeneric =
      'presiding.save_failed_generic';
  static const String presidingSessionExpired = 'presiding.session_expired';
  static const String presidingMobileRequired = 'presiding.mobile_required';
  static const String presidingCollapse = 'presiding.collapse';
  static const String presidingExpand = 'presiding.expand';

  // WebView
  static const String webviewLoadFailedSubtitle =
      'webview.load_failed_subtitle';
  static const String webviewErrorNetworkTitle = 'webview.error_network_title';
  static const String webviewErrorNetworkSub = 'webview.error_network_sub';
  static const String webviewErrorHttpTitle = 'webview.error_http_title';
  static const String webviewErrorHttpSub = 'webview.error_http_sub';
  static const String webviewErrorSslTitle = 'webview.error_ssl_title';
  static const String webviewErrorSslSub = 'webview.error_ssl_sub';
  static const String webviewErrorTimeoutTitle = 'webview.error_timeout_title';
  static const String webviewErrorTimeoutSub = 'webview.error_timeout_sub';
  static const String webviewErrorDnsTitle = 'webview.error_dns_title';
  static const String webviewErrorDnsSub = 'webview.error_dns_sub';
  static const String webviewErrorGenericTitle = 'webview.error_generic_title';
  static const String webviewErrorGenericSub = 'webview.error_generic_sub';
  static const String webviewErrorDetailsLabel = 'webview.error_details_label';
  static const String webviewErrorGoBack = 'webview.error_go_back';

  // Offline hub
  static const String offlineHubTitle = 'offline_hub.title';
  static const String offlineHubHeadline = 'offline_hub.headline';
  static const String offlineHubSubtitle = 'offline_hub.subtitle';
  static const String offlineHubDescription = 'offline_hub.description';
  static const String offlineHubConnection = 'offline_hub.connection';
  static const String offlineHubOnline = 'offline_hub.online';
  static const String offlineHubOffline = 'offline_hub.offline';
  static const String offlineHubRecordsWaiting = 'offline_hub.records_waiting';
  static const String offlineHubLastSync = 'offline_hub.last_sync';
  static const String offlineHubStorageUsed = 'offline_hub.storage_used';
  static const String offlineHubStorageMb = 'offline_hub.storage_mb';
  static const String offlineHubContinueOffline =
      'offline_hub.continue_offline';
  static const String offlineHubRetryConnection =
      'offline_hub.retry_connection';
  static const String offlineHubSyncWhenOnline = 'offline_hub.sync_when_online';
  static const String offlineHubSyncProgress = 'offline_hub.sync_progress';
  static const String offlineHubPendingSurveys = 'offline_hub.pending_surveys';
  static const String offlineHubPendingImages = 'offline_hub.pending_images';
  static const String offlineHubPendingVideos = 'offline_hub.pending_videos';
  static const String offlineHubPendingGps = 'offline_hub.pending_gps';
  static const String offlineHubPendingSignatures =
      'offline_hub.pending_signatures';
  static const String offlineHubTips = 'offline_hub.tips';
  static const String offlineHubTipGps = 'offline_hub.tip_gps';
  static const String offlineHubTipUninstall = 'offline_hub.tip_uninstall';
  static const String offlineHubTipEncrypted = 'offline_hub.tip_encrypted';
  static const String offlineHubTipAutoSync = 'offline_hub.tip_auto_sync';
  static const String offlineHubBanner = 'offline_hub.banner';
  static const String offlineHubBlockedService = 'offline_hub.blocked_service';

  // Menu
  static const String menuDashboard = 'menu.dashboard';
  static const String menuMasterStockRegister = 'menu.master_stock_register';
  static const String menuControlUnit = 'menu.control_unit';
  static const String menuBallotUnit = 'menu.ballot_unit';
  static const String menuScanner = 'menu.scanner';
  static const String menuReports = 'menu.reports';
  static const String menuNotifications = 'menu.notifications';
  static const String menuAuditTrail = 'menu.audit_trail';
  static const String menuSyncManagement = 'menu.sync_management';
  static const String menuSearch = 'menu.search';
  static const String menuProfile = 'menu.profile';
  static const String menuSettings = 'menu.settings';
  static const String menuHelpSupport = 'menu.help_support';
  static const String menuAbout = 'menu.about';

  // Splash
  static const String splashLoading = 'splash.loading';
}
