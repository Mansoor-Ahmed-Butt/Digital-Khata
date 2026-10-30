import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'pin_pad_controller.dart';

class OnboardingController extends GetxController {
  final SettingsController _settings = Get.find<SettingsController>();

  final RxString language = 'en'.obs;
  final RxnString shopError = RxnString();
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    language.value = _settings.locale.value.languageCode;
  }

  Future<void> selectLanguage(String code) async {
    language.value = code;
    await _settings.setLanguage(code);
  }

  Future<void> submit(String shopName) async {
    if (saving.value) return;
    saving.value = true;
    shopError.value = null;
    try {
      final result = await _settings.completeOnboarding(shopName);
      result.when(
        ok: (_) => Get.offNamed(
          AppRoutes.pinPad,
          arguments: <String, Object?>{
            RouteArgs.pinMode: PinMode.create,
            RouteArgs.fromOnboarding: true,
          },
        ),
        err: (f) => shopError.value = f.messageKey.tr,
      );
    } finally {
      saving.value = false;
    }
  }
}
