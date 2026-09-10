import 'package:evm_management_system/features/service_auth/domain/entities/service_session.dart';

class ServiceLoginArgs {
  const ServiceLoginArgs({
    this.serviceTitle,
    this.loginKind,
    this.registrationAllowed,
  });

  factory ServiceLoginArgs.from(Object? raw) {
    if (raw is ServiceLoginArgs) return raw;
    if (raw is String) {
      return ServiceLoginArgs(serviceTitle: raw);
    }
    if (raw is Map) {
      final Object? kindRaw = raw['loginKind'] ?? raw['kind'];
      ServiceLoginKind? kind;
      if (kindRaw is ServiceLoginKind) {
        kind = kindRaw;
      } else if (kindRaw != null) {
        final String s = kindRaw.toString();
        if (s == ServiceLoginKind.presiding.name || s == 'presiding') {
          kind = ServiceLoginKind.presiding;
        } else if (s == ServiceLoginKind.survey.name || s == 'survey') {
          kind = ServiceLoginKind.survey;
        }
      }
      final Object? reg = raw['registrationAllowed'];
      return ServiceLoginArgs(
        serviceTitle:
            raw['serviceTitle']?.toString() ?? raw['title']?.toString(),
        loginKind: kind,
        registrationAllowed: reg is bool ? reg : null,
      );
    }
    return const ServiceLoginArgs();
  }

  final String? serviceTitle;
  final ServiceLoginKind? loginKind;

  final bool? registrationAllowed;
}
