import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../features/auth/presentation/controllers/lock_controller.dart';
import '../routes/app_routes.dart';

/// Redirects to the lock screen whenever the app is locked (FR-01).
class LockMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<LockController>()) return null;
    if (Get.find<LockController>().isLocked.value) {
      return const RouteSettings(name: AppRoutes.splash);
    }
    return null;
  }
}
