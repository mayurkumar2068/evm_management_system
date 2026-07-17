import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/sync/sync_models.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/shared/models/activity_event.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Sync Management — offline-first sync console.
class SyncManagementScreen extends StatefulWidget {
  const SyncManagementScreen({super.key});

  @override
  State<SyncManagementScreen> createState() => _SyncManagementScreenState();
}

class _SyncManagementScreenState extends State<SyncManagementScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  )..repeat();
  Timer? _timer;
  bool _syncing = false;
  bool _done = false;
  double _progress = 0;

  /// Snapshot of the tasks being synced in the current run, so they stay
  /// visible even after their status flips in the store.
  List<SyncTask> _batch = <SyncTask>[];
  DateTime? _lastSync;

  @override
  void dispose() {
    _timer?.cancel();
    _spin.dispose();
    super.dispose();
  }

  static String _time(DateTime t) => DateFormat('HH:mm').format(t);

  void _startSync(List<SyncTask> pending) {
    if (_syncing || pending.isEmpty) return;
    setState(() {
      _syncing = true;
      _done = false;
      _progress = 0;
      _batch = List<SyncTask>.of(pending);
    });
    unawaited(AppServices.syncManager.sync());
    _timer = Timer.periodic(const Duration(milliseconds: 60), (Timer t) {
      setState(() {
        _progress += 0.03;
        if (_progress >= 1) {
          _progress = 1;
          _syncing = false;
          _done = true;
          _lastSync = DateTime.now();
          t.cancel();
          _commit();
        }
      });
    });
  }

  void _commit() {
    final int n = _batch.length;
    if (n > 0) {
      AppServices.activityLog.log(
        type: ActivityType.sync,
        title: LocaleKeys.statsSynced.tr(args: ['$n']),
        officer:
            AppServices.auth.authState.value.user?.fullName ??
            LocaleKeys.dashboardGuest.tr(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SyncTask>>(
      stream: AppServices.syncQueue.watchPendingTasks(),
      builder: (BuildContext context, AsyncSnapshot<List<SyncTask>> snap) {
        final List<SyncTask> pending = snap.data ?? const <SyncTask>[];
        final List<SyncTask> rows = (_syncing || _done) ? _batch : pending;
        final int synced = _done ? _batch.length : 0;
        final int pendingCount = _done ? 0 : pending.length;

        return Container(
          color: AppColors.background,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 110),
            children: <Widget>[
              AppTopBar(
                title: LocaleKeys.syncTitle.tr(),
                onBack: Get.key.currentState?.canPop() == true
                    ? () => Get.back<void>()
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: _hero(pending),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: <Widget>[
                    _Counter(
                      value: '$pendingCount',
                      label: LocaleKeys.statsPending.tr(),
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _Counter(
                      value: '$synced',
                      label: LocaleKeys.statsSynced.tr(),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _Counter(
                      value: '0',
                      label: LocaleKeys.statsFailed.tr(),
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  LocaleKeys.syncPendingRecords.tr(),
                  style: AppTextStyles.titleSmall,
                ),
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 18,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          LocaleKeys.syncNoPending.tr(),
                          style: const TextStyle(
                            color: AppColors.slate400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                for (final SyncTask task in rows)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _PendingRow(task: task, done: _done),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _hero(List<SyncTask> pending) {
    final int count = (_syncing || _done) ? _batch.length : pending.length;
    final Gradient gradient = _done
        ? const LinearGradient(
            colors: <Color>[Color(0xFF14532D), Color(0xFF22C55E)],
          )
        : _syncing
        ? AppGradients.header
        : count == 0
        ? const LinearGradient(
            colors: <Color>[Color(0xFF14532D), Color(0xFF22C55E)],
          )
        : const LinearGradient(
            colors: <Color>[Color(0xFF78350F), Color(0xFFF59E0B)],
          );
    final String title = _syncing
        ? LocaleKeys.syncHeroSyncing.tr()
        : _done || count == 0
        ? LocaleKeys.syncHeroDone.tr()
        : LocaleKeys.syncHeroPending.tr();
    final String subtitle = _syncing
        ? '${(_progress * 100).round()}% — ${(count * _progress).round()} of $count records'
        : _done
        ? '${LocaleKeys.syncLastSync.tr()}: ${_lastSync == null ? LocaleKeys.commonJustNow.tr() : _time(_lastSync!)} • ${LocaleKeys.syncUpToDate.tr()}'
        : count == 0
        ? LocaleKeys.syncUpToDate.tr()
        : '$count records waiting to sync'; // Simplified plural for now

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppRadius.brXl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: AppRadius.brMd,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: _heroIcon(count),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: AppRadius.brPill,
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _heroButton(
                  icon: Icons.sync_rounded,
                  label: _syncing
                      ? LocaleKeys.syncHeroSyncing.tr()
                      : _done || count == 0
                      ? LocaleKeys.syncAgain.tr()
                      : LocaleKeys.syncStart.tr(),
                  onTap: () => _startSync(pending),
                  spinning: _syncing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _heroButton(
                  icon: Icons.wifi_off_rounded,
                  label: LocaleKeys.syncForceOffline.tr(),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroIcon(int count) {
    if (_syncing) {
      return RotationTransition(
        turns: _spin,
        child: const Icon(Icons.sync_rounded, size: 24, color: Colors.white),
      );
    }
    return Icon(
      _done || count == 0
          ? Icons.check_circle_outline_rounded
          : Icons.wifi_off_rounded,
      size: 24,
      color: Colors.white,
    );
  }

  Widget _heroButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool spinning = false,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: AppRadius.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brMd,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: AppRadius.brMd,
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (spinning)
                RotationTransition(
                  turns: _spin,
                  child: Icon(icon, size: 14, color: Colors.white),
                )
              else
                Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: AppTextStyles.titleLarge.copyWith(
                color: color,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.slate400,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  const _PendingRow({required this.task, required this.done});
  final SyncTask task;
  final bool done;

  Color get _statusColor => done
      ? AppColors.successSurface
      : (task.status == SyncStatus.failed
            ? AppColors.errorSurface
            : AppColors.warningSurface);

  IconData get _statusIcon => done
      ? Icons.check_rounded
      : (task.status == SyncStatus.failed
            ? Icons.error_outline_rounded
            : Icons.schedule_rounded);

  String get _subtitle {
    final String operation = task.operation.name;
    final String entity = task.entityType.split('.').last;
    return '$entity • ${operation[0].toUpperCase()}${operation.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor,
              borderRadius: AppRadius.brMd,
            ),
            child: Icon(
              _statusIcon,
              size: 16,
              color: done ? AppColors.success : const Color(0xFFD97706),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  task.entityId,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate700,
                  ),
                ),
                Text(
                  _subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.slate400,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(task.createdAt),
            style: AppTextStyles.caption.copyWith(color: AppColors.slate400),
          ),
        ],
      ),
    );
  }
}
