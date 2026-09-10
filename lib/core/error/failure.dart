import 'package:evm_management_system/localization/locale_keys.dart';

sealed class Failure implements Exception {
  const Failure({required this.localizationKey, this.debugMessage});

  final String localizationKey;

  final String? debugMessage;

  @override
  String toString() => '$runtimeType(${debugMessage ?? localizationKey})';
}

class NetworkFailure extends Failure {
  const NetworkFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorNetwork);
}

class ApiFailure extends Failure {
  const ApiFailure({
    this.statusCode,
    this.errorCode,
    String? localizationKey,
    super.debugMessage,
  }) : super(localizationKey: localizationKey ?? LocaleKeys.errorServer);

  final int? statusCode;
  final String? errorCode;
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorUnauthorized);
}

class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorForbidden);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorNotFound);
}

class ValidationFailure extends Failure {
  const ValidationFailure({
    this.fieldErrors = const <String, List<String>>{},
    super.debugMessage,
  }) : super(localizationKey: LocaleKeys.errorValidation);

  final Map<String, List<String>> fieldErrors;
}

class CacheFailure extends Failure {
  const CacheFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorUnknown);
}

class SecurityFailure extends Failure {
  const SecurityFailure({String? localizationKey, super.debugMessage})
    : super(localizationKey: localizationKey ?? LocaleKeys.errorUnknown);
}

class UnknownFailure extends Failure {
  const UnknownFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorUnknown);
}
