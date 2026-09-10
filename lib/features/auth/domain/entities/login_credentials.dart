class LoginCredentials {
  const LoginCredentials({
    required this.officerId,
    required this.password,
    this.electionId,
  });

  final String officerId;
  final String password;

  final int? electionId;
}
