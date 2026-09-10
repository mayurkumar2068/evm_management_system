import 'package:evm_management_system/core/webview/config/webview_config.dart';
import 'package:evm_management_system/core/webview/url/webview_url_utils.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/features/web_portal/presentation/screens/web_view_screen.dart';

abstract final class DashboardWebViewLauncher {
  static const Map<String, String> _externalPortalHeaders = <String, String>{
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'hi-IN,hi;q=0.9,en;q=0.8',
  };

  static String launchUrl({
    required String baseUrl,
    required ServiceSession? session,
    required bool passSessionContext,
    required bool openAsExternalPortal,
  }) {
    final String token = session?.token ?? '';
    if (!passSessionContext || token.isEmpty) return baseUrl;

    var url = appendWebViewSurveyContext(
      baseUrl,
      token: token,
      userId: session?.userId,
      districtId: session?.districtId,
      distName: session?.districtName,
      bodyId: session?.bodyId,
      bodyName: session?.bodyName,
      urbanRural: session?.section,
      boothLat: session?.lat,
      boothLong: session?.long,
    );

    url = appendWebViewCacheBust(url);
    return url;
  }

  static WebViewArgs args({
    required String title,
    required String url,
    required bool openAsExternalPortal,
    bool showLogoutButton = false,
  }) {
    return WebViewArgs(
      title: title,
      url: url,
      headerPolicy: openAsExternalPortal
          ? WebViewHeaderPolicy.customOnly
          : WebViewHeaderPolicy.sessionAndCustom,
      extraHeaders: openAsExternalPortal ? _externalPortalHeaders : const {},
      cachePolicy: WebViewCachePolicy.noCache,
      syncCookies: !openAsExternalPortal,
      injectSessionContext: !openAsExternalPortal,
      enableJsBridge: !openAsExternalPortal,
      bootstrapSession: !openAsExternalPortal,
      showLogoutButton: showLogoutButton,
    );
  }
}
