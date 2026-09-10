import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:flutter/material.dart';

enum DashboardCategory { voterServices, aboutElections }

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
    this.registrationAllowed,
  });

  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final DashboardCategory category;

  final String url;

  final String? routeName;

  final bool requiresServiceLogin;

  final bool passSessionContext;

  final bool openAsExternalPortal;

  final bool forceFreshLogin;

  final ServiceLoginKind? requiredLoginKind;

  final bool? registrationAllowed;
}
