import 'package:get/get.dart';

class NavController extends GetxController {
  final RxInt tabIndex = 0.obs;

  void go(int index) {
    if (index < 0 || index > 3) return;
    tabIndex.value = index;
  }
}
