enum UserRole {
  superAdmin,

  stateOfficer,

  districtOfficer,

  warehouseOfficer,

  auditor,

  presidingOfficer,

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
