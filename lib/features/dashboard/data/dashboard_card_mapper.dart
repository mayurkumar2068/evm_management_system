import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/dashboard/data/models/dashboard_card_model.dart';
import 'package:evm_management_system/features/dashboard/presentation/models/dashboard_models.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

abstract final class DashboardCardMapper {
  static List<DashboardService> mapServices({
    required List<DashboardCardModel> cards,
    required bool preferHindi,
    required String surveyWebUrl,
    required String voterRegistrationUrl,
  }) {
    final List<DashboardService> out = <DashboardService>[];
    for (final DashboardCardModel card in cards) {
      final DashboardService? service = _mapOne(
        card: card,
        preferHindi: preferHindi,
        surveyWebUrl: surveyWebUrl,
        voterRegistrationUrl: voterRegistrationUrl,
      );
      if (service != null) out.add(service);
    }
    return out;
  }

  static DashboardCategory categoryFor(DashboardCardModel card) {
    final String en = card.categoryNameEn.toLowerCase();
    final String hi = card.categoryName;
    if (en.contains('voter') || hi.contains('मतदाता')) {
      return DashboardCategory.voterServices;
    }
    return DashboardCategory.aboutElections;
  }

  static String? categoryLabel({
    required List<DashboardCardModel> cards,
    required DashboardCategory category,
    required bool preferHindi,
  }) {
    final ({String? voter, String? election}) labels = categoryLabels(
      cards: cards,
      preferHindi: preferHindi,
    );
    return category == DashboardCategory.voterServices
        ? labels.voter
        : labels.election;
  }

  static ({String? voter, String? election}) categoryLabels({
    required List<DashboardCardModel> cards,
    required bool preferHindi,
  }) {
    String? voter;
    String? election;
    for (final DashboardCardModel card in cards) {
      final String label = card.displayCategory(preferHindi: preferHindi);
      if (label.isEmpty) continue;
      if (categoryFor(card) == DashboardCategory.voterServices) {
        voter ??= label;
      } else {
        election ??= label;
      }
      if (voter != null && election != null) break;
    }
    return (voter: voter, election: election);
  }

  static DashboardService? _mapOne({
    required DashboardCardModel card,
    required bool preferHindi,
    required String surveyWebUrl,
    required String voterRegistrationUrl,
  }) {
    final String title = card.displayName(preferHindi: preferHindi);
    if (title.isEmpty) return null;

    final DashboardCategory category = categoryFor(card);
    final _NativeKind? native = _resolveNative(card);

    switch (native) {
      case _NativeKind.voterSearch:
        return DashboardService(
          title: title,
          desc: '',
          icon: Icons.manage_search_outlined,
          color: AppColors.primary,
          url: '',
          category: category,
          routeName: AppRoute.voterSearch.path,
          requiresServiceLogin: card.isLogin,
          registrationAllowed: card.isRegistrationAllowed,
        );
      case _NativeKind.boothSurvey:
        return DashboardService(
          title: title,
          desc: '',
          icon: Icons.location_on_outlined,
          color: AppColors.primaryBright,
          url: (card.url != null && card.url!.isNotEmpty)
              ? card.url!
              : surveyWebUrl,
          category: category,
          requiresServiceLogin: card.isLogin,
          passSessionContext: true,
          openAsExternalPortal: false,
          requiredLoginKind: ServiceLoginKind.survey,
          registrationAllowed: card.isRegistrationAllowed,
        );
      case _NativeKind.presiding:
        return DashboardService(
          title: title,
          desc: '',
          icon: Icons.how_to_vote_rounded,
          color: MpSecTokens.softBlueDark,
          url: '',
          category: category,
          routeName: AppRoute.presidingDashboard.path,
          requiresServiceLogin: card.isLogin,
          forceFreshLogin: false,
          requiredLoginKind: ServiceLoginKind.presiding,
          registrationAllowed: card.isRegistrationAllowed,
        );
      case _NativeKind.claimsObjections:
        final String url = (card.url != null && card.url!.isNotEmpty)
            ? card.url!
            : voterRegistrationUrl;
        return DashboardService(
          title: title,
          desc: '',
          icon: Icons.app_registration_rounded,
          color: AppColors.teal,
          url: url,
          category: category,
          requiresServiceLogin: card.isLogin,
          passSessionContext: false,
          openAsExternalPortal: true,
          registrationAllowed: card.isRegistrationAllowed,
        );
      case null:
        break;
    }

    if (card.isWebView) {
      final String? url = card.url;
      if (url == null || url.isEmpty) return null;
      final String key = card.matchKey;
      if (key.contains('expenditure') ||
          key.contains('ems') ||
          key.contains('nomination')) {
        return null;
      }
      return DashboardService(
        title: title,
        desc: '',
        icon: Icons.language_rounded,
        color: AppColors.primaryBright,
        url: url,
        category: category,
        requiresServiceLogin: card.isLogin,
        passSessionContext: !card.isLogin,
        openAsExternalPortal: true,
        requiredLoginKind: card.isLogin ? ServiceLoginKind.survey : null,
        registrationAllowed: card.isRegistrationAllowed,
      );
    }

    return null;
  }

  static _NativeKind? _resolveNative(DashboardCardModel card) {
    switch (card.id) {
      case 1:
        return _NativeKind.claimsObjections;
      case 2:
        return _NativeKind.voterSearch;
      case 3:
        return null;
      case 4:
        return _NativeKind.boothSurvey;
      case 5:
        return _NativeKind.presiding;
    }

    final String key = card.matchKey;
    if (key.contains('claim') || key.contains('objection')) {
      return _NativeKind.claimsObjections;
    }
    if (key.contains('voter search')) {
      return _NativeKind.voterSearch;
    }
    if (key.contains('expenditure') ||
        key.contains('ems') ||
        key.contains('nomination')) {
      return null;
    }
    if (key.contains('survey') || key.contains('polling station')) {
      return _NativeKind.boothSurvey;
    }
    if (key.contains('presiding')) {
      return _NativeKind.presiding;
    }
    return null;
  }
}

enum _NativeKind {
  claimsObjections,
  voterSearch,
  boothSurvey,
  presiding,
}
