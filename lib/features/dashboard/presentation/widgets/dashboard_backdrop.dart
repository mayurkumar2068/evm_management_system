import 'package:evm_management_system/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Soft multicolor wash on the light dashboard canvas.
class DashboardBackdrop extends StatelessWidget {
  const DashboardBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isAppDark;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: isDark
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        AppColors.darkBackground,
                        AppColors.darkBackground.withValues(alpha: 0.95),
                        AppColors.darkSurface.withValues(alpha: 0.9),
                        AppColors.darkBackground,
                      ],
                      stops: const <double>[0.0, 0.35, 0.7, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFFD7E9FB),
                        Color(0xFFE8F3FC),
                        Color(0xFFE5F8F1),
                        Color(0xFFDCEEF9),
                      ],
                      stops: <double>[0.0, 0.32, 0.68, 1.0],
                    ),
            ),
          ),
          Positioned(
            top: -48,
            right: -28,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.16),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: isDark ? 0.06 : 0.12),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.saffron.withValues(alpha: isDark ? 0.05 : 0.10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
