import 'dart:async';

import 'package:evm_management_system/core/database/local_database.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:get/get.dart' hide Trans;

/// Single source of truth for the audit/activity log.
class ActivityLogController extends GetxController {
  final RxList<ActivityEvent> events = <ActivityEvent>[].obs;

  LocalDatabase get _db => AppServices.database;

  @override
  void onInit() {
    super.onInit();
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final List<Map<String, dynamic>> rows = await _db.getAll(
        LocalCollections.auditLogs,
      );
      final List<ActivityEvent> loaded =
          rows.map(ActivityEvent.fromJson).toList()..sort(
            (ActivityEvent a, ActivityEvent b) =>
                b.timestamp.compareTo(a.timestamp),
          );
      events.assignAll(loaded);
    } catch (_) {
      // Storage unavailable (e.g. in tests) — keep the in-memory log.
    }
  }

  /// Appends a new event to the log (newest first) and persists it.
  ActivityEvent log({
    required ActivityType type,
    required String title,
    String deviceId = '',
    required String officer,
  }) {
    final ActivityEvent event = ActivityEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      title: title,
      deviceId: deviceId,
      officer: officer.isEmpty ? 'Officer' : officer,
      timestamp: DateTime.now(),
    );
    events.insert(0, event);
    unawaited(_persist(event));
    return event;
  }

  Future<void> _persist(ActivityEvent event) async {
    try {
      await _db.put(LocalCollections.auditLogs, event.id, event.toJson());
    } catch (_) {
      // Best-effort persistence; ignore storage failures.
    }
  }

  /// Every event tied to [deviceId], newest first.
  List<ActivityEvent> eventsForDevice(String deviceId) => events
      .where((ActivityEvent e) => e.deviceId == deviceId)
      .toList(growable: false);
}
