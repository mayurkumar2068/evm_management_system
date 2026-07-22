import 'package:evm_management_system/features/auth/domain/entities/user_role.dart';

/// Immutable domain representation of the authenticated officer.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.officerId,
    required this.fullName,
    required this.role,
    this.email,
    this.designation,
    this.stateCode,
    this.districtCode,
    this.electionId,
    this.psId,
    this.areaType,
    this.pollingStationCode,
    this.pollingStationName,
  });

  final String id;
  final String officerId;
  final String fullName;
  final UserRole role;
  final String? email;
  final String? designation;
  final String? stateCode;
  final String? districtCode;
  final int? electionId;
  final String? psId;
  final String? areaType;
  final String? pollingStationCode;
  final String? pollingStationName;

  bool get isPresidingOfficer =>
      role == UserRole.presidingOfficer || (psId?.isNotEmpty ?? false);

  /// Local guest session (no real officer login).
  bool get isGuest => id.startsWith('guest-');

  bool hasAnyRole(Set<UserRole> roles) => roles.isEmpty || roles.contains(role);
}
