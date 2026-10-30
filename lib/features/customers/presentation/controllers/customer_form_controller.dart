import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../domain/customer.dart';
import '../../domain/customers_repository.dart';
import '../../domain/save_customer_use_case.dart';

/// Add / edit customer form logic. Text controllers live in the view's State
/// so they are never used after disposal.
class CustomerFormController extends GetxController {
  final CustomersRepository _repo = Get.find<CustomersRepository>();
  final SaveCustomerUseCase _save = Get.find<SaveCustomerUseCase>();

  String? customerId;
  Customer? initial;

  final Rx<UiStatus> status = UiStatus.loading.obs;
  final RxBool saving = false.obs;
  final RxnString nameError = RxnString();
  final RxnString phoneError = RxnString();
  final RxnString balanceError = RxnString();
  final RxnString limitError = RxnString();

  bool get isEdit => customerId != null;

  @override
  void onInit() {
    super.onInit();
    customerId = routeArg<String>(RouteArgs.customerId, Get.arguments);
    if (customerId == null) {
      status.value = UiStatus.data;
    } else {
      load();
    }
  }

  Future<void> load() async {
    status.value = UiStatus.loading;
    final result = await guard<Customer?>(() => _repo.getById(customerId!));
    result.when(
      ok: (customer) {
        initial = customer;
        status.value = customer == null ? UiStatus.error : UiStatus.data;
      },
      err: (_) => status.value = UiStatus.error,
    );
  }

  void _clearErrors() {
    nameError.value = null;
    phoneError.value = null;
    balanceError.value = null;
    limitError.value = null;
  }

  Future<void> save({
    required String name,
    required String phone,
    required String address,
    required String openingBalance,
    required String creditLimit,
    required String notes,
  }) async {
    if (saving.value) return;
    _clearErrors();

    final nameKey = Validators.name(name);
    final phoneKey = Validators.phone(phone);

    int? balance = 0;
    String? balanceKey;
    if (openingBalance.trim().isNotEmpty) {
      balance = Money.parseToPaisa(openingBalance, allowNegative: true);
      balanceKey = Validators.openingBalance(balance);
    }

    int? limit;
    String? limitKey;
    if (creditLimit.trim().isNotEmpty) {
      limit = Money.parseToPaisa(creditLimit);
      limitKey = Validators.creditLimit(creditLimit, limit);
    }

    nameError.value = nameKey?.tr;
    phoneError.value = phoneKey?.tr;
    balanceError.value = balanceKey?.tr;
    limitError.value = limitKey?.tr;
    if (nameKey != null || phoneKey != null || balanceKey != null || limitKey != null) return;

    saving.value = true;
    try {
      final result = await guard<SaveCustomerOutcome>(() => _save(SaveCustomerInput(
            id: customerId,
            name: name,
            phone: phone,
            address: address,
            openingBalance: balance ?? 0,
            creditLimit: limit,
            notes: notes,
          )));
      result.when(
        ok: (outcome) {
          Get.back<String>(result: outcome.customer.id);
          AppSnack.showKey(outcome.duplicatePhone ? 'customer_saved_duplicate' : 'customer_saved');
        },
        err: (f) => AppSnack.error(f.messageKey),
      );
    } finally {
      saving.value = false;
    }
  }
}
