/// Placeholder contract for the citizen grievance module. Paths follow this
/// codebase's existing `/api/<Feature>/<action>` convention so the backend
/// team can confirm or repoint them without touching call sites.
abstract final class GrievanceEndpoints {
  static const String sendOtp = '/api/Grievance/send-otp';
  static const String verifyOtp = '/api/Grievance/verify-otp';
  static const String register = '/api/Grievance/register';
}
