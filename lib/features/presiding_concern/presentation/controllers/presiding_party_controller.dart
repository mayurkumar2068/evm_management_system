import 'dart:async';

import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_party_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_party_details.dart';
import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';
import 'package:get/get.dart';

/// Tracks whether PO polling-party details (P1–P4) are filled and saved.
final class PresidingPartyController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isComplete = false.obs;

  PoPartyRemoteDatasource get _api =>
      PoPartyRemoteDatasource(AppServices.config);

  @override
  void onInit() {
    super.onInit();
    unawaited(refresh());
  }

  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final String? poUserId = _poUserId;
      if (poUserId == null || poUserId.isEmpty) {
        isComplete.value = false;
        return;
      }
      if (await _readLocalComplete(poUserId)) {
        isComplete.value = true;
        return;
      }
      final PoPartyDetails? existing =
          await _api.fetchPartyDetails(poUserId);
      isComplete.value = _isFilledOnServer(existing);
    } catch (_) {
      isComplete.value = false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markComplete() async {
    final String? poUserId = _poUserId;
    if (poUserId == null || poUserId.isEmpty) return;
    await AppServices.secureStorage.write(
      SecureStorageKeys.poPartyComplete(poUserId),
      '1',
    );
    isComplete.value = true;
  }

  String? get _poUserId =>
      AppServices.serviceAuth.session.value?.userId.trim();

  static bool _isFilledOnServer(PoPartyDetails? details) {
    if (details == null) return false;
    return details.p1Name.trim().isNotEmpty &&
        details.p1MobileNo.trim().length == 10;
  }

  Future<bool> _readLocalComplete(String poUserId) async {
    final String? raw = await AppServices.secureStorage.read(
      SecureStorageKeys.poPartyComplete(poUserId),
    );
    return raw == '1';
  }
}
