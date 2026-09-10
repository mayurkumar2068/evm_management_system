import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/navigation/external_url_launcher.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart' hide Trans;
import 'package:permission_handler/permission_handler.dart';

import '../config/webview_config.dart';
import '../url/webview_url_utils.dart';
import '../controller/app_webview_controller.dart';
import '../javascript/app_bridge_js.dart';
import '../models/web_session_context.dart';
import '../models/web_view_metrics.dart';
import '../service/webview_bridge.dart';
import '../service/web_session_service.dart';
import '../service/webview_cookie_service.dart';
import '../service/webview_warmer.dart';
import '../service/webview_logger.dart';
import '../service/webview_navigation_policy.dart';
import '../service/webview_security.dart';
import 'app_webview_header.dart';

class AppWebView extends StatefulWidget {
  const AppWebView({required this.config, this.onCreated, super.key});

  final WebViewConfig config;
  final ValueChanged<AppWebViewController>? onCreated;

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  static const WebViewNavigationPolicy _navPolicy = WebViewNavigationPolicy();
  static const ExternalUrlLauncher _externalLauncher = ExternalUrlLauncher();

  AppWebViewController? _controller;
  PullToRefreshController? _pullToRefresh;
  late final WebViewSecurity _security;
  late final WebViewLogger _logger;
  late final InAppWebViewSettings _settings;

  WebSessionContext? _session;
  bool _prepared = false;
  bool _loading = true;
  bool _error = false;
  String _errorCategory = 'load';
  String _errorMessage = '';
  double _progress = 0;
  Uint8List? _favicon;
  Uri? _lastVisitedUri;
  Uri? _lastStartedUri;
  Timer? _loadSettleTimer;
  URLRequest? _initialRequest;
  UnmodifiableListView<UserScript>? _initialUserScripts;

  WebViewConfig get _config => widget.config;

  @override
  void initState() {
    super.initState();
    _logger = Get.find<WebViewLogger>();
    _security = WebViewSecurity(
      serverTrustPolicy: _config.serverTrustPolicy,
      pinnedSha256: _config.pinnedCertificateSha256,
      allowCleartextLocalhost: _config.allowCleartextLocalhost,
      logger: _logger,
    );
    _settings = _buildSettings();
    if (_config.enablePullToRefresh) {
      _pullToRefresh = PullToRefreshController(
        settings: PullToRefreshSettings(color: AppColors.surveyPrimary),
        onRefresh: () async => _controller?.reload(),
      );
    }
    _prepare();
  }

  @override
  void dispose() {
    _loadSettleTimer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    unawaited(Get.find<WebViewWarmer>().warm());

    final WebThemeMode theme =
        AppServices.settings.themeMode.value == ThemeMode.dark
        ? WebThemeMode.dark
        : WebThemeMode.light;

    try {
      if (!_config.bootstrapSession) {
        if (!mounted) return;
        setState(() {
          _session = null;
          _initialRequest = _buildRequest();
          _initialUserScripts = UnmodifiableListView<UserScript>([]);
          _prepared = true;
        });
        return;
      }

      final WebSessionContext session = await Get.find<WebSessionService>()
          .build(theme: theme);

      final Uri parsed = _normalizedUri;
      if (_config.syncCookies &&
          (parsed.scheme == 'http' || parsed.scheme == 'https')) {
        await Get.find<WebViewCookieService>().sync(
          WebUri(parsed.toString()),
          session,
        );
      }

      if (!mounted) return;
      setState(() {
        _session = session;
        _initialRequest = _buildRequest();
        _initialUserScripts = UnmodifiableListView<UserScript>(
          _buildUserScripts(),
        );
        _prepared = true;
      });
    } catch (error) {
      _logger.logError(
        uri: _normalizedUri,
        category: 'prepare',
        description: error.toString(),
      );
      if (!mounted) return;
      setState(() {
        _prepared = true;
        _loading = false;
        _error = true;
      });
    }
  }

