import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:flutter/material.dart';

/// Dashboard service grouping for the category toggle.
enum DashboardCategory {
  voterServices,
  aboutElections,
}

/// View-model for a statistic card shown in the dashboard strip.
class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.value,
    required this.trend,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String trend;
  final IconData icon;
  final Color color;
}

/// View-model for a service tile / KPI card.
class DashboardService {
  const DashboardService({
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.url,
    required this.category,
    this.routeName,
    this.requiresServiceLogin = true,
    this.passSessionContext = true,
    this.openAsExternalPortal = false,
    this.forceFreshLogin = false,
    this.requiredLoginKind,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final DashboardCategory category;

  /// External government portal opened in the in-app browser.
  final String url;

  /// Native Flutter route name when the service is handled in-app.
  final String? routeName;

  /// When false, opens [url] directly without the per-service officer login.
  final bool requiresServiceLogin;

  /// When false, opens [url] without survey token/query params or session headers.
  final bool passSessionContext;

  /// Third-party portals (voter search) — plain WebView, no cookies/bridge injection.
  final bool openAsExternalPortal;

  /// Always clear any previous officer session and show login again.
  final bool forceFreshLogin;

  /// When set, an existing session of a different kind cannot be reused.
  final ServiceLoginKind? requiredLoginKind;
}
