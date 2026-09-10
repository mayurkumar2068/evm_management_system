import 'package:dio/dio.dart';
import 'package:evm_management_system/core/network/api_client.dart';
import 'package:evm_management_system/core/network/api_endpoints.dart';
import 'package:evm_management_system/features/auth/data/models/auth_response_model.dart';
import 'package:evm_management_system/features/auth/data/models/user_model.dart';
import 'package:evm_management_system/features/auth/domain/entities/login_credentials.dart';
import 'package:evm_management_system/core/notifications/notification_service.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthResponseModel> login(LoginCredentials credentials);
  Future<UserModel> localNotification(UserModel usermodel);
  Future<UserModel> profile();
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthResponseModel> login(LoginCredentials credentials) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'officerId': credentials.officerId,
      'password': credentials.password,
    };
    if (credentials.electionId != null) {
      body['electionId'] = credentials.electionId;
    }

    final Response<Map<String, dynamic>> response = await _apiClient
        .post<Map<String, dynamic>>(
          ApiEndpoints.login,
          data: body,
          options: unauthenticatedOptions,
        );

    final authResponse = AuthResponseModel.fromJson(
      response.data ?? <String, dynamic>{},
    );
    await localNotification(authResponse.user);

    return AuthResponseModel.fromJson(response.data ?? <String, dynamic>{});
  }

  @override
  Future<UserModel> profile() async {
    final Response<Map<String, dynamic>> response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.profile);
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    final Map<String, dynamic> user =
        (body['data'] as Map<String, dynamic>?) ?? body;
    return UserModel.fromJson(user);
  }

  @override
  Future<void> logout() async {
    await _apiClient.post<void>(
      ApiEndpoints.logout,
      options: Options(
        receiveTimeout: const Duration(seconds: 3),
        sendTimeout: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<UserModel> localNotification(UserModel userModel) async {
    final String areaType = userModel.areaType.toString().trim().toLowerCase();

    await NotificationUtils.scheduleDailyReminders(
      areaType: areaType == 'urban'
          ? PollingAreaType.urban
          : PollingAreaType.rural,
    );

    return userModel;
  }
}
