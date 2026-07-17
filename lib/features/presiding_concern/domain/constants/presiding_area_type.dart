/// Urban / rural body type returned by the PO Election login API.
enum PresidingAreaType {
  urban('U'),
  rural('R');

  const PresidingAreaType(this.code);

  final String code;

  bool get isUrban => this == PresidingAreaType.urban;
  bool get isRural => this == PresidingAreaType.rural;

  static PresidingAreaType parse(
    String? raw, {
    PresidingAreaType fallback = urban,
  }) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final String normalized = raw.trim().toUpperCase();
    return switch (normalized) {
      'U' || 'URBAN' => PresidingAreaType.urban,
      'R' || 'RURAL' => PresidingAreaType.rural,
      _ => fallback,
    };
  }
}
