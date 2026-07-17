import 'package:flutter/material.dart';

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
    this.routeName,
    this.requiresServiceLogin = true,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Color color;

  /// External government portal opened in the in-app browser.
  final String url;

  /// Native Flutter route name when the service is handled in-app.
  final String? routeName;

  /// When false, opens [url] directly without the per-service officer login.
  final bool requiresServiceLogin;
}
