import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/services/photo_storage.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../auth/presentation/controllers/lock_controller.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/domain/customers_repository.dart';
import '../../domain/ledger_transaction.dart';
import '../../domain/record_transaction_use_case.dart';

/// Add transaction (5.7): keypad amount, type, date, note, photo (FR-03).
class AddTransactionController extends GetxController {
  final RecordTransactionUseCase _record = Get.find<RecordTransactionUseCase>();
  final CustomersRepository _customers = Get.find<CustomersRepository>();
  final LockController _lock = Get.find<LockController>();
  final PhotoStorage _photos = PhotoStorage();

  String? customerId;
  final Rxn<Customer> customer = Rxn<Customer>();
  final RxString amount = ''.obs;
  final Rx<TxnType> type = TxnType.credit.obs;
  final Rx<DateTime> date = DateTime.now().obs;
  final RxnString photoPath = RxnString();
  final RxnString amountError = RxnString();
  final RxBool saving = false.obs;
  final RxBool pickingPhoto = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    customerId = routeArg<String>(RouteArgs.customerId, args);
    type.value = routeArg<TxnType>(RouteArgs.txnType, args) ?? TxnType.credit;
    final id = customerId;
    if (id != null) {
      _customers.getById(id).then((c) => customer.value = c).catchError((Object e, StackTrace s) {
        CrashReporter.record(e, s, reason: 'txn_customer');
        return null;
      });
    }
  }

  /// "2500.5" -> "2,500.5" for the big amount display.
  String get displayAmount {
    final raw = amount.value;
    if (raw.isEmpty) return '0';
    final dot = raw.indexOf('.');
    final whole = dot < 0 ? raw : raw.substring(0, dot);
    final grouped = whole.isEmpty ? '0' : Money.group(int.tryParse(whole) ?? 0);
    return dot < 0 ? grouped : '$grouped${raw.substring(dot)}';
  }

  void onKey(String key) {
    amountError.value = null;
    final cur = amount.value;
    if (key == '.') {
      if (cur.contains('.')) return;
      amount.value = cur.isEmpty ? '0.' : '$cur.';
      return;
    }
    final dot = cur.indexOf('.');
    if (dot >= 0) {
      if (cur.length - dot > 2) return; // max two decimals
    } else if (cur.length >= 10) {
      return;
    }
    if (cur == '0') {
      amount.value = key;
    } else {
      amount.value = '$cur$key';
    }
  }

  void onBackspace() {
    final cur = amount.value;
    if (cur.isEmpty) return;
    amount.value = cur.substring(0, cur.length - 1);
  }

  void setDate(DateTime d) => date.value = d;

  Future<void> pickPhoto(ImageSource source) async {
    if (pickingPhoto.value) return;
    pickingPhoto.value = true;
    try {
      final path = await _lock.external(() => _photos.pick(source));
      if (path != null) photoPath.value = path;
    } on Failure catch (f) {
      AppSnack.error(f.messageKey);
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pick_photo');
      AppSnack.error('err_photo_failed');
    } finally {
      pickingPhoto.value = false;
    }
  }

  Future<void> save(String note) async {
    if (saving.value) return;
    final id = customerId;
    if (id == null) {
      AppSnack.error('err_not_found');
      return;
    }
    final paisa = Money.parseToPaisa(amount.value);
    saving.value = true;
    try {
      final result = await guard<RecordTransactionOutcome>(() => _record(RecordTransactionInput(
            customerId: id,
            type: type.value,
            amountPaisa: paisa,
            date: date.value,
            note: note,
            photoPath: photoPath.value,
          )));
      result.when(
        ok: (outcome) {
          HapticFeedback.mediumImpact();
          Get.back<void>();
          AppSnack.showKey(outcome.exceedsCreditLimit ? 'warn_credit_limit' : 'entry_saved',
              isError: false);
        },
        err: (f) {
          if (f.messageKey == 'err_amount_invalid') {
            amountError.value = f.messageKey.tr;
          } else {
            AppSnack.error(f.messageKey);
          }
        },
      );
    } finally {
      saving.value = false;
    }
  }
}
