import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import 'lock_controller.dart';

/// Decides where the app starts: onboarding, lock screen or the app shell.
class SplashController extends GetxController {
  final SettingsController _settings = Get.find<SettingsController>();
  final LockController _lock = Get.find<LockController>();

  /// True when the PIN pad should be shown.
  final RxBool showLock = false.obs;

  @override
  void onReady() {
    super.onReady();
    _route();
  }

  Future<void> _route() async {
    await _lock.ready;
    if (!_settings.onboarded.value) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (!_lock.isLocked.value) {
      Get.offAllNamed(AppRoutes.shell);
    } else {
      showLock.value = true;
    }
  }
}
