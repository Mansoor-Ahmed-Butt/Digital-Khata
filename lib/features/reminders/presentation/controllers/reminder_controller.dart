import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/database/local_user.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/utils/ids.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../auth/presentation/controllers/lock_controller.dart';
import '../../../customers/domain/customer.dart';
import '../../../customers/domain/customers_repository.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/reminder.dart';
import '../../domain/reminders_repository.dart';

/// Reminder composer (FR-05): pre-filled polite message, WhatsApp or SMS.
class ReminderController extends GetxController {
  final CustomersRepository _customers = Get.find<CustomersRepository>();
  final RemindersRepository _reminders = Get.find<RemindersRepository>();
  final SettingsController _settings = Get.find<SettingsController>();
  final LockController _lock = Get.find<LockController>();

  static const List<String> templates = <String>['tpl_friendly', 'tpl_firm', 'tpl_short'];

  final Rxn<CustomerSummary> summary = Rxn<CustomerSummary>();
  final Rx<UiStatus> status = UiStatus.loading.obs;
  final RxString template = 'tpl_friendly'.obs;
  final Rx<ReminderChannel> channel = ReminderChannel.whatsapp.obs;
  final RxString message = ''.obs;
  final RxBool sending = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final id = routeArg<String>(RouteArgs.customerId, Get.arguments);
    if (id == null) {
      status.value = UiStatus.error;
      return;
    }
    status.value = UiStatus.loading;
    final result = await guard<CustomerSummary?>(() => _customers.getSummary(id));
    result.when(
      ok: (s) {
        summary.value = s;
        if (s == null) {
          status.value = UiStatus.error;
        } else {
          message.value = _build(template.value, s);
          status.value = UiStatus.data;
        }
      },
      err: (_) => status.value = UiStatus.error,
    );
  }

  String _build(String templateKey, CustomerSummary s) => ReminderMessage.fill(
        templateKey.tr,
        name: s.customer.name,
        amount: Money.withSymbol(s.balance > 0 ? s.balance : 0, 'currency'.tr),
        shop: _settings.shopName.value.isEmpty ? 'our_shop'.tr : _settings.shopName.value,
      );

  /// Returns the new text so the view can update its text field.
  String selectTemplate(String key) {
    template.value = key;
    final s = summary.value;
    if (s != null) message.value = _build(key, s);
    return message.value;
  }

  Future<void> send(String text) async {
    final s = summary.value;
    if (s == null || sending.value) return;
    final body = text.trim();
    if (body.isEmpty) {
      AppSnack.error('err_message_empty');
      return;
    }
    if (s.balance <= 0) {
      AppSnack.error('err_no_balance');
      return;
    }
    sending.value = true;
    try {
      final phone = s.customer.phone;
      final Uri uri;
      if (channel.value == ReminderChannel.whatsapp) {
        uri = ReminderMessage.whatsAppUri(digits: Validators.whatsAppNumber(phone), message: body);
      } else {
        uri = ReminderMessage.smsUri(phone: phone, message: body, ios: Platform.isIOS);
      }
      final opened = await _lock.external(() async {
        try {
          return await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e, st) {
          CrashReporter.record(e, st, reason: 'launch_reminder');
          return false;
        }
      });
      if (!opened) {
        AppSnack.error(channel.value == ReminderChannel.whatsapp ? 'err_whatsapp_missing' : 'err_sms_missing');
        return;
      }
      final now = DateTime.now().toUtc();
      await guard<void>(() => _reminders.upsert(Reminder(
            id: newId(),
            userId: kLocalUserId,
            createdAt: now,
            updatedAt: now,
            customerId: s.customer.id,
            channel: channel.value,
            message: body,
            sentAt: now,
          )));
    } finally {
      sending.value = false;
    }
  }
}
