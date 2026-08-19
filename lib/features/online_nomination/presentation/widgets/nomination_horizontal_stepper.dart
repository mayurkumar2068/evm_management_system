import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/online_nomination/presentation/models/nomination_models.dart';
import 'package:evm_management_system/features/online_nomination/presentation/widgets/nomination_theme.dart';
import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

class NominationHorizontalStepper extends StatelessWidget {
  const NominationHorizontalStepper({
    required this.steps,
    required this.currentStep,
    super.key,
  });

  final List<NominationStepItem> steps;
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < steps.length; i++) ...<Widget>[
            _StepNode(
              index: i,
              label: steps[i].labelKey.tr(),
              isActive: i == currentStep,
              isCompleted: i < currentStep,
            ),
            if (i < steps.length - 1)
              Container(
                width: 24,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < currentStep ? AppColors.primary : AppColors.slate200,
              ),
          ],
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  final int index;
  final String label;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final bool isDone = isCompleted;
    final bool isInProgress = isActive && !isCompleted;

    final Decoration nodeDecoration = isDone || isInProgress
        ? NominationTheme.gradientCircle()
        : const BoxDecoration(
            color: AppColors.slate300,
            shape: BoxShape.circle,
          );

    final Color textColor = isActive || isCompleted
        ? AppColors.primary
        : AppColors.slate500;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: nodeDecoration,
          child: isCompleted
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : Text(
                  '${index + 1}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.variant(
              AppTextStyles.caption,
              color: textColor,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }
}
