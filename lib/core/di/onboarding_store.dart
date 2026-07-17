import 'package:get/get.dart' hide Trans;

/// Persists whether first-run onboarding was completed (seeded at bootstrap).
class OnboardingStore extends GetxService {
  bool seen = false;

  void markSeen() {
    seen = true;
  }
}
