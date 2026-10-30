import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/database/local_user.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/ids.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/domain/customers_repository.dart';
import '../../domain/subscription.dart';
import '../../domain/subscriptions_repository.dart';

/// Free / Pro plan state (FR-10). Registered permanently.
class SubscriptionController extends GetxController {
  final SubscriptionsRepository _repo = Get.find<SubscriptionsRepository>();
  final CustomersRepository _customers = Get.find<CustomersRepository>();

  final Rx<Plan> plan = Plan.free.obs;
  final Rxn<DateTime> expiresAt = Rxn<DateTime>();
  final RxInt activeCustomers = 0.obs;

  StreamSubscription<List<Subscription>>? _planSub;
  StreamSubscription<List<CustomerSummary>>? _customerSub;

  bool get isPro => plan.value == Plan.pro;
  int get limit => kFreePlanCustomerLimit;
  bool get customerLimitReached => !isPro && activeCustomers.value >= limit;

  @override
  void onInit() {
    super.onInit();
    guard<Subscription>(() => _repo.current());
    _planSub = _repo.watchAll().listen((list) {
      final s = list.isEmpty ? null : list.first;
      plan.value = (s != null && s.isPro()) ? Plan.pro : Plan.free;
      expiresAt.value = s?.expiresAt;
    }, onError: (Object e, StackTrace st) => CrashReporter.record(e, st, reason: 'plan_stream'));
    _customerSub = _customers.watchSummaries().listen((list) {
      activeCustomers.value = list.where((c) => !c.customer.isArchived).length;
    }, onError: (Object e, StackTrace st) => CrashReporter.record(e, st, reason: 'count_stream'));
  }

  @override
  void onClose() {
    _planSub?.cancel();
    _customerSub?.cancel();
    super.onClose();
  }

  /// Store purchase is wired through Google Play Billing (`in_app_purchase`)
  /// once products exist in Play Console. Until then, explain honestly.
  void upgrade() => AppSnack.showKey('upgrade_coming_soon');

  /// Debug builds only: flip the plan to test the 50-customer limit.
  Future<void> debugTogglePlan() async {
    if (!kDebugMode) return;
    await guard<void>(() async {
      final current = await _repo.current();
      final now = DateTime.now().toUtc();
      await _repo.upsert(Subscription(
        id: current.id.isEmpty ? newId() : current.id,
        userId: kLocalUserId,
        createdAt: current.createdAt,
        updatedAt: now,
        plan: isPro ? Plan.free : Plan.pro,
      ));
    });
  }
}
