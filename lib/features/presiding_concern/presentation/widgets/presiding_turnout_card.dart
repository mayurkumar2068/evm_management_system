import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_count_validator.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/utils/turnout_validation_message.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_collapsed_summary.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_count_box.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_avatar.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_stat_column.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_save_status_badge.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_step_button.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_theme_button.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PresidingTurnoutCardMode { entry, live }

class PresidingTurnoutCard extends StatefulWidget {
  const PresidingTurnoutCard({
    required this.title,
    required this.slotId,
    required this.onSave,
    this.initialRecord,
    this.onSaved,
    this.mode = PresidingTurnoutCardMode.entry,
    this.isExpanded = true,
    this.onExpansionChanged,
    this.queueOnly = false,
    this.embedded = false,
    this.forceReadOnly = false,
    this.interactionEnabled = true,
    super.key,
  });

  final String title;
  final String slotId;
  final TurnoutRecord? initialRecord;
  final VoidCallback? onSaved;
  final PresidingTurnoutCardMode mode;
  final bool isExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  final bool queueOnly;
  final bool embedded;
  final bool forceReadOnly;

  final bool interactionEnabled;

  final Future<void> Function({
    int? male,
    int? female,
    int? thirdGender,
    int? queueCount,
  })
  onSave;

  @override
  State<PresidingTurnoutCard> createState() => _PresidingTurnoutCardState();
}

class _PresidingTurnoutCardState extends State<PresidingTurnoutCard> {
  late TextEditingController _maleCtrl;
  late TextEditingController _femaleCtrl;
  late TextEditingController _thirdGenderCtrl;
  late TextEditingController _queueCtrl;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(covariant PresidingTurnoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_busy ||
        _recordValuesEqual(oldWidget.initialRecord, widget.initialRecord)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _busy) return;
      _syncControllers();
    });
  }

  bool _recordValuesEqual(TurnoutRecord? a, TurnoutRecord? b) {
    return (a?.male ?? 0) == (b?.male ?? 0) &&
        (a?.female ?? 0) == (b?.female ?? 0) &&
        (a?.thirdGender ?? 0) == (b?.thirdGender ?? 0) &&
        (a?.queueCount ?? 0) == (b?.queueCount ?? 0);
  }

  void _initControllers() {
    _maleCtrl = TextEditingController(
      text: '${widget.initialRecord?.male ?? 0}',
    );
    _femaleCtrl = TextEditingController(
      text: '${widget.initialRecord?.female ?? 0}',
    );
    _thirdGenderCtrl = TextEditingController(
      text: '${widget.initialRecord?.thirdGender ?? 0}',
    );
    _queueCtrl = TextEditingController(
      text: '${widget.initialRecord?.queueCount ?? 0}',
    );
  }

  void _syncControllers() {
    _maleCtrl.text = '${widget.initialRecord?.male ?? 0}';
    _femaleCtrl.text = '${widget.initialRecord?.female ?? 0}';
    _thirdGenderCtrl.text = '${widget.initialRecord?.thirdGender ?? 0}';
    _queueCtrl.text = '${widget.initialRecord?.queueCount ?? 0}';
  }

  @override
  void dispose() {
    _maleCtrl.dispose();
    _femaleCtrl.dispose();
    _thirdGenderCtrl.dispose();
    _queueCtrl.dispose();
    super.dispose();
  }

  int _val(TextEditingController ctrl) => int.tryParse(ctrl.text) ?? 0;

  Future<void> _handleLiveDelta({
    required TextEditingController targetCtrl,
    required int delta,
  }) async {
    if (_busy || _isReadOnly) return;

    final int previous = _val(targetCtrl);
    final int next = previous + delta;
    if (next < 0) return;
    if (next > TurnoutCountValidator.maxEnterableCount) return;

    targetCtrl.text = '$next';
    setState(() => _busy = true);

    try {
      await widget.onSave(
        male: _val(_maleCtrl),
        female: _val(_femaleCtrl),
        thirdGender: _val(_thirdGenderCtrl),
        queueCount: widget.queueOnly ? _val(_queueCtrl) : null,
      );
      widget.onSaved?.call();
    } on TurnoutCountValidationException catch (e) {
      targetCtrl.text = '$previous';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatTurnoutValidationMessage(e.result))),
        );
      }
    } catch (e) {
      targetCtrl.text = '$previous';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleKeys.presidingUpdateFailed.tr(args: <String>['$e']),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _handleSave() async {
    if (_busy || _isReadOnly) return;
    setState(() => _busy = true);
    try {
      await widget.onSave(
        male: widget.queueOnly ? null : _val(_maleCtrl),
        female: widget.queueOnly ? null : _val(_femaleCtrl),
        thirdGender: widget.queueOnly ? null : _val(_thirdGenderCtrl),
        queueCount: widget.queueOnly ? _val(_queueCtrl) : null,
      );
      widget.onSaved?.call();
    } on TurnoutCountValidationException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(formatTurnoutValidationMessage(e.result))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleKeys.presidingSaveFailed.tr(args: <String>['$e']),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _isReadOnly =>
      widget.forceReadOnly || (widget.initialRecord?.isReadOnly ?? false);

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return PresidingCollapsedSummary(
        title: widget.title,
        record: widget.initialRecord,
        locked: !widget.interactionEnabled,
        onTap: widget.interactionEnabled
            ? () => widget.onExpansionChanged?.call(true)
            : null,
      );
    }

    final bool isSaved = widget.initialRecord?.savedAt != null;
    final String savedTime = isSaved
        ? DateFormat('hh:mm a').format(widget.initialRecord!.savedAt!)
        : '';

    final Widget content = widget.queueOnly
        ? _QueueCountSection(
            queueCtrl: _queueCtrl,
            isSaved: isSaved,
            isReadOnly: _isReadOnly,
            busy: _busy,
            onSave: _handleSave,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!widget.embedded)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _TimeBadge(label: widget.title),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            LocaleKeys.presidingVoterTurnout.tr(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          PresidingSaveStatusBadge(
                            isSaved: isSaved,
                            isReadOnly: _isReadOnly,
                            savedTime: savedTime,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else
                PresidingSaveStatusBadge(
                  isSaved: isSaved,
                  isReadOnly: _isReadOnly,
                  savedTime: savedTime,
                ),
              if (!widget.embedded) const SizedBox(height: 16),
              if (widget.embedded) const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: _GenderField(
                      genderType: PresidingGenderType.male,
                      controller: _maleCtrl,
                      showSteps: widget.mode == PresidingTurnoutCardMode.live,
                      disabled: _busy || _isReadOnly,
                      onDelta: (int d) =>
                          _handleLiveDelta(targetCtrl: _maleCtrl, delta: d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GenderField(
                      genderType: PresidingGenderType.female,
                      controller: _femaleCtrl,
                      showSteps: widget.mode == PresidingTurnoutCardMode.live,
                      disabled: _busy || _isReadOnly,
                      onDelta: (int d) =>
                          _handleLiveDelta(targetCtrl: _femaleCtrl, delta: d),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GenderField(
                      genderType: PresidingGenderType.other,
                      controller: _thirdGenderCtrl,
                      showSteps: widget.mode == PresidingTurnoutCardMode.live,
                      disabled: _busy || _isReadOnly,
                      onDelta: (int d) => _handleLiveDelta(
                        targetCtrl: _thirdGenderCtrl,
                        delta: d,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: _SaveActionButton(
                  isSaved: isSaved,
                  isReadOnly: _isReadOnly,
                  busy: _busy,
                  onPressed:
                      widget.mode == PresidingTurnoutCardMode.live ||
                          _isReadOnly
                      ? null
                      : _handleSave,
                ),
              ),
            ],
          );

    if (widget.embedded) return content;

    return AppCard(padding: const EdgeInsets.all(16), child: content);
  }
}

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.access_time_rounded,
        color: AppColors.primary,
        size: 22,
      ),
    );
  }
}

