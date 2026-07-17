/// Value object carrying the inputs required to authenticate.
class LoginCredentials {
  const LoginCredentials({
    required this.officerId,
    required this.password,
    this.electionId,
  });

  final String officerId;
  final String password;

  /// Active election cycle ID from deployment config (sent on login).
  final int? electionId;
}
