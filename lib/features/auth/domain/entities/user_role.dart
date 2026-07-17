/// Roles that gate access to features and routes (used by route role guards).
enum UserRole {
  /// Full administrative access nationwide.
  superAdmin,

  /// State-level election officer.
  stateOfficer,

  /// District-level election officer.
  districtOfficer,

  /// Warehouse / store-room officer managing physical EVM stock.
  warehouseOfficer,

  /// Read-only auditor.
  auditor,

  /// Presiding officer at a polling station on election day.
  presidingOfficer,

  /// Unknown / unmapped role.
  unknown;

  static UserRole fromString(String? value) {
    if (value == null || value.trim().isEmpty) return UserRole.unknown;
    final String normalized = value.trim().toLowerCase().replaceAll('-', '_');
    if (normalized == 'presiding_officer' ||
        normalized == 'pithasin_adhikari' ||
        normalized == 'presidingofficer') {
      return UserRole.presidingOfficer;
    }
    return UserRole.values.firstWhere(
      (UserRole r) => r.name == normalized || r.name == value,
      orElse: () => UserRole.unknown,
    );
  }

  bool get canManageInventory =>
      this == superAdmin ||
      this == stateOfficer ||
      this == districtOfficer ||
      this == warehouseOfficer;

  bool get canViewAudit =>
      this == superAdmin || this == auditor || this == stateOfficer;
}