class _SaveActionButton extends StatelessWidget {
  const _SaveActionButton({
    required this.isSaved,
    required this.busy,
    this.isReadOnly = false,
    this.onPressed,
  });

  final bool isSaved;
  final bool isReadOnly;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool disabled = busy || isReadOnly || onPressed == null;
    if (isReadOnly) {
      return SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.slate400,
            disabledBackgroundColor: AppColors.slate200,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            minimumSize: const Size(108, 48),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.lock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.commonSaved.tr(),
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: 120,
      child: PresidingThemeButton(
        onPressed: disabled ? null : onPressed,
        isLoading: busy,
        icon: isSaved ? Icons.check_rounded : Icons.save_outlined,
        label: isSaved
            ? LocaleKeys.commonSaved.tr()
            : LocaleKeys.commonSave.tr(),
        height: 48,
        expanded: true,
      ),
    );
  }
}

class _QueueCountSection extends StatelessWidget {
  const _QueueCountSection({
    required this.queueCtrl,
    required this.isSaved,
    required this.isReadOnly,
    required this.busy,
    required this.onSave,
  });

  final TextEditingController queueCtrl;
  final bool isSaved;
  final bool isReadOnly;
  final bool busy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: PresidingUiTokens.queueAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: PresidingUiTokens.queueAccent,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    LocaleKeys.presidingCurrentQueueCount.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocaleKeys.presidingQueueHint.tr(),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: queueCtrl,
          enabled: !isReadOnly && !busy,
          readOnly: isReadOnly,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
            const ReplaceInitialZeroFormatter(),
            LengthLimitingTextInputFormatter(
              TurnoutCountValidator.maxInputDigits,
            ),
          ],
          decoration: InputDecoration(
            hintText: LocaleKeys.presidingEnterNumber.tr(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: _SaveActionButton(
            isSaved: isSaved,
            isReadOnly: isReadOnly,
            busy: busy,
            onPressed: isReadOnly ? null : onSave,
          ),
        ),
      ],
    );
  }
}

class _GenderField extends StatelessWidget {
  const _GenderField({
    required this.genderType,
    required this.controller,
    required this.showSteps,
    required this.disabled,
    required this.onDelta,
  });

  final PresidingGenderType genderType;
  final TextEditingController controller;
  final bool showSteps;
  final bool disabled;
  final FutureOr<void> Function(int delta) onDelta;

  @override
  Widget build(BuildContext context) {
    final Color color = PresidingGenderAssets.colorFor(genderType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        PresidingGenderStatColumn(
          genderType: genderType,
          avatarSize: 36,
          labelFontSize: 10,
        ),
        const SizedBox(height: 6),
        if (showSteps)
          Row(
            children: <Widget>[
              PresidingStepButton(
                icon: Icons.remove_rounded,
                onPressed: () => onDelta(-1),
                enabled: !disabled,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PresidingCountBox(
                    controller: controller,
                    disabled: disabled,
                    accentColor: color,
                  ),
                ),
              ),
              PresidingStepButton(
                icon: Icons.add_rounded,
                onPressed: () => onDelta(1),
                enabled: !disabled,
              ),
            ],
          )
        else
          PresidingCountBox(
            controller: controller,
            disabled: disabled,
            accentColor: color,
          ),
      ],
    );
  }
}
