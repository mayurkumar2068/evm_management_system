import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:evm_management_system/core/logging/app_logger.dart';
import 'package:evm_management_system/core/network/connectivity_service.dart';
import 'package:evm_management_system/core/offline/survey_api_upload_service.dart';
import 'package:evm_management_system/core/offline/web_form_submission.dart';
import 'package:evm_management_system/core/offline/web_submission_repository.dart';
import 'package:evm_management_system/core/sync/retry_policy.dart';
import 'package:evm_management_system/core/webview/service/web_session_service.dart';
import 'package:uuid/uuid.dart';

/// Offline-first orchestrator for every Angular form submitted via the bridge.
///
/// Angular never checks connectivity or persists data — it only awaits
/// `{ success, mode }` from Flutter. Flutter:
///   • checks reachability via [ConnectivityService]
///   • uploads immediately when online
///   • persists to local DB + drains the queue when offline
///   • retries transient failures with backoff
class OfflineSyncService {
  OfflineSyncService({
    required WebSubmissionRepository repository,
    required SurveyApiUploadService uploadService,
    required ConnectivityService connectivity,
    required RetryPolicy retryPolicy,
    Duration syncInterval = const Duration(minutes: 2),
    Uuid? uuid,
  }) : _repository = repository,
       _upload = uploadService,
       _connectivity = connectivity,
       _retryPolicy = retryPolicy,
       _syncInterval = syncInterval,
       _uuid = uuid ?? const Uuid();

  final WebSubmissionRepository _repository;
  final SurveyApiUploadService _upload;
  final ConnectivityService _connectivity;
  final RetryPolicy _retryPolicy;
  final Duration _syncInterval;
  final Uuid _uuid;

  StreamSubscription<bool>? _connectivitySub;
  Timer? _timer;
  bool _draining = false;

  /// Entry point for the JS bridge. Returns a map Angular can consume directly.
  Future<Map<String, dynamic>> submitForm({
    required String formType,
    required String endpoint,
    required Map<String, dynamic> data,
    String? clientId,
    String? authToken,
    String? officerId,
    String? districtId,
    String? deviceId,
  }) async {
    final String id = (clientId?.trim().isNotEmpty ?? false)
        ? clientId!.trim()
        : _uuid.v4();

    if (await _repository.isDuplicate(id)) {
      return WebFormSubmitResult(
        success: true,
        mode: 'duplicate',
        clientId: id,
        message: 'Already queued or submitted.',
      ).toBridgeMap();
    }

    final Map<String, dynamic> body = <String, dynamic>{
      ...data,
      'clientSubmissionId': id,
      if (officerId != null && officerId.isNotEmpty) 'submittedBy': officerId,
      'appVersion': kWebAppVersion,
      'deviceInfo': _deviceInfo(deviceId),
    };

    final WebFormSubmission submission = WebFormSubmission(
      clientId: id,
      formType: formType,
      endpoint: _normalizeEndpoint(endpoint),
      payload: body,
      authToken: authToken ?? '',
      createdAt: DateTime.now(),
    );

    if (await _connectivity.isOnline) {
      try {
        final Map<String, dynamic> server = await _upload.upload(submission);
        final WebFormSubmission synced = submission.copyWith(
          status: WebSubmissionStatus.synced,
          referenceId: server['referenceId']?.toString(),
          syncedAt: DateTime.now(),
        );
        await _repository.save(synced);
        return WebFormSubmitResult(
          success: true,
          mode: 'online',
          clientId: id,
          referenceId: synced.referenceId,
          message: server['message']?.toString(),
        ).toBridgeMap();
      } on DioException catch (e) {
        if (_isFatalClientError(e)) {
          return WebFormSubmitResult(
            success: false,
            mode: 'online',
            error: _dioMessage(e),
          ).toBridgeMap();
        }
        AppLogger.w('Online upload failed — queuing offline', error: e);
      }
    }

    await _repository.save(submission);
    unawaited(sync());
    return WebFormSubmitResult(
      success: true,
      mode: 'offline',
      clientId: id,
    ).toBridgeMap();
  }

  /// Watches connectivity and periodically drains the pending queue.
  void start() {
    _connectivitySub = _connectivity.onStatusChange.listen((bool online) {
      if (online) unawaited(sync());
    });
    _timer = Timer.periodic(_syncInterval, (_) => unawaited(sync()));
  }

  /// Uploads every pending record. Safe to call concurrently.
  Future<void> sync() async {
    if (_draining) return;
    if (!await _connectivity.isOnline) return;
    _draining = true;
    try {
      for (final WebFormSubmission pending in await _repository.pending()) {
        await _syncOne(pending);
      }
    } catch (e, s) {
      AppLogger.e('Web submission sync drain failed', error: e, stackTrace: s);
    } finally {
      _draining = false;
    }
  }

  Future<void> _syncOne(WebFormSubmission submission) async {
    final WebFormSubmission syncing = submission.copyWith(
      status: WebSubmissionStatus.syncing,
    );
    await _repository.save(syncing);

    try {
      final Map<String, dynamic> server = await _upload.upload(syncing);
      await _repository.save(
        syncing.copyWith(
          status: WebSubmissionStatus.synced,
          referenceId: server['referenceId']?.toString(),
          syncedAt: DateTime.now(),
          lastError: null,
        ),
      );
    } on DioException catch (e) {
      final int attempts = syncing.attempts + 1;
      if (_isFatalClientError(e) || !_retryPolicy.shouldRetry(attempts)) {
        await _repository.save(
          syncing.copyWith(
            status: WebSubmissionStatus.failed,
            attempts: attempts,
            lastError: _dioMessage(e),
          ),
        );
        return;
      }
      await _repository.save(
        syncing.copyWith(
          status: WebSubmissionStatus.pending,
          attempts: attempts,
          lastError: _dioMessage(e),
        ),
      );
      await Future<void>.delayed(_retryPolicy.delayFor(attempts - 1));
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _timer?.cancel();
  }

  static String _normalizeEndpoint(String endpoint) {
    final String trimmed = endpoint.trim();
    if (trimmed.isEmpty) return '/survey/submit';
    return trimmed.startsWith('/') ? trimmed : '/$trimmed';
  }

  static String _deviceInfo(String? deviceId) {
    final String platform = Platform.isIOS ? 'ios' : 'android';
    if (deviceId != null && deviceId.isNotEmpty) {
      return '$platform:$deviceId'.substring(
        0,
        '$platform:$deviceId'.length.clamp(0, 255),
      );
    }
    return platform;
  }

  static bool _isFatalClientError(DioException e) {
    final int? code = e.response?.statusCode;
    return code != null && code >= 400 && code < 500 && code != 408;
  }

  static String _dioMessage(DioException e) =>
      e.response?.data?.toString() ?? e.message ?? 'upload failed';
}
