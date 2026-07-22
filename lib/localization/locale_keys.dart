/// Centralized, type-safe localization keys.
abstract final class LocaleKeys {
  // App
  static const String appName = 'app.name';
  static const String appTagline = 'app.tagline';
  static const String appFullName = 'app.full_name';
  static const String appSystem = 'app.system';
  static const String appNicCertified = 'app.nic_certified';
  static const String appSecure = 'app.secure';
  static const String appSmart = 'app.smart';
  static const String appTransparent = 'app.transparent';
  static const String appVersion = 'app.version';
  static const String appCopyright = 'app.copyright';

  // Common
  static const String commonOk = 'common.ok';
  static const String commonCancel = 'common.cancel';
  static const String commonRetry = 'common.retry';
  static const String commonSave = 'common.save';
  static const String commonSaved = 'common.saved';
  static const String commonSubmit = 'common.submit';
  static const String commonSearch = 'common.search';
  static const String commonLoading = 'common.loading';
  static const String commonNoData = 'common.no_data';
  static const String commonSomethingWentWrong = 'common.something_went_wrong';
  static const String commonNoInternet = 'common.no_internet';
  static const String commonLogout = 'common.logout';
  static const String commonYes = 'common.yes';
  static const String commonNo = 'common.no';
  static const String commonConfirm = 'common.confirm';
  static const String commonBack = 'common.back';
  static const String commonSkip = 'common.skip';
  static const String commonContinue = 'common.continue';
  static const String commonGetStarted = 'common.get_started';
  static const String commonForgot = 'common.forgot';
  static const String commonExport = 'common.export';
  static const String commonJustNow = 'common.just_now';
  static const String commonSaving = 'common.saving';
  static const String commonMenu = 'common.menu';
  static const String commonTakePhoto = 'common.take_photo';
  static const String commonChooseFromGallery = 'common.choose_from_gallery';
  static const String commonPickImageSource = 'common.pick_image_source';

  // Error
  static const String errorNetwork = 'error.network';
  static const String errorServer = 'error.server';
  static const String errorUnauthorized = 'error.unauthorized';
  static const String errorForbidden = 'error.forbidden';
  static const String errorNotFound = 'error.not_found';
  static const String errorValidation = 'error.validation';
  static const String errorUnknown = 'error.unknown';

  // Auth
  static const String authLoginTitle = 'auth.login_title';
  static const String authLoginSubtitle = 'auth.login_subtitle';
  static const String authUsername = 'auth.username';
  static const String authUsernameHint = 'auth.username_hint';
  static const String authPassword = 'auth.password';
  static const String authPasswordHint = 'auth.password_hint';
  static const String authLoginButton = 'auth.login_button';
  static const String authBiometricButton = 'auth.biometric_button';
  static const String authBiometricReason = 'auth.biometric_reason';
  static const String authInvalidCredentials = 'auth.invalid_credentials';
  static const String authPoInvalidCredentials = 'auth.po_invalid_credentials';
  static const String authDistrictInvalidCredentials =
      'auth.district_invalid_credentials';
  static const String authSessionExpired = 'auth.session_expired';
  static const String authUsernameRequired = 'auth.username_required';
  static const String authPasswordRequired = 'auth.password_required';
  static const String authPasswordTooShort = 'auth.password_too_short';
  static const String authAuthorisedOnly = 'auth.authorised_only';
  static const String authDistrict = 'auth.district';
  static const String authRememberMe = 'auth.remember_me';
  static const String authTrustNic = 'auth.trust.nic';
  static const String authTrustGovt = 'auth.trust.govt';
  static const String authTrustEncrypted = 'auth.trust.encrypted';

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