  Uri get _normalizedUri => Uri.parse(_normalizeUrl(_config.url));

  String _normalizeUrl(String rawUrl) => normalizeWebViewLaunchUrl(rawUrl);

  Future<void> _reload() async {
    _loadSettleTimer?.cancel();
    if (mounted) {
      setState(() {
        _error = false;
        _loading = true;
        _errorMessage = '';
        _errorCategory = 'load';
      });
    }
    final AppWebViewController? controller = _controller;
    if (controller == null) {
      await _prepare();
      return;
    }
    final URLRequest request = _buildRequest();
    await controller.loadUrl(request: request);
  }

  Future<void> _goBackOrClose() async {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  Future<void> _confirmLogout() async {
    final bool confirmed = await AppDialog.confirmSignOut(context);
    if (!confirmed || !mounted) return;

    await AppServices.serviceAuth.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(LocaleKeys.profileSignOutSuccess.tr())),
    );
    await _goBackOrClose();
  }

  Map<String, String> _buildHeaders() {
    return switch (_config.headerPolicy) {
      WebViewHeaderPolicy.none => <String, String>{},
      WebViewHeaderPolicy.customOnly => <String, String>{
        ..._config.extraHeaders,
      },
      WebViewHeaderPolicy.sessionAndCustom => <String, String>{
        ...?_session?.toHeaders(),
        ..._config.extraHeaders,
      },
    };
  }

  URLRequest _buildRequest() {
    final Uri uri = _normalizedUri;
    final Map<String, String> headers = _buildHeaders();
    final URLRequest request;
    if (_config.method == WebViewHttpMethod.post) {
      request = URLRequest(
        url: WebUri(uri.toString()),
        method: 'POST',
        headers: headers,
        body: Uint8List.fromList(utf8.encode(_config.postBody ?? '')),
      );
    } else {
      request = URLRequest(url: WebUri(uri.toString()), headers: headers);
    }
    _logger.logInitialRequest(request: request, headers: headers);
    return request;
  }

  InAppWebViewSettings _buildSettings() {
    return InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      useOnNavigationResponse: true,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      mediaPlaybackRequiresUserGesture: false,
      transparentBackground: false,
      supportZoom: false,
      builtInZoomControls: false,
      displayZoomControls: false,
      supportMultipleWindows: true,
      geolocationEnabled: true,
      allowFileAccess: true,
      allowContentAccess: true,
      allowFileAccessFromFileURLs: false,
      allowUniversalAccessFromFileURLs: false,
      mixedContentMode: _config.allowCleartextLocalhost
          ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
          : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      cacheEnabled: false,
      cacheMode: CacheMode.LOAD_NO_CACHE,
      clearCache: true,
      useHybridComposition: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      thirdPartyCookiesEnabled: true,
      sharedCookiesEnabled: true,
      allowsInlineMediaPlayback: true,
      allowsBackForwardNavigationGestures: true,
      allowsLinkPreview: true,
      disableDefaultErrorPage: true,
    );
  }

  List<UserScript> _buildUserScripts() {
    final List<UserScript> scripts = <UserScript>[];
    final WebSessionContext? session = _session;
    if (session == null) return scripts;
    if (_config.injectSessionContext || _config.enableJsBridge) {
      scripts.add(
        UserScript(
          source: appBridgeBootstrapJs(session.toJsContextJson()),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
      scripts.add(
        UserScript(
          source: lcpObserverJs,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        ),
      );
    }
    return scripts;
  }

  Future<NavigationActionPolicy> _onNavigation(
    InAppWebViewController _,
    NavigationAction action,
  ) async {
    final WebUri? url = action.request.url;
    if (url == null) return NavigationActionPolicy.ALLOW;

    final Uri uri = Uri.parse(url.toString());
    final WebNavigationDecision decision = _navPolicy.decide(uri);
    _logger.logNavigationDecision(
      uri: uri,
      reason: decision.reason,
      action: decision.action.name,
      isMainFrame: action.isForMainFrame,
      isRedirect: action.isRedirect,
      method: action.request.method,
    );

    switch (decision.action) {
      case WebNavDecision.allow:
        return NavigationActionPolicy.ALLOW;
      case WebNavDecision.external:
        await _launchExternal(uri);
        return NavigationActionPolicy.CANCEL;
      case WebNavDecision.block:
        return NavigationActionPolicy.CANCEL;
    }
  }

  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    final Uri? uri = Uri.tryParse(
      createWindowAction.request.url?.toString() ?? '',
    );
    if (uri != null) {
      final WebNavigationDecision decision = _navPolicy.decide(uri);
      if (decision.action == WebNavDecision.external) {
        await _launchExternal(uri);
        return false;
      }
    }
    await controller.loadUrl(urlRequest: createWindowAction.request);
    return false;
  }

  Future<NavigationResponseAction> _onNavigationResponse(
    InAppWebViewController _,
    NavigationResponse navigationResponse,
  ) async {
    final URLResponse? response = navigationResponse.response;
    final Uri? responseUri = Uri.tryParse(response?.url.toString() ?? '');
    _logger.logHttpResponse(
      uri: responseUri,
      statusCode: response?.statusCode,
      mimeType: response?.mimeType,
      headers: response?.headers,
    );

    if (!navigationResponse.canShowMIMEType &&
        navigationResponse.isForMainFrame &&
        responseUri != null &&
        (responseUri.scheme == 'http' || responseUri.scheme == 'https')) {
      return NavigationResponseAction.DOWNLOAD;
    }

    return NavigationResponseAction.ALLOW;
  }

  Future<void> _onDownloadStart(
    InAppWebViewController _,
    DownloadStartRequest request,
  ) async {
    final Uri? uri = Uri.tryParse(request.url.toString());
    if (uri != null) {
      await _launchExternal(uri);
    }
  }

  void _onRedirect(InAppWebViewController _) {
    _logger.logRedirect(
      from: _lastVisitedUri,
      to: _lastStartedUri,
      source: 'provisional_navigation',
    );
  }

  void _onUpdateVisitedHistory(
    InAppWebViewController _,
    WebUri? url,
    bool? isReload,
  ) {
    final Uri? uri = url == null ? null : Uri.tryParse(url.toString());
    if (uri != null && _lastVisitedUri != null && _lastVisitedUri != uri) {
      _logger.logRedirect(
        from: _lastVisitedUri,
        to: uri,
        source: isReload == true ? 'reload' : 'history',
      );
    }
    _lastVisitedUri = uri;
    if (_loading && (_progress >= 1 || isReload == true)) {
      _scheduleLoadSettlement(uri: uri, reason: 'visited_history');
    }
  }

  Future<void> _launchExternal(Uri uri) async {
    final bool launched = await _externalLauncher.launch(uri);
    if (!launched) {
      _logger.logError(
        uri: uri,
        category: 'external_launch',
        description: 'Failed to open external URL',
      );
    }
  }

  void _onCreated(InAppWebViewController raw) {
    final AppWebViewController controller = AppWebViewController(raw);
    _controller = controller;
    if (_config.enableJsBridge) {
      WebViewBridge(
        onClose: () => Navigator.of(context).maybePop(),
        onLogout: () => Navigator.of(context).maybePop(),
        onNavigate: (_) {},
        onScanner: () {},
        onMessage: _config.onBridgeMessage,
        onSubmitForm: _handleSubmitForm,
      ).register(raw);
    }
    widget.onCreated?.call(controller);
  }

  Future<Map<String, dynamic>> _handleSubmitForm(Map<String, dynamic> payload) {
    final Map<String, dynamic> data =
        (payload['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};
    return AppServices.offlineSync.submitForm(
      formType: payload['formType']?.toString() ?? 'generic',
      endpoint: payload['endpoint']?.toString() ?? '/survey/submit',
      data: data,
      clientId: payload['clientId']?.toString(),
      authToken:
          _session?.accessToken ?? AppServices.serviceAuth.session.value?.token,
      officerId: _session?.officerId,
      districtId: _session?.districtId,
      deviceId: _session?.deviceId,
    );
  }

  void _onLoadStart(InAppWebViewController _, WebUri? url) {
    _loadSettleTimer?.cancel();
    _lastStartedUri = url == null ? null : Uri.tryParse(url.toString());
    _logger.logLoadStart(_lastStartedUri);
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
      _favicon = null;
      _progress = 0;
    });
    _config.onPageStarted?.call();

    _scheduleLoadSettlement(
      uri: _lastStartedUri,
      reason: 'load_start_timeout',
      delay: const Duration(seconds: 8),
    );
  }

  Future<void> _onLoadStop(InAppWebViewController _, WebUri? url) async {
    final Uri? uri = url == null
        ? _lastVisitedUri
        : Uri.tryParse(url.toString());
    _logger.logLoadStop(uri);
    _loadSettleTimer?.cancel();
    await _pullToRefresh?.endRefreshing();
    await _settleLoad(uri: uri, reason: 'load_stop');
  }

  void _onProgressChanged(InAppWebViewController _, int progress) {
    if (progress >= 100) {
      _pullToRefresh?.endRefreshing();
      _scheduleLoadSettlement(
        uri: _lastVisitedUri ?? _lastStartedUri,
        reason: 'progress_complete',
      );
    }
    if (!mounted) return;
    setState(() => _progress = progress / 100);
    _logger.logProgress(
      progress: progress,
      uri: _lastVisitedUri ?? _lastStartedUri,
    );
  }

  Future<void> _onReceivedError(
    InAppWebViewController _,
    WebResourceRequest request,
    WebResourceError error,
  ) async {
    final Uri? uri = Uri.tryParse(request.url.toString());
    if (_shouldIgnoreResourceError(request: request, error: error)) {
      _logger.logError(
        uri: uri,
        category: 'cancelled',
        description: error.description,
        ignored: true,
      );
      return;
    }

    await _pullToRefresh?.endRefreshing();
    if (!mounted || !_isMainFrameRequest(request)) return;

    _logger.logError(
      uri: uri,
      category: _classifyResourceError(error),
      description: error.description,
    );
    setState(() {
      _loading = false;
      _error = true;
      _errorCategory = _classifyResourceError(error);
      _errorMessage = error.description.trim();
    });
    _config.onError?.call(error.description);
  }

  Future<void> _onReceivedHttpError(
    InAppWebViewController _,
    WebResourceRequest request,
    WebResourceResponse response,
  ) async {
    if (!mounted || !_isMainFrameRequest(request)) return;

    final int statusCode = response.statusCode ?? 0;
    final Uri? uri = Uri.tryParse(request.url.toString());
    _logger.logHttpResponse(
      uri: uri,
      statusCode: response.statusCode,
      mimeType: response.contentType,
      headers: response.headers?.cast<String, String>(),
    );

    final String mime = (response.contentType ?? '').toLowerCase();
    final bool spaFallback404 =
        statusCode == 404 && (mime.contains('text/html') || mime.isEmpty);
    if (statusCode >= 400 && !spaFallback404) {
      await _pullToRefresh?.endRefreshing();
      setState(() {
        _loading = false;
        _error = true;
        _errorCategory = 'http';
        _errorMessage = 'HTTP $statusCode';
      });
      _config.onError?.call('HTTP $statusCode');
      return;
    }
    if (spaFallback404) {
      _scheduleLoadSettlement(
        uri: uri,
        reason: 'spa_http_404_fallback',
        delay: const Duration(milliseconds: 800),
      );
    }
  }

  void _scheduleLoadSettlement({
    required Uri? uri,
    required String reason,
    Duration delay = const Duration(milliseconds: 500),
  }) {
    _loadSettleTimer?.cancel();
    _loadSettleTimer = Timer(delay, () {
      unawaited(_settleLoad(uri: uri, reason: reason));
    });
  }

  Future<void> _settleLoad({required Uri? uri, required String reason}) async {
    if (!mounted) return;
    final Uri finalUri =
        uri ?? _lastVisitedUri ?? _lastStartedUri ?? _normalizedUri;
    if (_config.syncCookies &&
        (finalUri.scheme == 'http' || finalUri.scheme == 'https')) {
      await Get.find<WebViewCookieService>().logCookiesFor(
        WebUri(finalUri.toString()),
        source: reason,
      );
    }
    setState(() {
      _loading = false;
      _error = false;
      if (_progress < 1) {
        _progress = 1;
      }
    });
    _config.onPageFinished?.call(finalUri.toString());
    if (_config.onMetrics != null) {
      final WebViewMetrics? metrics = await _controller?.collectMetrics();
      if (metrics != null) {
        _config.onMetrics!.call(metrics);
      }
    }
  }

  bool _shouldIgnoreResourceError({
    required WebResourceRequest request,
    required WebResourceError error,
  }) {
    if (error.type == WebResourceErrorType.CANCELLED) {
      return true;
    }

    final String description = error.description.toLowerCase();
    if (description.contains('-999') || description.contains('cancelled')) {
      return true;
    }

    return request.isRedirect == true;
  }

  bool _isMainFrameRequest(WebResourceRequest request) {
    return request.isForMainFrame ?? true;
  }

  String _classifyResourceError(WebResourceError error) {
    final String description = error.description.toLowerCase();
    if (description.contains('ssl') || description.contains('certificate')) {
      return 'ssl';
    }
    if (description.contains('timeout')) {
      return 'timeout';
    }
    if (description.contains('dns') || description.contains('resolve')) {
      return 'dns';
    }
    if (description.contains('network') || description.contains('internet')) {
      return 'network';
    }
    return 'load';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop) return;
        await _goBackOrClose();
      },
      child: Scaffold(
        backgroundColor: context.appBackground,
        body: Column(
          children: <Widget>[
            if (_config.showHeader)
              AppWebViewHeader(
                title: _config.title,
                icon: _favicon,
                onBack: _goBackOrClose,
                onReload: _reload,
                onLogout: _config.showLogoutButton ? _confirmLogout : null,
              ),
            if (_loading) _loadingBar(context),
            Expanded(
              child: Stack(
                children: <Widget>[
                  if (_prepared) _webView() else _initialLoading(),
                  if (_error) _errorView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<GeolocationPermissionShowPromptResponse> _onGeolocationPermission(
    InAppWebViewController _,
    String origin,
  ) async {
    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (!status.isGranted && !status.isLimited) {
      status = await Permission.locationWhenInUse.request();
    }
    final bool allow = status.isGranted || status.isLimited;
    return GeolocationPermissionShowPromptResponse(
      origin: origin,
      allow: allow,
      retain: allow,
    );
  }

  Future<PermissionResponse> _onWebViewPermissionRequest(
    InAppWebViewController _,
    PermissionRequest _,
  ) async {
    return PermissionResponse(
      resources: const <PermissionResourceType>[],
      action: PermissionResponseAction.DENY,
    );
  }

  Widget _webView() {
    return InAppWebView(
      initialUrlRequest: _initialRequest,
      initialSettings: _settings,
      initialUserScripts:
          _initialUserScripts ?? UnmodifiableListView<UserScript>([]),
      pullToRefreshController: _pullToRefresh,
      onWebViewCreated: _onCreated,
      shouldOverrideUrlLoading: _onNavigation,
      onCreateWindow: _onCreateWindow,
      onNavigationResponse: _onNavigationResponse,
      onDownloadStartRequest: _onDownloadStart,
      onReceivedServerTrustAuthRequest:
          (_, URLAuthenticationChallenge challenge) =>
              _security.decide(challenge),
      onDidReceiveServerRedirectForProvisionalNavigation: _onRedirect,
      onUpdateVisitedHistory: _onUpdateVisitedHistory,
      onGeolocationPermissionsShowPrompt: _onGeolocationPermission,
      onPermissionRequest: _onWebViewPermissionRequest,
      onLoadStart: _onLoadStart,
      onReceivedIcon: (_, Uint8List icon) async {
        if (!mounted) return;
        setState(() => _favicon = icon);
      },
      onLoadStop: _onLoadStop,
      onReceivedError: _onReceivedError,
      onReceivedHttpError: _onReceivedHttpError,
      onProgressChanged: _onProgressChanged,
      onConsoleMessage: (_, ConsoleMessage message) {
        _logger.logConsole(
          level: message.messageLevel.toString(),
          message: message.message,
        );
      },
    );
  }

  Widget _loadingBar(BuildContext context) {
    return LinearProgressIndicator(
      value: _progress == 0 ? null : _progress,
      minHeight: 3,
      backgroundColor: context.appChip,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.surveyPrimary),
    );
  }

  Widget _initialLoading() {
    if (_config.loadingBuilder != null) {
      return _config.loadingBuilder!(context);
    }
    return ColoredBox(
      color: context.appBackground,
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.surveyPrimary),
        ),
      ),
    );
  }

  Widget _errorView() {
    if (_config.errorBuilder != null) {
      return _config.errorBuilder!(context, _reload);
    }

    final ({String title, String subtitle, IconData icon}) copy =
        _errorCopyForCategory(_errorCategory);

    return Container(
      color: context.appBackground,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: context.isAppDark
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.errorSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(copy.icon, color: AppColors.error, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.appOnSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              copy.subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.appMuted,
                height: 1.45,
              ),
            ),
            if (_errorMessage.isNotEmpty) ...<Widget>[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.06),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      LocaleKeys.webviewErrorDetailsLabel.tr(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage,
                      style: AppTextStyles.caption.copyWith(
                        color: context.appOnSurface,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_lastStartedUri != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _lastStartedUri.toString(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: context.appMuted,
                          fontSize: 10,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: 200,
              child: AppGradientButton(
                label: LocaleKeys.commonRetry.tr(),
                icon: Icons.refresh_rounded,
                gradient: AppGradients.survey,
                onPressed: _reload,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _goBackOrClose,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(LocaleKeys.webviewErrorGoBack.tr()),
            ),
          ],
        ),
      ),
    );
  }

  ({String title, String subtitle, IconData icon}) _errorCopyForCategory(
    String category,
  ) {
    return switch (category) {
      'network' => (
        title: LocaleKeys.webviewErrorNetworkTitle.tr(),
        subtitle: LocaleKeys.webviewErrorNetworkSub.tr(),
        icon: Icons.wifi_off_rounded,
      ),
      'http' => (
        title: LocaleKeys.webviewErrorHttpTitle.tr(),
        subtitle: LocaleKeys.webviewErrorHttpSub.tr(
          args: <String>[_errorMessage.replaceFirst(RegExp(r'^HTTP\s*'), '')],
        ),
        icon: Icons.http_rounded,
      ),
      'ssl' => (
        title: LocaleKeys.webviewErrorSslTitle.tr(),
        subtitle: LocaleKeys.webviewErrorSslSub.tr(),
        icon: Icons.lock_outline_rounded,
      ),
      'timeout' => (
        title: LocaleKeys.webviewErrorTimeoutTitle.tr(),
        subtitle: LocaleKeys.webviewErrorTimeoutSub.tr(),
        icon: Icons.timer_off_outlined,
      ),
      'dns' => (
        title: LocaleKeys.webviewErrorDnsTitle.tr(),
        subtitle: LocaleKeys.webviewErrorDnsSub.tr(),
        icon: Icons.dns_outlined,
      ),
      _ => (
        title: LocaleKeys.webviewErrorGenericTitle.tr(),
        subtitle: _errorMessage.isNotEmpty
            ? LocaleKeys.webviewErrorGenericSub.tr()
            : LocaleKeys.webviewLoadFailedSubtitle.tr(),
        icon: Icons.error_outline_rounded,
      ),
    };
  }
}
