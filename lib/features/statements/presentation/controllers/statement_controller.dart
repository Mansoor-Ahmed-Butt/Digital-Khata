import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:printing/printing.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../auth/presentation/controllers/lock_controller.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/domain/customers_repository.dart';
import '../../../ledger/domain/ledger_transaction.dart';
import '../../../ledger/domain/transactions_repository.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/statement_pdf.dart';
import '../../domain/statement_data.dart';

/// Reports tab (date range, summary, customer pick) and the statement screen (FR-08).
class StatementController extends GetxController {
  final CustomersRepository _customers = Get.find<CustomersRepository>();
  final TransactionsRepository _txns = Get.find<TransactionsRepository>();
  final SettingsController _settings = Get.find<SettingsController>();
  final LockController _lock = Get.find<LockController>();

  final Rx<DateTime> from = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final Rx<DateTime> to = AppDates.today().obs;
  final Rx<RangeTotals> totals = const RangeTotals().obs;
  final RxList<CustomerSummary> customerList = <CustomerSummary>[].obs;
  final Rxn<String> selectedCustomerId = Rxn<String>();

  // Statement screen
  final Rx<UiStatus> status = UiStatus.loading.obs;
  final Rxn<Uint8List> pdfBytes = Rxn<Uint8List>();
  final Rxn<StatementData> statement = Rxn<StatementData>();
  final RxBool sharing = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    final id = routeArg<String>(RouteArgs.customerId, args);
    if (Get.currentRoute == AppRoutes.statement || id != null) {
      selectedCustomerId.value = id;
      final f = routeArg<DateTime>(RouteArgs.from, args);
      final t = routeArg<DateTime>(RouteArgs.to, args);
      if (f != null) from.value = f;
      if (t != null) to.value = t;
      buildStatement();
    } else {
      refreshSummary();
    }
  }

  Future<void> setRange(DateTime start, DateTime end) async {
    from.value = DateTime(start.year, start.month, start.day);
    to.value = DateTime(end.year, end.month, end.day);
    await refreshSummary();
  }

  Future<void> refreshSummary() async {
    final result = await guard<void>(() async {
      totals.value = await _txns.totalsBetween(from.value, to.value);
      final list = await _customers.watchSummaries().first;
      customerList.assignAll(list.where((s) => !s.customer.isArchived));
    });
    result.when(ok: (_) {}, err: (f) => AppSnack.error(f.messageKey));
  }

  Future<void> buildStatement() async {
    final id = selectedCustomerId.value;
    if (id == null) {
      status.value = UiStatus.error;
      return;
    }
    status.value = UiStatus.loading;
    final result = await guard<StatementData>(() async {
      final customer = await _customers.getById(id);
      if (customer == null) throw const Failure('err_not_found');
      final all = await _txns.forCustomerBetween(id);
      return StatementData.assemble(
        shopName: _settings.shopName.value,
        customer: customer,
        from: from.value,
        to: to.value,
        allTransactions: all,
      );
    });
    if (result is Err<StatementData>) {
      status.value = UiStatus.error;
      return;
    }
    final data = (result as Ok<StatementData>).value;
    final pdf = await guard<Uint8List>(() => StatementPdf.build(data));
    if (pdf is Ok<Uint8List>) {
      statement.value = data;
      pdfBytes.value = pdf.value;
      status.value = UiStatus.data;
    } else {
      status.value = UiStatus.error;
    }
  }

  Future<void> share() async {
    final bytes = pdfBytes.value;
    final data = statement.value;
    if (bytes == null || data == null || sharing.value) return;
    sharing.value = true;
    try {
      final safeName = data.customer.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
      await _lock.external(() => Printing.sharePdf(
            bytes: bytes,
            filename: 'statement_${safeName.isEmpty ? 'customer' : safeName}.pdf',
          ));
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'share_pdf');
      AppSnack.error('err_share_failed');
    } finally {
      sharing.value = false;
    }
  }
}
