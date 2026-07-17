import 'package:flutter/material.dart';

/// Centralized icon registry so glyphs can be swapped (e.g. to a custom font)
/// in one place without touching feature code.
abstract final class AppIcons {
  static const IconData dashboard = Icons.dashboard_outlined;
  static const IconData stockRegister = Icons.inventory_2_outlined;
  static const IconData controlUnit = Icons.memory_outlined;
  static const IconData ballotUnit = Icons.how_to_vote_outlined;
  static const IconData scanner = Icons.qr_code_scanner_outlined;
  static const IconData reports = Icons.assessment_outlined;
  static const IconData notifications = Icons.notifications_outlined;
  static const IconData profile = Icons.person_outline;
  static const IconData settings = Icons.settings_outlined;
  static const IconData auditTrail = Icons.fact_check_outlined;
  static const IconData sync = Icons.sync_outlined;
  static const IconData search = Icons.search_outlined;
  static const IconData help = Icons.help_outline;
  static const IconData about = Icons.info_outline;
  static const IconData logout = Icons.logout_outlined;
  static const IconData flashOn = Icons.flash_on_outlined;
  static const IconData flashOff = Icons.flash_off_outlined;
  static const IconData switchCamera = Icons.cameraswitch_outlined;
  static const IconData error = Icons.error_outline;
  static const IconData empty = Icons.inbox_outlined;
  static const IconData offline = Icons.cloud_off_outlined;
  static const IconData success = Icons.check_circle_outline;
  static const IconData visibility = Icons.visibility_outlined;
  static const IconData visibilityOff = Icons.visibility_off_outlined;
  static const IconData fingerprint = Icons.fingerprint;
}
