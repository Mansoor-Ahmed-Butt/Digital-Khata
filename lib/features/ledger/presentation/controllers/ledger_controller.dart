import 'dart:async';

import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/domain/customers_repository.dart';
import '../../domain/ledger_transaction.dart';
import '../../domain/transactions_repository.dart';

/// Customer ledger: balance header and dated timeline (FR-04).
class LedgerController extends GetxController {
  final CustomersRepository _customers = Get.find<CustomersRepository>();
  final TransactionsRepository _txns = Get.find<TransactionsRepository>();

  String? customerId;
  final Rxn<CustomerSummary> summary = Rxn<CustomerSummary>();
  final RxList<LedgerEntry> entries = <LedgerEntry>[].obs;
  final Rx<UiStatus> status = UiStatus.loading.obs;

  StreamSubscription<CustomerSummary?>? _summarySub;
  StreamSubscription<List<LedgerTransaction>>? _txnSub;
  List<LedgerTransaction> _latest = const <LedgerTransaction>[];

  @override
  void onInit() {
    super.onInit();
    customerId = routeArg<String>(RouteArgs.customerId, Get.arguments);
    if (customerId == null) {
      status.value = UiStatus.error;
    } else {
      _listen();
    }
  }

  @override
  void onClose() {
    _summarySub?.cancel();
    _txnSub?.cancel();
    super.onClose();
  }

  void retry() {
    if (customerId != null) _listen();
  }

  void _fail(Object e, StackTrace s) {
    CrashReporter.record(e, s, reason: 'ledger_stream');
    status.value = UiStatus.error;
  }

  void _listen() {
    final id = customerId!;
    _summarySub?.cancel();
    _txnSub?.cancel();
    status.value = UiStatus.loading;
    _summarySub = _customers.watchSummary(id).listen((s) {
      summary.value = s;
      _rebuild();
    }, onError: _fail);
    _txnSub = _txns.watchForCustomer(id).listen((list) {
      _latest = list;
      _rebuild();
    }, onError: _fail);
  }

  void _rebuild() {
    final s = summary.value;
    if (s == null) {
      // Customer missing (deleted) once data has arrived.
      if (_summaryLoadedOnce) status.value = UiStatus.error;
      _summaryLoadedOnce = true;
      return;
    }
    _summaryLoadedOnce = true;
    entries.assignAll(BalanceCalculator.timeline(s.customer.openingBalance, _latest));
    status.value = UiStatus.data;
  }

  bool _summaryLoadedOnce = false;

  /// BR-04: reminders only make sense when money is owed.
  bool get canRemind => (summary.value?.balance ?? 0) > 0;

  /// BR-05: soft delete with an Undo action; the balance recalculates.
  Future<void> deleteTransaction(LedgerTransaction t) async {
    final result = await guard<void>(() => _txns.softDelete(t.id));
    result.when(
      ok: (_) => AppSnack.show('entry_deleted'.tr,
          actionLabel: 'undo'.tr, onAction: () => guard<void>(() => _txns.restore(t.id))),
      err: (f) => AppSnack.error(f.messageKey),
    );
  }

  Future<void> archiveCustomer() async {
    final id = customerId;
    if (id == null) return;
    final result = await guard<void>(() => _customers.setArchived(id, true));
    result.when(
      ok: (_) {
        Get.back<void>();
        AppSnack.showKey('customer_archived');
      },
      err: (f) => AppSnack.error(f.messageKey),
    );
  }
}
