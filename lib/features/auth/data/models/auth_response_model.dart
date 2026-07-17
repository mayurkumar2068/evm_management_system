import 'package:evm_management_system/features/auth/data/models/user_model.dart';

/// The login / refresh response envelope from the auth API.
class AuthResponseModel {
  const AuthResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data =
        (json['data'] as Map<String, dynamic>?) ?? json;
    final Map<String, dynamic> userJson = Map<String, dynamic>.from(
      data['user'] as Map<String, dynamic>,
    );
    _mergeElectionContext(userJson, data);
    return AuthResponseModel(
      user: UserModel.fromJson(userJson),
      accessToken:
          data['accessToken'] as String? ??
          data['access_token'] as String? ??
          '',
      refreshToken:
          data['refreshToken'] as String? ??
          data['refresh_token'] as String? ??
          '',
      expiresInSeconds:
          data['expiresIn'] as int? ?? data['expires_in'] as int? ?? 3600,
    );
  }

  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;

  /// Copies election / polling-station fields from the response envelope into [userJson].
  static void _mergeElectionContext(
    Map<String, dynamic> userJson,
    Map<String, dynamic> data,
  ) {
    for (final String key in <String>[
      'electionId',
      'election_id',
      'psId',
      'ps_id',
      'PSID',
      'areaType',
      'area_type',
      'pollingStationCode',
      'polling_station_code',
      'boothId',
      'pollingStationName',
      'polling_station_name',
      'boothName',
    ]) {
      if (data[key] != null && userJson[key] == null) {
        userJson[key] = data[key];
      }
    }
  }
}
