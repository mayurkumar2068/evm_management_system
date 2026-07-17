import 'package:evm_management_system/core/error/failure.dart';
import 'package:evm_management_system/design_system/mpsec/mpsec_design_system.dart';
import 'package:evm_management_system/features/presiding_concern/di/presiding_concern_module.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared async session wrapper for presiding-officer screens.
class PresidingSessionScaffold extends StatefulWidget {
  const PresidingSessionScaffold({required this.builder, super.key});

  final Widget Function(BuildContext context, PresidingSession session) builder;

  @override
  State<PresidingSessionScaffold> createState() =>
      _PresidingSessionScaffoldState();
}

class _PresidingSessionScaffoldState extends State<PresidingSessionScaffold> {
  int _retryKey = 0;

  void _retry() => setState(() => _retryKey++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MpSecTokens.softBlueLight,
      body: StreamBuilder<PresidingSession>(
        key: ValueKey<int>(_retryKey),
        stream: PresidingConcernModule.watchSession(),
        builder: (BuildContext context, AsyncSnapshot<PresidingSession> snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: AppLoader());
          }
          if (snap.hasError) {
            return AppErrorState(
              failure: UnknownFailure(debugMessage: '${snap.error}'),
              onRetry: _retry,
            );
          }
          final PresidingSession? session = snap.data;
          if (session == null) {
            return const Center(child: AppLoader());
          }
          return widget.builder(context, session);
        },
      ),
    );
  }
}
