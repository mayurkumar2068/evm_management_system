import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/features/presiding_concern/domain/turnout_count_validator.dart';

/// Localizes [TurnoutCountValidationResult] for snackbars.
String formatTurnoutValidationMessage(TurnoutCountValidationResult result) {
  final String? key = result.messageKey;
  if (key == null) return '';
  if (result.categoryKey != null && result.limit != null) {
    return key.tr(
      args: <String>[result.categoryKey!.tr(), '${result.limit}'],
    );
  }
  if (result.limit != null) {
    return key.tr(args: <String>['${result.limit}']);
  }
  return key.tr();
}
