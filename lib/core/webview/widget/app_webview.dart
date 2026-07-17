import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart' hide Trans;
import 'package:url_launcher/url_launcher.dart';

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

/// The single, reusable WebView engine for the entire app.
class AppWebView extends StatefulWidget {
  /// Creates the app-wide reusable WebView widget.
  const AppWebView({required this.config, this.onCreated, super.key});

  final WebViewConfig config;
  final ValueChanged<AppWebViewController>? onCreated;

  @override
  State<AppWebView> createState() => _AppWebViewState();
}

class _AppWebViewState extends State<AppWebView> {
  static const WebViewNavigationPolicy _navPolicy = WebViewNavigationPolicy();

  AppWebViewController? _controller;
  PullToRefreshController? _pullToRefresh;
  late final WebViewSecurity _security;
  late final WebViewLogger _logger;
  late final InAppWebViewSettings _settings;

  WebSessionContext? _session;
  bool _prepared = false;
  bool _loading = true;
  bool _error = false;
  double _progress = 0;
  Uint8List? _favicon;
  Uri? _lastVisitedUri;
  Uri? _lastStartedUri;
  Timer? _loadSettleTimer;
  URLRequest? _initialRequest;
  UnmodifiableListView<UserScript>? _initialUserScripts;

  /// Returns the current widget configuration.
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

