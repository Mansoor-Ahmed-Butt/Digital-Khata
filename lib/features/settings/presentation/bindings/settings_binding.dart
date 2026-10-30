import 'package:get/get.dart';

import '../../../backup/presentation/controllers/backup_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BackupController>(() => BackupController());
  }
}
