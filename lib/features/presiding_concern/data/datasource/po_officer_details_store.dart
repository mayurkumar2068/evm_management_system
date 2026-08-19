import 'dart:convert';

import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:evm_management_system/features/presiding_concern/data/models/po_officer_details.dart';

/// Local cache of saved PO name/mobile — used by the report when offline or
/// immediately after profile save (before server read catches up).
final class PoOfficerDetailsStore {
  const PoOfficerDetailsStore(this._secureStorage);

  final SecureStorageService _secureStorage;

  Future<void> save(PoOfficerDetails details) async {
    final String poUserId = details.poUserId.trim();
    if (poUserId.isEmpty) return;
    await _secureStorage.write(
      SecureStorageKeys.poOfficerProfile(poUserId),
      jsonEncode(_toJson(details)),
    );
  }

  Future<PoOfficerDetails?> read(String poUserId) async {
    final String id = poUserId.trim();
    if (id.isEmpty) return null;
    final String? raw = await _secureStorage.read(
      SecureStorageKeys.poOfficerProfile(id),
    );
    if (raw == null || raw.isEmpty) return null;
    try {
      return PoOfficerDetails.tryParse(
        jsonDecode(raw) as Map<String, dynamic>,
        fallbackUserId: id,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> clear(String poUserId) {
    final String id = poUserId.trim();
    if (id.isEmpty) return Future<void>.value();
    return _secureStorage.delete(SecureStorageKeys.poOfficerProfile(id));
  }

  static Map<String, dynamic> _toJson(PoOfficerDetails details) =>
      <String, dynamic>{
        if (details.id != null && details.id!.trim().isNotEmpty)
          'id': details.id,
        'poUserId': details.poUserId.trim(),
        'poName': details.poName.trim(),
        'poMobileNo': details.poMobileNo.trim(),
      };
}