  // Registration
  static const String regControlUnit = 'registration.control_unit';
  static const String regBallotUnit = 'registration.ballot_unit';
  static const String regRegisterCu = 'registration.register_cu';
  static const String regRegisterBu = 'registration.register_bu';
  static const String regInventory = 'registration.inventory';
  static const String regReports = 'registration.reports';
  static const String regSyncData = 'registration.sync_data';
  static const String regAuditTrail = 'registration.audit_trail';
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
  static const String dashboardTitle = 'dashboard.title';
  static const String dashboardWelcome = 'dashboard.welcome';
  static const String dashboardTotalControlUnits =
      'dashboard.total_control_units';
  static const String dashboardTotalBallotUnits =
      'dashboard.total_ballot_units';
  static const String dashboardPendingSync = 'dashboard.pending_sync';
  static const String dashboardScannedToday = 'dashboard.scanned_today';
  static const String dashboardInventoryOverview =
      'dashboard.inventory_overview';
  static const String dashboardRecentActivity = 'dashboard.recent_activity';
  static const String dashboardQuickActions = 'dashboard.quick_actions';
  static const String dashboardBrandTitle = 'dashboard.brand_title';
  static const String dashboardBrandSubtitle = 'dashboard.brand_subtitle';
  static const String dashboardGreeting = 'dashboard.greeting';
  static const String dashboardGuest = 'dashboard.guest';
  static const String dashboardRole = 'dashboard.role';
  static const String dashboardDistrictUnset = 'dashboard.district_unset';
  static const String dashboardStatusActive = 'dashboard.status_active';
  static const String dashboardMainServices = 'dashboard.main_services';
  static const String dashboardViewAll = 'dashboard.view_all';
  static const String dashboardStatObservers = 'dashboard.stat_observers';
  static const String dashboardStatExpenditure = 'dashboard.stat_expenditure';
  static const String dashboardStatInspections = 'dashboard.stat_inspections';
  static const String dashboardStatEms = 'dashboard.stat_ems';
  static const String dashboardStatSurveysTotal = 'dashboard.stat_surveys_total';
  static const String dashboardStatSurveysToday = 'dashboard.stat_surveys_today';
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
  static const String dashboardActInspection = 'dashboard.act_inspection';
  static const String dashboardActExpenditure = 'dashboard.act_expenditure';
  static const String dashboardActBooth = 'dashboard.act_booth';
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
  static const String profileSettingsSub = 'profile.settings_sub';
  static const String profileAudit = 'profile.audit';
  static const String profileAuditSub = 'profile.audit_sub';
  static const String profileSync = 'profile.sync';
  static const String profileSyncSub = 'profile.sync_sub';
  static const String profileSearch = 'profile.search';
  static const String profileSearchSub = 'profile.search_sub';
  static const String profileNotifications = 'profile.notifications';
  static const String profileNotificationsSub = 'profile.notifications_sub';
  static const String profileChangePassword = 'profile.change_password';
  static const String profileLastChanged = 'profile.last_changed';
  static const String profileSignOut = 'profile.sign_out';
  static const String profileSignOutTitle = 'profile.sign_out_title';
  static const String profileSignOutMessage = 'profile.sign_out_message';
  static const String profileThisWeek = 'profile.this_week';
  static const String profileRegisteredBy = 'profile.registered_by';
  static const String profileTimeline = 'profile.timeline';
  static const String profileAccount = 'profile.account';
  static const String profileServices = 'profile.services';
  static const String profileDetails = 'profile.details';
  static const String profileOfficerId = 'profile.officer_id';
  static const String profileUserId = 'profile.user_id';
  static const String profileSection = 'profile.section';
  static const String profileDistrict = 'profile.district';
  static const String profileBody = 'profile.body';
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
  static const String settingsDarkModeSub = 'settings.dark_mode_sub';
  static const String settingsLanguage = 'settings.language';
  static const String settingsEnglish = 'settings.english';
  static const String settingsHindi = 'settings.hindi';
  static const String settingsTheme = 'settings.theme';
  static const String settingsLightMode = 'settings.light_mode';
  static const String settingsSecurity = 'settings.security';
  static const String settingsBiometricAuth = 'settings.biometric_auth';
  static const String settingsBiometricSub = 'settings.biometric_sub';
  static const String settingsUpdatePassword = 'settings.update_password';
  static const String settingsLoginHistory = 'settings.login_history';
  static const String settingsViewRecentLogins = 'settings.view_recent_logins';
  static const String settingsPushAlerts = 'settings.push_alerts';
  static const String settingsPushAlertsSub = 'settings.push_alerts_sub';
  static const String settingsSoundEffects = 'settings.sound_effects';
  static const String settingsSoundEffectsSub = 'settings.sound_effects_sub';
  static const String settingsDataSync = 'settings.data_sync';
  static const String settingsAutoSync = 'settings.auto_sync';
  static const String settingsAutoSyncSub = 'settings.auto_sync_sub';
  static const String settingsOfflineStorage = 'settings.offline_storage';
  static const String settingsRecordsStored = 'settings.records_stored';
  static const String settingsExportData = 'settings.export_data';
  static const String settingsExportDataSub = 'settings.export_data_sub';
  static const String settingsPrivacy = 'settings.privacy';
  static const String settingsPrivacySub = 'settings.privacy_sub';

