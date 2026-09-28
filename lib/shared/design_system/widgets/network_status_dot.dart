import 'package:evm_management_system/core/di/app_services.dart';
import 'package:evm_management_system/core/network/network_quality_service.dart';
import 'package:evm_management_system/shared/design_system/tokens/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;

/// Small dot that reflects live internet quality: green when the
/// connection is fast, amber when it is slow, red when there is none.
class NetworkStatusDot extends StatelessWidget {
  const NetworkStatusDot({super.key, this.size = 10});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final NetworkQuality quality = AppServices.networkQuality.quality.value;
      final Color color = switch (quality) {
        NetworkQuality.good => AppColors.success,
        NetworkQuality.poor => AppColors.warning,
        NetworkQuality.offline => AppColors.error,
      };
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 4,
              spreadRadius: 0.5,
            ),
          ],
        ),
      );
    });
  }
}
