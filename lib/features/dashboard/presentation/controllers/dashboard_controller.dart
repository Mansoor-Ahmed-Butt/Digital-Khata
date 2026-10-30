import 'dart:async';

import 'package:get/get.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/ui_status.dart';
import '../../domain/dashboard_data.dart';
import '../../domain/dashboard_repository.dart';

class DashboardController extends GetxController {
  final DashboardRepository _repo = Get.find<DashboardRepository>();

  final Rx<DashboardData> data = const DashboardData().obs;
  final Rx<UiStatus> status = UiStatus.loading.obs;
  StreamSubscription<DashboardData>? _sub;

  @override
  void onInit() {
    super.onInit();
    listen();
  }

  void listen() {
    _sub?.cancel();
    status.value = UiStatus.loading;
    _sub = _repo.watch().listen(
      (d) {
        data.value = d;
        status.value = d.customerCount == 0 ? UiStatus.empty : UiStatus.data;
      },
      onError: (Object e, StackTrace s) {
        CrashReporter.record(e, s, reason: 'dashboard');
        status.value = UiStatus.error;
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
