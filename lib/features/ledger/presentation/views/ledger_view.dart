import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/khata_colors.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/khata_card.dart';
import '../../../../core/widgets/money_widgets.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/ledger_transaction.dart';
import '../controllers/ledger_controller.dart';

/// Customer ledger (5.6).
class LedgerView extends GetView<LedgerController> {
  const LedgerView({super.key});

  Map<String, Object?> get _args =>
      <String, Object?>{RouteArgs.customerId: controller.customerId};

  void _add(TxnType type) => Get.toNamed(AppRoutes.addTransaction,
      arguments: <String, Object?>{RouteArgs.customerId: controller.customerId, RouteArgs.txnType: type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.summary.value?.customer.name ?? 'ledger'.tr, overflow: TextOverflow.ellipsis)),
        actions: <Widget>[
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') Get.toNamed(AppRoutes.customerEdit, arguments: _args);
              if (v == 'archive') controller.archiveCustomer();
            },
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(value: 'edit', child: Text('edit_customer'.tr)),
              PopupMenuItem<String>(value: 'archive', child: Text('archive'.tr)),
            ],
          ),
        ],
      ),
      body: Obx(() {
        switch (controller.status.value) {
          case UiStatus.loading:
            return const SkeletonLoader(itemCount: 5);
          case UiStatus.error:
          case UiStatus.empty:
            return ErrorRetry(messageKey: 'err_not_found', onRetry: controller.retry);
          case UiStatus.data:
            return _content(context);
        }
      }),
    );
  }

  Widget _content(BuildContext context) {
    final s = controller.summary.value;
    if (s == null) return const SizedBox.shrink();
    final entries = controller.entries;
    final theme = Theme.of(context);
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: KhataCard(
            color: context.khata.primaryTint,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        (s.isAdvance ? 'advance' : (s.isClear ? 'all_clear' : 'you_will_get')).tr,
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      BalanceDisplay(balance: s.balance, large: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  titleKey: 'ledger_empty_title',
                  messageKey: 'ledger_empty_message')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _EntryTile(
                    key: ValueKey<String>(entries[i].transaction.id),
                    entry: entries[i],
                    onDelete: () async {
                      final ok = await ConfirmDialog.show(
                          titleKey: 'delete_entry',
                          messageKey: 'delete_entry_message',
                          confirmKey: 'delete',
                          destructive: true);
                      if (ok) controller.deleteTransaction(entries[i].transaction);
                    },
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: PrimaryButton(
                          label: 'give_credit'.tr, icon: Icons.remove, onPressed: () => _add(TxnType.credit)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                          label: 'receive_payment'.tr, icon: Icons.add, onPressed: () => _add(TxnType.payment)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SecondaryButton(
                        label: 'remind'.tr,
                        icon: Icons.notifications_active_outlined,
                        onPressed: controller.canRemind ? () => Get.toNamed(AppRoutes.reminder, arguments: _args) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SecondaryButton(
                        label: 'export_pdf'.tr,
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () => Get.toNamed(AppRoutes.statement, arguments: _args),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({super.key, required this.entry, required this.onDelete});

  final LedgerEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = entry.transaction;
    final colors = context.khata;
    final isCredit = t.type == TxnType.credit;
    final color = isCredit ? colors.danger : colors.success;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: KhataCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onTap: t.photoPath == null ? null : () => _showPhoto(t.photoPath!),
        child: Row(
          children: <Widget>[
            Icon(isCredit ? Icons.remove_circle : Icons.add_circle, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text((isCredit ? 'credit_given' : 'payment_received').tr, style: theme.textTheme.titleMedium),
                  Text(
                    [AppDates.full(t.txnDate), if (t.note != null) t.note!].join(' - '),
                    style: theme.textTheme.bodySmall,
                  ),
                  Text('${'balance'.tr}: ${'currency'.tr} ${_fmt(entry.balanceAfter)}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                MoneyText(t.amount, style: theme.textTheme.titleMedium, color: color),
                if (t.photoPath != null) const Icon(Icons.photo_outlined, size: 16),
              ],
            ),
            IconButton(
              tooltip: 'delete'.tr,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int paisa) {
    final neg = paisa < 0;
    final abs = paisa.abs();
    final s = '${abs ~/ 100}'.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
    final frac = abs % 100;
    final out = frac == 0 ? s : '$s.${frac.toString().padLeft(2, '0')}';
    return neg ? '-$out' : out;
  }

  void _showPhoto(String path) {
    Get.dialog<void>(
      Dialog(
        child: InteractiveViewer(
          child: Image.file(
            File(path),
            errorBuilder: (context, error, stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('photo_missing'.tr),
            ),
          ),
        ),
      ),
    );
  }
}
