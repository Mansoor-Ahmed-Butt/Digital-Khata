import 'package:get/get.dart';

import '../../../customers/presentation/bindings/customers_binding.dart';
import '../../../dashboard/presentation/bindings/dashboard_binding.dart';
import '../../../statements/presentation/bindings/statements_binding.dart';
import '../controllers/nav_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavController>(() => NavController());
    DashboardBinding().dependencies();
    CustomersBinding().dependencies();
    StatementsBinding().dependencies();
  }
}
