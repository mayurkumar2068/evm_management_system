import 'package:evm_management_system/core/utils/json_map.dart';

/// Master dashboard card from `GET /api/Masters/card-list`.
class DashboardCardModel {
  const DashboardCardModel({
    required this.id,
    required this.categoryName,
    required this.categoryNameEn,
    required this.cardName,
    required this.cardNameEn,
    required this.isRegistrationAllowed,
    required this.isLogin,
    required this.isWebView,
    required this.isActive,
    this.url,
  });

  factory DashboardCardModel.fromJson(Map<String, dynamic> json) {
    return DashboardCardModel(
      id: parseOptionalInt(json['ID'] ?? json['Id'] ?? json['id']) ?? 0,
      categoryName: _str(json['CategoryName'] ?? json['categoryName']),
      categoryNameEn: _str(json['CategoryNameEn'] ?? json['categoryNameEn']),
      cardName: _str(json['CardName'] ?? json['cardName']),
      cardNameEn: _str(json['CardNameEn'] ?? json['cardNameEn']),
      isRegistrationAllowed: _asBool(
        json['IsRegistrationAllowed'] ?? json['isRegistrationAllowed'],
      ),
      isLogin: _asBool(json['IsLogin'] ?? json['isLogin']),
      isWebView: _asBool(json['IsWebView'] ?? json['isWebView']),
      url: _nullableStr(json['Url'] ?? json['url']),
      isActive: _asBool(json['IsActive'] ?? json['isActive'], defaultValue: true),
    );
  }

  final int id;
  final String categoryName;
  final String categoryNameEn;
  final String cardName;
  final String cardNameEn;
  final bool isRegistrationAllowed;
  final bool isLogin;
  final bool isWebView;
  final String? url;
  final bool isActive;

  String displayName({required bool preferHindi}) {
    if (preferHindi && cardName.trim().isNotEmpty) return cardName.trim();
    if (cardNameEn.trim().isNotEmpty) return cardNameEn.trim();
    return cardName.trim();
  }

  String displayCategory({required bool preferHindi}) {
    if (preferHindi && categoryName.trim().isNotEmpty) {
      return categoryName.trim();
    }
    if (categoryNameEn.trim().isNotEmpty) return categoryNameEn.trim();
    return categoryName.trim();
  }

  /// Stable English key used for native route mapping.
  String get matchKey => cardNameEn.trim().toLowerCase();

  static String _str(Object? value) => value?.toString().trim() ?? '';

  static String? _nullableStr(Object? value) {
    final String s = _str(value);
    return s.isEmpty ? null : s;
  }


  static bool _asBool(Object? value, {bool defaultValue = false}) {
    if (value is bool) return value;
    final String s = value?.toString().trim().toLowerCase() ?? '';
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return defaultValue;
  }
}
