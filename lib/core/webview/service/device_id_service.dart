import 'package:evm_management_system/core/storage/secure_storage_service.dart';
import 'package:uuid/uuid.dart';

/// Issues and persists a stable, app-scoped device identifier in secure
/// storage. Used as `X-Device-Id` for the embedded web apps.
class DeviceIdService {
  DeviceIdService(this._storage);

  static const String _key = 'evm.device_id';
  final SecureStorageService _storage;

  String? _cached;

  Future<String> getOrCreate() async {
    if (_cached != null) return _cached!;
    try {
      final String? existing = await _storage.read(_key);
      if (existing != null && existing.isNotEmpty) {
        return _cached = existing;
      }
    } catch (_) {
      // fall through and mint a fresh one
    }
    final String id = const Uuid().v4();
    try {
      await _storage.write(_key, id);
    } catch (_) {
      // best-effort: still return the id for this session
    }
    return _cached = id;
  }
}
