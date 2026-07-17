import 'package:evm_management_system/localization/locale_keys.dart';

/// Domain-level representation of an error.
///
/// Repositories return [Failure]s (never throw) so the presentation layer can
/// render a localized, user-safe message via [localizationKey].
///
/// Implements [Exception] so it can also be surfaced through `AsyncValue.error`
/// without tripping the `only_throw_errors` lint.
sealed class Failure implements Exception {
  const Failure({required this.localizationKey, this.debugMessage});

  /// Key into the localization table used to display a safe message.
  final String localizationKey;

  /// Technical detail for logging only — never shown to end users.
  final String? debugMessage;

  @override
  String toString() => '$runtimeType(${debugMessage ?? localizationKey})';
}

/// Connectivity / transport level failure.
class NetworkFailure extends Failure {
  const NetworkFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorNetwork);
}

/// Failure returned by the backend (5xx, unexpected payloads, etc.).
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

/// Authentication failure (401).
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorUnauthorized);
}

/// Authorization failure (403).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorForbidden);
}

/// Resource not found (404).
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorNotFound);
}

/// Input/semantic validation failure (422) with optional per-field detail.
class ValidationFailure extends Failure {
  const ValidationFailure({
    this.fieldErrors = const <String, List<String>>{},
    super.debugMessage,
  }) : super(localizationKey: LocaleKeys.errorValidation);

  final Map<String, List<String>> fieldErrors;
}

/// Local persistence failure (Isar / cache / secure storage).
class CacheFailure extends Failure {
  const CacheFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorUnknown);
}

/// Device integrity / security policy violation.
class SecurityFailure extends Failure {
  const SecurityFailure({String? localizationKey, super.debugMessage})
    : super(localizationKey: localizationKey ?? LocaleKeys.errorUnknown);
}

/// Unclassified failure.
class UnknownFailure extends Failure {
  const UnknownFailure({super.debugMessage})
    : super(localizationKey: LocaleKeys.errorUnknown);
}
