import 'dart:async';

import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/shared/models/device_record.dart';
import 'package:get/get.dart' hide Trans;

/// Single source of truth for device records across the app.
class DeviceRecordsController extends GetxController {
  DeviceRecordsController(this._db);

  final LocalDatabase _db;
  final RxList<DeviceRecord> records = <DeviceRecord>[].obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_restore());
  }

  String _collection(DeviceKind kind) => kind == DeviceKind.controlUnit
      ? LocalCollections.controlUnits
      : LocalCollections.ballotUnits;

  Future<void> _restore() async {
    try {
      final List<Map<String, dynamic>> cu = await _db.getAll(
        LocalCollections.controlUnits,
      );
      final List<Map<String, dynamic>> bu = await _db.getAll(
        LocalCollections.ballotUnits,
      );
      final List<DeviceRecord> loaded =
          <DeviceRecord>[
            ...cu.map(DeviceRecord.fromJson),
            ...bu.map(DeviceRecord.fromJson),
          ]..sort(
            (DeviceRecord a, DeviceRecord b) =>
                b.timestamp.compareTo(a.timestamp),
          );
      records.assignAll(loaded);
    } catch (e, s) {
      AppLogger.w('Restoring device records failed', error: e, stackTrace: s);
    }
  }

  int _maxSeq(DeviceKind kind) {
    int max = 0;
    for (final DeviceRecord r in records) {
      if (r.kind != kind) continue;
      final List<String> parts = r.id.split('-');
      final int? seq = parts.isEmpty ? null : int.tryParse(parts.last);
      if (seq != null && seq > max) max = seq;
    }
    return max;
  }

  String _idFor(DeviceKind kind, int seq) =>
      '${kind.code}-${DateTime.now().year}-${seq.toString().padLeft(3, '0')}';

  /// Next device id that *would* be assigned for [kind] (preview before save).
  String previewNextId(DeviceKind kind) => _idFor(kind, _maxSeq(kind) + 1);

  /// Registers a new device, prepends it to the store and returns the record.
  DeviceRecord register({
    required DeviceKind kind,
    required String barcode,
    String? box,
    String manufacturer = 'BEL',
    String district = 'Unassigned',
    String officer = '—',
    DeviceStatus status = DeviceStatus.pending,
  }) {
    final DeviceRecord record = DeviceRecord(
      id: _idFor(kind, _maxSeq(kind) + 1),
      barcode: barcode.trim(),
      box: (box == null || box.trim().isEmpty) ? 'Unassigned' : box.trim(),
      kind: kind,
      manufacturer: manufacturer,
      status: status,
      district: district.trim().isEmpty ? 'Unassigned' : district.trim(),
      officer: officer.trim().isEmpty ? '—' : officer.trim(),
      timestamp: DateTime.now(),
    );
    records.insert(0, record);
    unawaited(_persist(record));
    return record;
  }

  Future<void> _persist(DeviceRecord record) async {
    try {
      await _db.put(_collection(record.kind), record.id, record.toJson());
    } catch (e, s) {
      AppLogger.w(
        'Persisting device ${record.id} failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Marks every `pending` device as `registered`.
  int markAllSynced() {
    int changed = 0;
    for (int i = 0; i < records.length; i++) {
      final DeviceRecord r = records[i];
      if (r.status == DeviceStatus.pending) {
        changed++;
        final DeviceRecord updated = r.copyWith(
          status: DeviceStatus.registered,
        );
        records[i] = updated;
        unawaited(_persist(updated));
      }
    }
    if (changed > 0) records.refresh();
    return changed;
  }

  /// Updates a single device's [status] and persists the change.
  void updateStatus(String id, DeviceStatus status) {
    for (int i = 0; i < records.length; i++) {
      if (records[i].id == id) {
        final DeviceRecord updated = records[i].copyWith(status: status);
        records[i] = updated;
        unawaited(_persist(updated));
        records.refresh();
        return;
      }
    }
  }

  DeviceRecord? byId(String id) {
    for (final DeviceRecord r in records) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<DeviceRecord> byKind(DeviceKind kind) =>
      records.where((DeviceRecord r) => r.kind == kind).toList();

  DeviceStats statsFor(DeviceKind? kind) {
    final Iterable<DeviceRecord> src = kind == null
        ? records
        : records.where((DeviceRecord r) => r.kind == kind);
    int reg = 0, pend = 0, transit = 0, defect = 0;
    for (final DeviceRecord r in src) {
      switch (r.status) {
        case DeviceStatus.registered:
          reg++;
        case DeviceStatus.pending:
          pend++;
        case DeviceStatus.inTransit:
          transit++;
        case DeviceStatus.defective:
          defect++;
      }
    }
    return DeviceStats(
      total: reg + pend + transit + defect,
      registered: reg,
      pending: pend,
      inTransit: transit,
      defective: defect,
    );
  }

  List<DeviceRecord> search(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return const <DeviceRecord>[];
    return records
        .where(
          (DeviceRecord r) =>
              r.id.toLowerCase().contains(q) ||
              r.barcode.toLowerCase().contains(q) ||
              r.box.toLowerCase().contains(q) ||
              r.officer.toLowerCase().contains(q) ||
              r.district.toLowerCase().contains(q),
        )
        .toList();
  }
}
