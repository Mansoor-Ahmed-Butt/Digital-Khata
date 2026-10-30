import 'package:get/get.dart';

import '../controllers/statement_controller.dart';

/// Used by the Reports tab (inside the shell).
class StatementsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<StatementController>(() => StatementController());
  }
}