  // Device Detail
  static const String detailTitle = 'detail.title';
  static const String detailBoxNo = 'detail.box_no';
  static const String detailDistrict = 'detail.district';
  static const String detailMfrYear = 'detail.mfr_year';
  static const String detailNotFound = 'detail.not_found';
  static const String detailNotFoundSub = 'detail.not_found_sub';

  // Search
  static const String searchTitle = 'search.title';
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
  static const String notificationsEmpty = 'notifications.empty';
  static const String notificationsEmptySub = 'notifications.empty_sub';

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
  static const String reportsDeviceStatus = 'reports.device_status';
  static const String reportsSurveyStatus = 'reports.survey_status';
  static const String reportsSurveyList = 'reports.survey_list';
  static const String reportsRefId = 'reports.ref_id';
  static const String reportsUrban = 'reports.urban';
  static const String reportsRural = 'reports.rural';
  static const String reportsUnknownArea = 'reports.unknown_area';
  static const String reportsByAreaType = 'reports.by_area_type';
  static const String reportsDetailTitle = 'reports.detail_title';
  static const String reportsDetailSub = 'reports.detail_sub';
  static const String reportsDistrictMeta = 'reports.district_meta';
  static const String reportsPollingStations = 'reports.polling_stations';
  static const String reportsSurveyCount = 'reports.survey_count';
  static const String reportsByDistrict = 'reports.by_district';
  static const String reportsByFormType = 'reports.by_form_type';
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
  static const String timeYesterday = 'time.yesterday';

  // Services
  static const String serviceObserverTitle = 'services.observer.title';
  static const String serviceObserverDesc = 'services.observer.desc';
  static const String serviceExpenditureTitle = 'services.expenditure.title';
  static const String serviceExpenditureDesc = 'services.expenditure.desc';

  static const String serviceVoterTitle = 'services.voter.title';
  static const String serviceVoterDesc = 'services.voter.desc';
  static const String serviceVoterSearchEngineTitle =
      'services.voter_search_engine.title';
  static const String serviceVoterSearchEngineDesc =
      'services.voter_search_engine.desc';
  static const String serviceEmsTitle = 'services.ems.title';
  static const String serviceEmsDesc = 'services.ems.desc';
  static const String serviceBoothTitle = 'services.booth.title';
  static const String serviceBoothDesc = 'services.booth.desc';
  static const String servicePresidingTitle = 'services.presiding.title';
  static const String servicePresidingDesc = 'services.presiding.desc';
  static const String serviceReportsTitle = 'services.reports.title';
  static const String serviceReportsDesc = 'services.reports.desc';
  static const String serviceComplaintsTitle = 'services.complaints.title';
  static const String serviceComplaintsDesc = 'services.complaints.desc';
  static const String serviceGuidelinesTitle = 'services.guidelines.title';
  static const String serviceGuidelinesDesc = 'services.guidelines.desc';
  static const String serviceOnlineNominationTitle =
      'services.online_nomination.title';
  static const String serviceOnlineNominationDesc =
      'services.online_nomination.desc';

