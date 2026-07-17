import 'package:easy_localization/easy_localization.dart';
import 'package:evm_management_system/localization/locale_keys.dart';

/// Reusable, localized form validators shared across feature screens.
abstract final class Validators {
  static String? requiredOfficerId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.authUsernameRequired.tr();
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return LocaleKeys.authPasswordRequired.tr();
    }
    if (value.length < 6) {
      return LocaleKeys.authPasswordTooShort.tr();
    }
    return null;
  }

  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return LocaleKeys.nominationValidationRequired.tr();
    }
    return null;
  }

  static String? mobile(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    final String digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10 || !RegExp(r'^[6-9]').hasMatch(digits)) {
      return LocaleKeys.nominationValidationMobile.tr();
    }
    return null;
  }

  static String? email(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value!.trim())) {
      return LocaleKeys.nominationValidationEmail.tr();
    }
    return null;
  }

  static String? pincode(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (!RegExp(r'^\d{6}$').hasMatch(value!.trim())) {
      return LocaleKeys.nominationValidationPincode.tr();
    }
    return null;
  }

  static String? aadhaar(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    final String digits = value!.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 12) {
      return LocaleKeys.nominationValidationAadhaar.tr();
    }
    return null;
  }

  static String? voterId(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    if (value!.trim().length < 10) {
      return LocaleKeys.nominationValidationVoterId.tr();
    }
    return null;
  }

  static String? dob(String? value) {
    final String? requiredError = required(value);
    if (requiredError != null) return requiredError;
    return null;
  }

  static String? ageMin25(String? dobValue) {
    final String? requiredError = dob(dobValue);
    if (requiredError != null) return requiredError;
    try {
      final DateTime dob = DateFormat('dd/MM/yyyy').parse(dobValue!.trim());
      final DateTime today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      if (age < 25) {
        return LocaleKeys.nominationValidationAgeMin.tr();
      }
    } on Object {
      return LocaleKeys.nominationValidationDob.tr();
    }
    return null;
  }

  static String? dropdownRequired<T>(T? value) {
    if (value == null) {
      return LocaleKeys.nominationValidationDropdown.tr();
    }
    return null;
  }
}
