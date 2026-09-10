import 'package:get/get.dart' hide Trans;

class OnboardingStore extends GetxService {
  bool seen = false;

  void markSeen() {
    seen = true;
  }
}
