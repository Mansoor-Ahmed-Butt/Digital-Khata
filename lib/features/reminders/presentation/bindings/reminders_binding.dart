import 'package:get/get.dart';

import '../controllers/reminder_controller.dart';

class RemindersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReminderController>(() => ReminderController());
  }
}
