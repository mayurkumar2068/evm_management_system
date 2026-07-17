import 'package:flutter/widgets.dart';

extension StringExtensions on String {
  /// Extract initials from a name (e.g., "Rajesh Sharma" -> "RS").
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
