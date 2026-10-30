import 'package:get/get.dart';

import '../controllers/onboarding_controller.dart';
import '../controllers/pin_pad_controller.dart';
import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(() => SplashController());
    Get.lazyPut<PinPadController>(() => PinPadController());
  }
}

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}

class PinPadBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PinPadController>(() => PinPadController());
  }
}
