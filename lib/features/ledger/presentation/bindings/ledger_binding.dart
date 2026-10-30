import 'package:get/get.dart';

import '../controllers/add_transaction_controller.dart';
import '../controllers/ledger_controller.dart';

class LedgerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LedgerController>(() => LedgerController());
  }
}

class AddTransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AddTransactionController>(() => AddTransactionController());
  }
}
