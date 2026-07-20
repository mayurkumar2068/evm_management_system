import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:evm_management_system/features/presiding_concern/domain/entities/presiding_entities.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:evm_management_system/features/presiding_concern/presentation/widgets/presiding_gender_avatar.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum PresidingTurnoutCardMode {
  /// Scheduled turnout slots: text fields + Save button.
  entry,

  /// Live poll: +/- triggers immediate API call.
  live,
}

/// Specialized UI for presiding-officer turnout entry.
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

  bool get _isReadOnly => widget.initialRecord?.isReadOnly ?? false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isExpanded) {
      return _CollapsedSummary(
        title: widget.title,
        record: widget.initialRecord,
        onTap: () => widget.onExpansionChanged?.call(true),
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
                          _SaveStatusBadge(
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
                _SaveStatusBadge(
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
                      widget.mode == PresidingTurnoutCardMode.live || _isReadOnly
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
    return Column(
      children: <Widget>[
        Container(
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
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 56,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _SaveStatusBadge extends StatelessWidget {
  const _SaveStatusBadge({
    required this.isSaved,
    required this.savedTime,
    this.isReadOnly = false,
  });

  final bool isSaved;
  final bool isReadOnly;
  final String savedTime;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          isReadOnly
              ? Icons.lock_rounded
              : isSaved
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: isReadOnly
              ? AppColors.slate500
              : isSaved
              ? AppColors.success
              : AppColors.slate400,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            isReadOnly
                ? LocaleKeys.presidingAlreadyRegistered.tr()
                : isSaved
                ? LocaleKeys.presidingSavedAt.tr(args: <String>[savedTime])
                : LocaleKeys.presidingNotSaved.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: isSaved ? AppColors.success : AppColors.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
    return SizedBox(
      width: 108,
      height: 48,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isReadOnly
              ? AppColors.slate400
              : isSaved
              ? AppColors.success
              : PresidingUiTokens.actionGreen,
          disabledBackgroundColor: AppColors.slate200,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    isSaved ? Icons.check_rounded : Icons.save_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isSaved
                        ? LocaleKeys.commonSaved.tr()
                        : LocaleKeys.commonSave.tr(),
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
              child: Icon(
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

class _CollapsedSummary extends StatelessWidget {
  const _CollapsedSummary({
    required this.title,
    required this.record,
    required this.onTap,
  });

  final String title;
  final TurnoutRecord? record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool saved = record?.savedAt != null;
    final int total =
        (record?.male ?? 0) +
        (record?.female ?? 0) +
        (record?.thirdGender ?? 0);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          Icon(
            saved ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
            color: saved ? AppColors.success : AppColors.slate400,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (saved)
                  Text(
                    record!.queueCount != null
                        ? LocaleKeys.presidingQueueSummary.tr(
                            args: <String>['${record!.queueCount}'],
                          )
                        : LocaleKeys.presidingTotalVotesSummary.tr(
                            args: <String>['$total'],
                          ),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.slate400,
          ),
        ],
      ),
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
        PresidingGenderAvatar(type: genderType, size: 36),
        const SizedBox(height: 4),
        Text(
          PresidingGenderAssets.labelKeyFor(genderType).tr(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 6),
        if (showSteps)
          Row(
            children: <Widget>[
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: disabled ? null : () => onDelta(-1),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _CountBox(
                    controller: controller,
                    disabled: disabled,
                    accentColor: color,
                  ),
                ),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: disabled ? null : () => onDelta(1),
              ),
            ],
          )
        else
          _CountBox(
            controller: controller,
            disabled: disabled,
            accentColor: color,
          ),
      ],
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox({
    required this.controller,
    required this.disabled,
    required this.accentColor,
  });

  final TextEditingController controller;
  final bool disabled;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        enabled: !disabled,
        readOnly: disabled,
        inputFormatters: <TextInputFormatter>[
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 10,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 2),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: onTap == null ? AppColors.slate100 : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Icon(
              icon,
              size: 16,
              color: onTap == null ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
        ),
      ),
    );
  }
}
