import 'dart:async';
import 'dart:convert';

import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_api_exception.dart';
import 'package:evm_management_system/features/presiding_concern/data/datasource/po_party_remote_datasource.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_party_details.dart';
import 'package:get/get.dart';

final class PresidingPartyController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxBool isComplete = false.obs;

  PoPartyRemoteDatasource get _api =>
      PoPartyRemoteDatasource(AppServices.config);

  @override
  void onInit() {
    super.onInit();
    unawaited(reload());
  }

  Future<void> reload() async {
    isLoading.value = true;
    try {
      final String? poUserId = _poUserId;
      if (poUserId == null || poUserId.isEmpty) {
        isComplete.value = false;
        return;
      }

      final bool localComplete = await _readLocalComplete(poUserId);
      if (localComplete) {
        isComplete.value = true;
      }

      final bool online = await AppServices.connectivity.isOnline;
      if (online) {
        await syncPending();
        final PoPartyDetails? existing = await _api.fetchPartyDetails(poUserId);
        if (_isFilledOnServer(existing)) {
          await _writeDraft(poUserId, existing!);
          await markComplete();
          if (!await _hasPending(poUserId)) {
            isComplete.value = true;
          }
        } else if (localComplete) {
          isComplete.value = true;
        } else {
          isComplete.value = false;
        }
      } else {
        final PoPartyDetails? draft = await _readDraft(poUserId);
        isComplete.value = localComplete || _isFilledOnServer(draft);
      }
    } catch (_) {
      final String? poUserId = _poUserId;
      if (poUserId != null && poUserId.isNotEmpty) {
        isComplete.value = await _readLocalComplete(poUserId);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<PoPartyDetails?> loadForForm() async {
    final String? poUserId = _poUserId;
    if (poUserId == null || poUserId.isEmpty) return null;

    final PoPartyDetails? local = await _readDraft(poUserId);
    final bool pending = await _hasPending(poUserId);
    if (pending && _isFilledOnServer(local)) return local;

    final bool online = await AppServices.connectivity.isOnline;
    if (online) {
      final PoPartyDetails? remote = await _api.fetchPartyDetails(poUserId);
      if (_isFilledOnServer(remote)) {
        await _writeDraft(poUserId, remote!);
        return remote;
      }
    }
    return local;
  }

  Future<void> save(PoPartyDetails details) async {
    final String poUserId = details.poUserId.trim();
    if (poUserId.isEmpty) {
      throw const PoApiException(
        'PO session token missing. Please login again.',
        statusCode: 401,
      );
    }

    await _writeDraft(poUserId, details);

    final bool online = await AppServices.connectivity.isOnline;
    if (!online) {
      await _markPending(poUserId, details);
      await markComplete();
      return;
    }

    try {
      final String? id = await _api.savePartyDetails(details);
      final PoPartyDetails stored = (id != null && id != details.id)
          ? details.copyWith(id: id)
          : details;
      await _writeDraft(poUserId, stored);
      await _clearPending(poUserId);
      await markComplete();
    } on PoApiException catch (e) {
      if (e.isUnauthorized) rethrow;
      await _markPending(poUserId, details);
      final bool fatalClient =
          e.statusCode != null &&
          e.statusCode! >= 400 &&
          e.statusCode! < 500 &&
          e.statusCode != 408 &&
          e.statusCode != 429 &&
          !e.isOffline &&
          !e.isInvalidOtp;
      if (fatalClient) rethrow;
      await markComplete();
    } catch (_) {
      await _markPending(poUserId, details);
      await markComplete();
    }
  }

  Future<void> syncPending() async {
    final String? poUserId = _poUserId;
    if (poUserId == null || poUserId.isEmpty) return;
    if (!await _hasPending(poUserId)) return;
    if (!await AppServices.connectivity.isOnline) return;

    final PoPartyDetails? draft = await _readDraft(poUserId);
    if (draft == null || !_isFilledOnServer(draft)) return;

    try {
      final String? id = await _api.savePartyDetails(draft);
      final PoPartyDetails stored = (id != null && id != draft.id)
          ? draft.copyWith(id: id)
          : draft;
      await _writeDraft(poUserId, stored);
      await _clearPending(poUserId);
      await markComplete();
    } on PoApiException catch (e) {
      if (e.isUnauthorized || (!e.isOffline && e.statusCode == 400)) {
        return;
      }
    } catch (_) {}
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

  String? get _poUserId => AppServices.serviceAuth.session.value?.userId.trim();

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

  Future<PoPartyDetails?> _readDraft(String poUserId) async {
    final String? raw = await AppServices.secureStorage.read(
      SecureStorageKeys.poPartyDraft(poUserId),
    );
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return PoPartyDetails.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDraft(String poUserId, PoPartyDetails details) async {
    await AppServices.secureStorage.write(
      SecureStorageKeys.poPartyDraft(poUserId),
      jsonEncode(details.toCacheJson()),
    );
  }

  Future<bool> _hasPending(String poUserId) async {
    final String? raw = await AppServices.secureStorage.read(
      SecureStorageKeys.poPartyPending(poUserId),
    );
    return raw == '1';
  }

  Future<void> _markPending(String poUserId, PoPartyDetails details) async {
    await _writeDraft(poUserId, details);
    await AppServices.secureStorage.write(
      SecureStorageKeys.poPartyPending(poUserId),
      '1',
    );
  }

  Future<void> _clearPending(String poUserId) async {
    await AppServices.secureStorage.delete(
      SecureStorageKeys.poPartyPending(poUserId),
    );
  }
}