  // Online nomination
  static const String nominationTitle = 'nomination.title';
  static const String nominationSubtitle = 'nomination.subtitle';
  static const String nominationApplyOnline = 'nomination.apply_online';
  static const String nominationTrackStatusCta = 'nomination.track_status_cta';
  static const String nominationHeaderDepartment =
      'nomination.header_department';
  static const String nominationWelcomeTitle = 'nomination.welcome_title';
  static const String nominationWelcomeSubtitle = 'nomination.welcome_subtitle';
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
  static const String nominationWorkflowSubtitle =
      'nomination.workflow_subtitle';
  static const String nominationElectionType = 'nomination.election_type';
  static const String nominationFieldElection = 'nomination.field_election';
  static const String nominationSelectElectionHint =
      'nomination.select_election_hint';
  static const String nominationNoPostsFound = 'nomination.no_posts_found';
  static const String nominationMastersLoading = 'nomination.masters_loading';
  static const String nominationMastersEmpty = 'nomination.masters_empty';
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
  static const String nominationSubmit = 'nomination.steps.submit';
  static const String nominationSuccess = 'nomination.steps.success';
  static const String nominationReceipt = 'nomination.steps.receipt';
  static const String nominationTrack = 'nomination.steps.track_status';
  static const String nominationFieldState = 'nomination.fields.state';
  static const String nominationFieldDistrict = 'nomination.fields.district';
  static const String nominationFieldMunicipality =
      'nomination.fields.municipality';
  static const String nominationFieldNagarNigam =
      'nomination.fields.nagar_nigam';
  static const String nominationFieldBodyType = 'nomination.fields.body_type';
  static const String nominationFieldUbName = 'nomination.fields.ub_name';
  static const String nominationFieldUrbanBody = 'nomination.fields.urban_body';
  static const String nominationFieldJanpadPanchayat =
      'nomination.fields.janpad_panchayat';
  static const String nominationFieldGramPanchayat =
      'nomination.fields.gram_panchayat';
  static const String nominationFieldWard = 'nomination.fields.ward';
  static const String nominationFieldReservation =
      'nomination.fields.reservation';
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
  static const String nominationOptionWomen = 'nomination.options.women';
  static const String nominationOptionStateMp = 'nomination.options.state_mp';
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
  static const String nominationDownloadReceipt =
      'nomination.actions.download_receipt';
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
  static const String nominationFeatureSpeedTitle =
      'nomination.features.speed_title';
  static const String nominationFeatureSpeedDesc =
      'nomination.features.speed_desc';
  static const String nominationTimelineOfficer = 'nomination.timeline.officer';
  static const String nominationTimelineRemarks = 'nomination.timeline.remarks';
  static const String nominationActionCopyId = 'nomination.actions.copy_id';
  static const String nominationActionDownloadPdf =
      'nomination.actions.download_pdf';
  static const String nominationActionStart = 'nomination.actions.start';
  static const String nominationEntryTitle = 'nomination.entry.title';
  static const String nominationEntrySubtitle = 'nomination.entry.subtitle';
  static const String nominationEntryLoginTitle = 'nomination.entry.login_title';
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
  static const String nominationActionDelete = 'nomination.actions.delete';
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
  static const String presidingDefaultStation = 'presiding.default_station';
  static const String presidingSectionArrival = 'presiding.section_arrival';
  static const String presidingSectionPrePoll = 'presiding.section_pre_poll';
  static const String presidingSectionDuringPoll =
      'presiding.section_during_poll';
  static const String presidingSectionPostPoll = 'presiding.section_post_poll';
  static const String presidingMale = 'presiding.male';
  static const String presidingFemale = 'presiding.female';
  static const String presidingThirdGender = 'presiding.third_gender';
  static const String presidingQueueCount = 'presiding.queue_count';
  static const String presidingPollCompletion = 'presiding.poll_completion';
  static const String presidingTurnoutSaved = 'presiding.turnout_saved';
  static const String presidingBack = 'presiding.back';
  static const String presidingFinishAndBack = 'presiding.finish_and_back';
  static const String presidingSlot9Am = 'presiding.slot_9am';
  static const String presidingSlot11Am = 'presiding.slot_11am';
  static const String presidingSlot1Pm = 'presiding.slot_1pm';
  static const String presidingSlot3Pm = 'presiding.slot_3pm';
  static const String presidingSlot5Pm = 'presiding.slot_5pm';
  static const String presidingNotSaved = 'presiding.not_saved';
  static const String presidingSavedAt = 'presiding.saved_at';
  static const String presidingQueueManagement = 'presiding.queue_management';
  static const String presidingTurnoutEntry = 'presiding.turnout_entry';
  static const String presidingQueueUpdateHint = 'presiding.queue_update_hint';
  static const String presidingTurnoutHint = 'presiding.turnout_hint';
  static const String presidingEnterCount = 'presiding.enter_count';
  static const String presidingMarkComplete = 'presiding.mark_complete';
  static const String presidingAlreadyRegistered =
      'presiding.already_registered';
  static const String presidingLivePollTitle = 'presiding.live_poll_title';
  static const String presidingLivePollSubtitle =
      'presiding.live_poll_subtitle';
  static const String presidingLiveBadge = 'presiding.live_badge';
  static const String presidingLatestTurnoutStatus =
      'presiding.latest_turnout_status';
  static const String presidingPollingStationNumber =
      'presiding.polling_station_number';
  static const String presidingLastUpdate = 'presiding.last_update';
  static const String presidingIncreaseByOne = 'presiding.increase_by_one';
  static const String presidingTotalVotes = 'presiding.total_votes';
  static const String presidingTurnoutSharePercent =
      'presiding.turnout_share_percent';
  static const String presidingLivePollNote = 'presiding.live_poll_note';
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
  static const String splashTitle = 'splash.title';
  static const String splashTagline = 'splash.tagline';
  static const String splashLoading = 'splash.loading';
}