  /// Builds the session context and synchronizes cookies before first paint.
  Future<void> _prepare() async {
    unawaited(Get.find<WebViewWarmer>().warm());

    final WebThemeMode theme =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark
        ? WebThemeMode.dark
        : WebThemeMode.light;

    try {
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

  /// Returns the normalized initial URI.
  Uri get _normalizedUri => Uri.parse(_normalizeUrl(_config.url));

  /// Normalizes and safely encodes user-provided URLs.
  String _normalizeUrl(String rawUrl) => normalizeWebViewLaunchUrl(rawUrl);

  /// Returns the current host for the header UI.
  String get _host {
    try {
      return _normalizedUri.host;
    } catch (_) {
      return _config.url;
    }
  }

  /// Reloads the current page and resets transient error state.
  Future<void> _reload() async {
    _loadSettleTimer?.cancel();
    if (mounted) {
      setState(() {
        _error = false;
        _loading = true;
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
    final bool canBack =
        await (_controller?.canGoBack() ?? Future<bool>.value(false));
    if (canBack) {
      await _controller?.goBack();
      return;
    }
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Returns the app-managed headers for the initial request.
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

  /// Builds the initial GET or POST request.
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

  /// Maps the declarative cache strategy to the native cache mode.
  CacheMode get _cacheMode => switch (_config.cachePolicy) {
    WebViewCachePolicy.normal => CacheMode.LOAD_DEFAULT,
    WebViewCachePolicy.noCache => CacheMode.LOAD_NO_CACHE,
    WebViewCachePolicy.cacheFirst => CacheMode.LOAD_CACHE_ELSE_NETWORK,
  };

  /// Builds cross-platform WebView settings for resilient page loading.
  InAppWebViewSettings _buildSettings() {
    return InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      useOnNavigationResponse: true,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      mediaPlaybackRequiresUserGesture: false,
      transparentBackground: false,
      supportZoom: true,
      supportMultipleWindows: true,
      geolocationEnabled: true,
      allowFileAccess: true,
      allowContentAccess: true,
      allowFileAccessFromFileURLs: false,
      allowUniversalAccessFromFileURLs: false,
      mixedContentMode: _config.allowCleartextLocalhost
          ? MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW
          : MixedContentMode.MIXED_CONTENT_NEVER_ALLOW,
      cacheEnabled: _config.cachePolicy != WebViewCachePolicy.noCache,
      cacheMode: _cacheMode,
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

  /// Builds the user scripts injected into the page before content loads.
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

  /// Applies the navigation policy to every outgoing navigation.
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

  /// Handles `window.open()` by reusing the current WebView instead of spawning
  /// a secondary blank window that would otherwise fail silently on iOS.
  Future<bool> _onCreateWindow(
    InAppWebViewController controller,
    CreateWindowAction createWindowAction,
  ) async {
    await controller.loadUrl(urlRequest: createWindowAction.request);
    return false;
  }

  /// Observes main-frame responses for status logging and download routing.
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

  /// Opens download URLs with the host platform.
  Future<void> _onDownloadStart(
    InAppWebViewController _,
    DownloadStartRequest request,
  ) async {
    final Uri? uri = Uri.tryParse(request.url.toString());
    if (uri != null) {
      await _launchExternal(uri);
    }
  }

  /// Logs provisional redirect callbacks emitted by `WKWebView`.
  void _onRedirect(InAppWebViewController _) {
    _logger.logRedirect(
      from: _lastVisitedUri,
      to: _lastStartedUri,
      source: 'provisional_navigation',
    );
  }

  /// Tracks history changes so the final URL is preserved.
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

  /// Launches supported external-app schemes.
  Future<void> _launchExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (error) {
      _logger.logError(
        uri: uri,
        category: 'external_launch',
        description: error.toString(),
      );
    }
  }

  /// Wraps the raw controller and registers the JS bridge.
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

  /// Routes Angular `AppBridge.submitForm()` calls through the offline sync
  /// engine so web flows remain offline-capable.
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

  /// Handles page-start events and resets transient load state.
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
    // iOS often stalls near 50% when SPA redirects or CDN assets hang.
    // Force the chrome to settle so the user is not stuck on the bar.
    _scheduleLoadSettlement(
      uri: _lastStartedUri,
      reason: 'load_start_timeout',
      delay: const Duration(seconds: 8),
    );
  }

  /// Handles page-stop events and finalizes the loading lifecycle.
  Future<void> _onLoadStop(InAppWebViewController _, WebUri? url) async {
    final Uri? uri = url == null
        ? _lastVisitedUri
        : Uri.tryParse(url.toString());
    _logger.logLoadStop(uri);
    _loadSettleTimer?.cancel();
    await _pullToRefresh?.endRefreshing();
    await _settleLoad(uri: uri, reason: 'load_stop');
  }

  /// Handles progress updates and uses 100% as a fallback completion signal.
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

  /// Handles transport and SSL errors while ignoring expected cancellations.
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
    });
    _config.onError?.call(error.description);
  }

  /// Handles HTTP errors separately from transport-level failures.
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

    // GitHub Pages SPA fallback serves index.html with HTTP 404 for deep links
    // like /location. Treat HTML 404 as a soft failure so load can settle.
    final String mime = (response.contentType ?? '').toLowerCase();
    final bool spaFallback404 =
        statusCode == 404 && (mime.contains('text/html') || mime.isEmpty);
    if (statusCode >= 400 && !spaFallback404) {
      await _pullToRefresh?.endRefreshing();
      setState(() {
        _loading = false;
        _error = true;
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

  /// Schedules a short delayed load settlement when native stop callbacks are
  /// skipped during redirects.
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

  /// Completes loading once the URL has stabilized.
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

  /// Returns whether an error should be ignored as an expected cancellation.
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

  /// Returns whether a request targets the main frame.
  bool _isMainFrameRequest(WebResourceRequest request) {
    return request.isForMainFrame ?? true;
  }

  /// Maps native resource errors to higher-level log categories.
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
        backgroundColor: Colors.white,
        body: Column(
          children: <Widget>[
            if (_config.showHeader)
              AppWebViewHeader(
                title: _config.title,
                host: _host,
                icon: _favicon,
                onBack: _goBackOrClose,
                onReload: _reload,
              ),
            if (_loading) _loadingBar(),
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

  /// Builds the platform WebView widget with all lifecycle hooks attached.
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
      onGeolocationPermissionsShowPrompt: (_, String origin) async =>
          GeolocationPermissionShowPromptResponse(
            origin: origin,
            allow: true,
            retain: true,
          ),
      onPermissionRequest: (_, PermissionRequest request) async =>
          PermissionResponse(
            resources: request.resources,
            action: PermissionResponseAction.GRANT,
          ),
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

  /// Builds the top loading progress indicator.
  Widget _loadingBar() {
    return LinearProgressIndicator(
      value: _progress == 0 ? null : _progress,
      minHeight: 3,
      backgroundColor: AppColors.slate100,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.surveyPrimary),
    );
  }

  /// Builds the initial loading placeholder shown before WebView creation.
  Widget _initialLoading() {
    if (_config.loadingBuilder != null) {
      return _config.loadingBuilder!(context);
    }
    return const Center(
      child: CircularProgressIndicator(
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.surveyPrimary),
      ),
    );
  }

  /// Builds the retryable error UI for unrecoverable main-frame failures.
  Widget _errorView() {
    if (_config.errorBuilder != null) {
      return _config.errorBuilder!(context, _reload);
    }
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: AppColors.errorSurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              color: AppColors.error,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'पेज लोड नहीं हो सका',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.slate800,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Couldn\'t load this page. Check your connection and try again.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.slate500),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 180,
            child: AppGradientButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              gradient: AppGradients.survey,
              onPressed: _reload,
            ),
          ),
        ],
      ),
    );
  }
}
