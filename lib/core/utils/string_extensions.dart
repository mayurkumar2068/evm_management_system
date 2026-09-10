import 'package:flutter/widgets.dart';

extension StringExtensions on String {
  String get initials {
    final List<String> parts = trim()
        .split(RegExp(r'\s+'))
        .where((String p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

extension MobileMasking on String {
  String get masked =>
      length >= 4 ? '${'*' * (length - 4)}${substring(length - 4)}' : this;
}
