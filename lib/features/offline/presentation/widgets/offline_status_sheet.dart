import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/features/offline/presentation/screens/offline_screen.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_status_card.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_sync_progress_card.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Opens offline connection / pending-sync status in a theme-aware bottom sheet.
Future<void> showOfflineStatusSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext ctx) => const _OfflineStatusSheet(),
  );
}

class _OfflineStatusSheet extends StatefulWidget {
  const _OfflineStatusSheet();

  @override
  State<_OfflineStatusSheet> createState() => _OfflineStatusSheetState();
}

class _OfflineStatusSheetState extends State<_OfflineStatusSheet> {
  late Future<OfflineHubState> _future = loadOfflineHubState();
  bool _syncing = false;

  void _reload() {
    final Future<OfflineHubState> next = loadOfflineHubState();
    setState(() {
      _future = next;
    });
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
    });
    try {
      await AppServices.offlineSync.sync();
    } finally {
      if (mounted) {
        setState(() {
          _syncing = false;
        });
        _reload();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottom = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + bottom),
        child: FutureBuilder<OfflineHubState>(
          future: _future,
          builder: (BuildContext context, AsyncSnapshot<OfflineHubState> snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const SizedBox(
                height: 220,
                child: Center(child: AppLoader()),
              );
            }
            if (snap.hasError) {
              return SizedBox(
                height: 240,
                child: AppErrorState(
                  failure: UnknownFailure(debugMessage: '${snap.error}'),
                  onRetry: _reload,
                ),
              );
            }
            final OfflineHubState? state = snap.data;
            if (state == null) {
              return const SizedBox(
                height: 220,
                child: Center(child: AppLoader()),
              );
            }

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: context.appDivider,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    LocaleKeys.offlineHubTitle.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.appOnSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    LocaleKeys.offlineHubSubtitle.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: context.appMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OfflineStatusCard(
                    connectionLabel: state.isOnline
                        ? LocaleKeys.offlineHubOnline.tr()
                        : LocaleKeys.offlineHubOffline.tr(),
                    pendingRecords: state.pendingRecords,
                    lastSync: state.lastSyncLabel,
                    storageUsedMb: state.storageUsedMb,
                  ),
                  const SizedBox(height: 14),
                  OfflineSyncProgressCard(
                    pendingSurveys: state.pendingSurveys,
                    pendingImages: state.pendingImages,
                    pendingVideos: state.pendingVideos,
                    pendingGps: state.pendingGps,
                    pendingSignatures: state.pendingSignatures,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: _syncing ? null : _sync,
                      icon: _syncing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        _syncing
                            ? LocaleKeys.syncHeroSyncing.tr()
                            : LocaleKeys.offlineHubSyncWhenOnline.tr(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _reload,
                    child: Text(LocaleKeys.offlineHubRetryConnection.tr()),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
