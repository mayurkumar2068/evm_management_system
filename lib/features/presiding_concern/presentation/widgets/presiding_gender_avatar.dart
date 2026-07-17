import 'package:evm_management_system/features/presiding_concern/presentation/theme/presiding_ui_tokens.dart';
import 'package:evm_management_system/localization/locale_keys.dart';
import 'package:flutter/material.dart';

/// Voter gender categories used across presiding-officer turnout UI.
enum PresidingGenderType { male, female, other }

/// Asset paths for presiding gender avatars.
abstract final class PresidingGenderAssets {
  static const String male = 'assets/images/gender_avatar_male.png';
  static const String female = 'assets/images/gender_avatar_female.png';
  static const String other = 'assets/images/gender_avatar_other.png';

  static String assetFor(PresidingGenderType type) {
    return switch (type) {
      PresidingGenderType.male => male,
      PresidingGenderType.female => female,
      PresidingGenderType.other => other,
    };
  }

  static Color colorFor(PresidingGenderType type) {
    return PresidingUiTokens.genderColor(type);
  }

  static String labelKeyFor(PresidingGenderType type) {
    return switch (type) {
      PresidingGenderType.male => LocaleKeys.presidingMale,
      PresidingGenderType.female => LocaleKeys.presidingFemale,
      PresidingGenderType.other => LocaleKeys.presidingThirdGender,
    };
  }
}

/// Circular gender avatar used in live poll and turnout cards.
class PresidingGenderAvatar extends StatelessWidget {
  const PresidingGenderAvatar({
    required this.type,
    this.size = 52,
    this.showRing = true,
    super.key,
  });

  final PresidingGenderType type;
  final double size;
  final bool showRing;

  @override
  Widget build(BuildContext context) {
    final Color accent = PresidingGenderAssets.colorFor(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
        border: showRing
            ? Border.all(color: accent.withValues(alpha: 0.25), width: 2)
            : null,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: Image.asset(
            PresidingGenderAssets.assetFor(type),
            fit: BoxFit.cover,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) {
                  return Icon(
                    _fallbackIcon(type),
                    color: accent,
                    size: size * 0.5,
                  );
                },
          ),
        ),
      ),
    );
  }

  static IconData _fallbackIcon(PresidingGenderType type) {
    return switch (type) {
      PresidingGenderType.male => Icons.male_rounded,
      PresidingGenderType.female => Icons.female_rounded,
      PresidingGenderType.other => Icons.transgender_rounded,
    };
  }
}
