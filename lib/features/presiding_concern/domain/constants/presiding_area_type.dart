/// Urban / rural body type returned by the PO Election login API.
enum PresidingAreaType {
  urban('U'),
  rural('R');

  const PresidingAreaType(this.code);

  final String code;

  bool get isUrban => this == PresidingAreaType.urban;
  bool get isRural => this == PresidingAreaType.rural;

  /// Returns null when [raw] is empty or not a known urban/rural code.
  static PresidingAreaType? tryParse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final String normalized = raw.trim().toUpperCase();
    return switch (normalized) {
      'U' || 'URBAN' => PresidingAreaType.urban,
      'R' || 'RURAL' => PresidingAreaType.rural,
      _ => null,
    };
  }

  static PresidingAreaType parse(
    String? raw, {
    PresidingAreaType fallback = urban,
  }) {
    return tryParse(raw) ?? fallback;
  }
}
