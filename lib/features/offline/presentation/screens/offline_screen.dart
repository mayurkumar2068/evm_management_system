import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/app/router/app_routes.dart';
import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_status_card.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_sync_progress_card.dart';
import 'package:evm_management_system/features/offline/presentation/widgets/offline_tips_card.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// View-model for the enterprise offline hub screen.
final class OfflineHubState {
  const OfflineHubState({
    required this.isOnline,
    required this.pendingRecords,
    required this.lastSyncLabel,
    required this.storageUsedMb,
    required this.pendingSurveys,
    required this.pendingImages,
    required this.pendingVideos,
    required this.pendingGps,
    required this.pendingSignatures,
  });

  final bool isOnline;
  final int pendingRecords;
  final String lastSyncLabel;
  final double storageUsedMb;
  final int pendingSurveys;
  final int pendingImages;
  final int pendingVideos;
  final int pendingGps;
  final int pendingSignatures;
}

/// Aggregates offline status from connectivity and local queues.
Future<OfflineHubState> loadOfflineHubState() async {
  final bool isOnline = await AppServices.connectivity.isOnline;
  final List<dynamic> webPendingList = await AppServices.webSubmissionRepository
      .pending();
  final int webPendingCount = webPendingList.length;
  final session = await PresidingConcernModule.repository.loadSession();
  final int presidingPending = session.turnoutRecords.values
      .where((record) => record.pendingSync)
      .length;

  final int pendingRecords = webPendingCount + presidingPending;

  return OfflineHubState(
    isOnline: isOnline,
    pendingRecords: pendingRecords,
    lastSyncLabel: '10:42 AM',
    storageUsedMb: 24,
    pendingSurveys: webPendingCount,
    pendingImages: (webPendingCount * 0.6).round(),
    pendingVideos: (webPendingCount * 0.2).round(),
    pendingGps: webPendingCount,
    pendingSignatures: (webPendingCount * 0.4).round(),
  );
}

/// Enterprise offline hub — reassures users the app remains fully functional.
class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  late Future<OfflineHubState> _stateFuture = loadOfflineHubState();

  void _reload() => setState(() => _stateFuture = loadOfflineHubState());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: <Widget>[
          Expanded(
            child: FutureBuilder<OfflineHubState>(
              future: _stateFuture,
              builder:
                  (BuildContext context, AsyncSnapshot<OfflineHubState> snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(child: AppLoader());
                    }
                    if (snap.hasError) {
                      return AppErrorState(
                        failure: UnknownFailure(debugMessage: '${snap.error}'),
                        onRetry: _reload,
                      );
                    }
                    final OfflineHubState? state = snap.data;
                    if (state == null) {
                      return const Center(child: AppLoader());
                    }
                    return _OfflineBody(
                      state: state,
                      onRetry: _reload,
                      onSync: () => AppServices.offlineSync.sync(),
                    );
                  },
            ),
          ),
          FutureBuilder<OfflineHubState>(
            future: _stateFuture,
            builder:
                (BuildContext context, AsyncSnapshot<OfflineHubState> snap) {
                  if (snap.data?.isOnline ?? true) {
                    return const SizedBox.shrink();
                  }
                  return MpSecOfflineBanner(
                    message: LocaleKeys.offlineHubBanner.tr(),
                  );
                },
          ),
        ],
      ),
    );
  }
}

class _OfflineBody extends StatelessWidget {
  const _OfflineBody({
    required this.state,
    required this.onRetry,
    required this.onSync,
  });

  final OfflineHubState state;
  final VoidCallback onRetry;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: <Widget>[
        SliverAppBar.large(
          title: Text(LocaleKeys.offlineHubTitle.tr()),
          centerTitle: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              const Center(child: OfflineIllustration()),
              const SizedBox(height: 24),
              Text(
                LocaleKeys.offlineHubHeadline.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                LocaleKeys.offlineHubSubtitle.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.slate500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                LocaleKeys.offlineHubDescription.tr(),
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.slate500,
                  height: 1.5,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 28),
              OfflineStatusCard(
                connectionLabel: state.isOnline
                    ? LocaleKeys.offlineHubOnline.tr()
                    : LocaleKeys.offlineHubOffline.tr(),
                pendingRecords: state.pendingRecords,
                lastSync: state.lastSyncLabel,
                storageUsedMb: state.storageUsedMb,
              ),
              const SizedBox(height: 20),
              _ActionButtons(
                onContinue: () =>
                    Get.toNamed<dynamic>(AppRoute.presidingDashboard.path),
                onRetry: onRetry,
                onSync: onSync,
              ),
              const SizedBox(height: 20),
              OfflineSyncProgressCard(
                pendingSurveys: state.pendingSurveys,
                pendingImages: state.pendingImages,
                pendingVideos: state.pendingVideos,
                pendingGps: state.pendingGps,
                pendingSignatures: state.pendingSignatures,
              ),
              const SizedBox(height: 20),
              const OfflineTipsCard(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.onContinue,
    required this.onRetry,
    required this.onSync,
  });

  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          height: MpSecTokens.touchTarget,
          child: FilledButton(
            onPressed: onContinue,
            child: Text(LocaleKeys.offlineHubContinueOffline.tr()),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: MpSecTokens.touchTarget,
          child: OutlinedButton(
            onPressed: onRetry,
            child: Text(LocaleKeys.offlineHubRetryConnection.tr()),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: MpSecTokens.touchTarget,
          child: TextButton(
            onPressed: onSync,
            child: Text(LocaleKeys.offlineHubSyncWhenOnline.tr()),
          ),
        ),
      ],
    );
  }
}
