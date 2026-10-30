import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/khata_colors.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/khata_card.dart';
import '../../../../core/widgets/app_snack.dart';
import '../../../auth/presentation/controllers/lock_controller.dart';
import '../../../auth/presentation/controllers/pin_pad_controller.dart';
import '../../../backup/presentation/controllers/backup_controller.dart';
import '../../../subscription/presentation/controllers/subscription_controller.dart';
import '../controllers/settings_controller.dart';

/// Settings and backup (5.10).
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _pin(PinMode mode) =>
      Get.toNamed(AppRoutes.pinPad, arguments: <String, Object?>{RouteArgs.pinMode: mode});

  Future<void> _editShop(SettingsController settings) async {
    final name = await Get.dialog<String>(_ShopNameDialog(initial: settings.shopName.value));
    if (name == null) return;
    final result = await settings.saveShopName(name);
    result.when(
      ok: (_) => AppSnack.showKey('saved'),
      err: (f) => AppSnack.error(f.messageKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    final lock = Get.find<LockController>();
    final plan = Get.find<SubscriptionController>();
    final backup = Get.find<BackupController>();
    final theme = Theme.of(context);
    final colors = context.khata;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('shop_profile'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() => KhataCard(
                onTap: () => _editShop(settings),
                child: Row(children: <Widget>[
                  const Icon(Icons.storefront_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(settings.shopName.value.isEmpty ? '-' : settings.shopName.value,
                          style: theme.textTheme.titleMedium)),
                  const Icon(Icons.edit_outlined, size: 20),
                ]),
              )),
          const SizedBox(height: 24),
          Text('language'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() => Row(children: <Widget>[
                Expanded(
                  child: _choice(context, 'English', settings.locale.value.languageCode == 'en',
                      () => settings.setLanguage('en')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _choice(context, 'language_urdu'.tr, settings.locale.value.languageCode == 'ur',
                      () => settings.setLanguage('ur')),
                ),
              ])),
          const SizedBox(height: 24),
          Text('lock_settings'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() => KhataCard(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(children: <Widget>[
                  SwitchListTile(
                    title: Text('app_lock'.tr),
                    subtitle: Text('app_lock_hint'.tr),
                    value: lock.lockEnabled.value,
                    onChanged: (on) => on ? _pin(PinMode.create) : _pin(PinMode.verifyDisable),
                  ),
                  if (lock.lockEnabled.value) ...<Widget>[
                    ListTile(
                      title: Text('change_pin'.tr),
                      leading: const Icon(Icons.password),
                      onTap: () => _pin(PinMode.verifyChange),
                    ),
                    if (lock.biometricAvailable.value)
                      SwitchListTile(
                        title: Text('use_fingerprint'.tr),
                        value: lock.biometricEnabled.value,
                        onChanged: (on) async {
                          final r = await lock.setBiometricEnabled(on);
                          r.when(ok: (_) {}, err: (f) => AppSnack.error(f.messageKey));
                        },
                      ),
                  ],
                ]),
              )),
          const SizedBox(height: 24),
          Text('backup'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() {
            final last = backup.lastBackupAt.value;
            return KhataCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                Text(last == null
                    ? 'never_backed_up'.tr
                    : 'last_backup'.trParams(<String, String>{'date': AppDates.full(last.toLocal())})),
                const SizedBox(height: 4),
                Text('backup_hint'.tr, style: theme.textTheme.bodySmall),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  Expanded(
                    child: PrimaryButton(
                      label: 'backup_now'.tr,
                      icon: Icons.cloud_upload_outlined,
                      loading: backup.isBackingUp.value,
                      onPressed: backup.backupNow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryButton(
                      label: 'restore'.tr,
                      icon: Icons.settings_backup_restore,
                      onPressed: backup.isRestoring.value ? null : backup.restore,
                    ),
                  ),
                ]),
              ]),
            );
          }),
          const SizedBox(height: 24),
          Text('plan'.tr, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Obx(() => KhataCard(
                color: colors.primaryTint,
                onTap: plan.debugTogglePlan,
                child: Row(children: <Widget>[
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Text(plan.isPro ? 'plan_pro'.tr : 'plan_free'.tr, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(plan.isPro
                          ? 'plan_pro_hint'.tr
                          : 'plan_usage'.trParams(<String, String>{
                              'n': '${plan.activeCustomers.value}',
                              'limit': '${plan.limit}',
                            })),
                    ]),
                  ),
                  if (!plan.isPro)
                    FilledButton(onPressed: plan.upgrade, child: Text('upgrade'.tr)),
                ]),
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _choice(BuildContext context, String label, bool selected, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: KhataCard(
        onTap: onTap,
        color: selected ? context.khata.primaryTint : null,
        borderColor: selected ? theme.colorScheme.primary : null,
        child: Center(
          child: Text(label, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _ShopNameDialog extends StatefulWidget {
  const _ShopNameDialog({required this.initial});

  final String initial;

  @override
  State<_ShopNameDialog> createState() => _ShopNameDialogState();
}

class _ShopNameDialogState extends State<_ShopNameDialog> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('shop_name'.tr),
      content: TextField(controller: _c, autofocus: true, maxLength: 60),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('cancel'.tr)),
        TextButton(onPressed: () => Navigator.of(context).pop(_c.text), child: Text('save'.tr)),
      ],
    );
  }
}
