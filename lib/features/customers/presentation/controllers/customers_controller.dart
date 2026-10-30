import 'dart:async';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../auth/presentation/controllers/lock_controller.dart';
import '../../domain/contact_candidate.dart';
import '../../domain/customer.dart';
import '../../domain/customer_list_logic.dart';
import '../../domain/customers_repository.dart';
import '../../domain/save_customer_use_case.dart';

/// Customer list: live data from the local database, search, filter, sort,
/// archive and phone-contact import (FR-02).
class CustomersController extends GetxController {
  final CustomersRepository _repo = Get.find<CustomersRepository>();
  final SaveCustomerUseCase _save = Get.find<SaveCustomerUseCase>();
  final LockController _lock = Get.find<LockController>();

  final RxList<CustomerSummary> all = <CustomerSummary>[].obs;
  final RxList<CustomerSummary> visible = <CustomerSummary>[].obs;
  final RxString query = ''.obs;
  final Rx<CustomerFilter> filter = CustomerFilter.all.obs;
  final Rx<CustomerSort> sort = CustomerSort.name.obs;
  final Rx<UiStatus> status = UiStatus.loading.obs;
  final RxnString errorMessage = RxnString();
  final RxBool importing = false.obs;

  StreamSubscription<List<CustomerSummary>>? _subscription;
  Worker? _worker;

  @override
  void onInit() {
    super.onInit();
    _worker = everAll(<RxInterface<Object?>>[query, filter, sort], (_) => _recompute());
    _listen();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _worker?.dispose();
    super.onClose();
  }

  void retry() => _listen();

  void _listen() {
    _subscription?.cancel();
    status.value = UiStatus.loading;
    errorMessage.value = null;
    _subscription = _repo.watchSummaries().listen(
      (list) {
        all.assignAll(list);
        _recompute();
      },
      onError: (Object error, StackTrace stack) {
        CrashReporter.record(error, stack, reason: 'customers_stream');
        errorMessage.value = 'err_generic'.tr;
        status.value = UiStatus.error;
      },
    );
  }

  void _recompute() {
    visible.assignAll(CustomerListLogic.apply(
      all,
      query: query.value,
      filter: filter.value,
      sort: sort.value,
    ));
    status.value = all.isEmpty ? UiStatus.empty : UiStatus.data;
  }

  Future<void> archive(CustomerSummary summary) async {
    final id = summary.customer.id;
    final result = await guard<void>(() => _repo.setArchived(id, true));
    result.when(
      ok: (_) => AppSnack.show(
        'customer_archived'.tr,
        actionLabel: 'undo'.tr,
        onAction: () => guard<void>(() => _repo.setArchived(id, false)),
      ),
      err: (f) => AppSnack.error(f.messageKey),
    );
  }

  /// BR-06: bringing a customer back counts toward the free-plan limit.
  Future<void> unarchive(CustomerSummary summary) async {
    final result = await guard<void>(() async {
      await _save.ensureCanAddActive();
      await _repo.setArchived(summary.customer.id, false);
    });
    result.when(
      ok: (_) => AppSnack.showKey('customer_restored'),
      err: (f) => AppSnack.error(f.messageKey),
    );
  }

  // ---------------------------------------------------------------- contacts

  /// Asks for permission at the moment of use and returns the phone book.
  Future<List<ContactCandidate>?> loadContacts() async {
    if (importing.value) return null;
    importing.value = true;
    try {
      final granted =
          await _lock.external(() => FlutterContacts.requestPermission(readonly: true));
      if (!granted) {
        AppSnack.error('err_contacts_denied');
        return null;
      }
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final candidates = <ContactCandidate>[];
      for (final c in contacts) {
        final name = c.displayName.trim();
        if (name.runes.length < 2 || c.phones.isEmpty) continue;
        String? phone;
        for (final p in c.phones) {
          phone = Validators.normalizeMobile(p.number);
          if (phone != null) break;
        }
        candidates.add(ContactCandidate(
          name: name.runes.length > 60 ? String.fromCharCodes(name.runes.take(60)) : name,
          phone: phone,
        ));
      }
      candidates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      if (candidates.isEmpty) {
        AppSnack.showKey('contacts_empty');
        return null;
      }
      return candidates;
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'load_contacts');
      AppSnack.error('err_contacts_failed');
      return null;
    } finally {
      importing.value = false;
    }
  }

  /// Saves the chosen contacts. Skips numbers that already exist and stops
  /// cleanly at the free-plan limit instead of failing half way.
  Future<void> importContacts(List<ContactCandidate> selected) async {
    if (selected.isEmpty) return;
    importing.value = true;
    var added = 0;
    var skipped = 0;
    var limitReached = false;
    try {
      for (final c in selected) {
        final phone = c.phone;
        if (phone != null && await _repo.phoneExists(phone)) {
          skipped++;
          continue;
        }
        try {
          await _save(SaveCustomerInput(name: c.name, phone: phone ?? ''));
          added++;
        } on Failure catch (f) {
          if (f.messageKey == 'err_plan_limit') {
            limitReached = true;
            break;
          }
          skipped++;
        }
      }
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'import_contacts');
      AppSnack.error('err_generic');
      return;
    } finally {
      importing.value = false;
    }
    AppSnack.show(
      'import_result'.trParams(<String, String>{'added': '$added', 'skipped': '$skipped'}) +
          (limitReached ? '\n${'err_plan_limit'.tr}' : ''),
      isError: limitReached,
    );
  }
}
