import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/khata_colors.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/khata_card.dart';
import '../../../../core/widgets/money_widgets.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../customers/presentation/views/customer_tile.dart';
import '../../../ledger/domain/ledger_transaction.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/dashboard_controller.dart';

/// Home dashboard (5.3).
class HomeView extends GetView<DashboardController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<SettingsController>();
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(settings.shopName.value.isEmpty ? 'app_name'.tr : settings.shopName.value)),
        actions: const <Widget>[
          SyncBadge(),
          SizedBox(width: 16),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_customer_home',
        tooltip: 'add_customer'.tr,
        onPressed: () => Get.toNamed(AppRoutes.customerEdit),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Obx(() {
        switch (controller.status.value) {
          case UiStatus.loading:
            return const SkeletonLoader(itemCount: 4);
          case UiStatus.error:
            return ErrorRetry(messageKey: 'err_generic', onRetry: controller.listen);
          case UiStatus.empty:
            return EmptyState(
              icon: Icons.menu_book_outlined,
              titleKey: 'home_empty_title',
              messageKey: 'home_empty_message',
              actionKey: 'add_customer',
              onAction: () => Get.toNamed(AppRoutes.customerEdit),
            );
          case UiStatus.data:
            return _content(context);
        }
      }),
    );
  }

  Widget _content(BuildContext context) {
    final d = controller.data.value;
    final theme = Theme.of(context);
    final colors = context.khata;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      children: <Widget>[
        KhataCard(
          color: theme.colorScheme.primary,
          borderColor: theme.colorScheme.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('total_receivable'.tr,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: MoneyText(d.totalReceivable,
                    style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.onPrimary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        KhataCard(
          child: Row(
            children: <Widget>[
              Icon(Icons.add_circle_outline, color: colors.success),
              const SizedBox(width: 12),
              Expanded(child: Text('todays_collection'.tr, style: theme.textTheme.titleMedium)),
              MoneyText(d.todayCollection, style: theme.textTheme.titleMedium, color: colors.success),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('top_debtors'.tr, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (d.topDebtors.isEmpty)
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('no_debtors'.tr))
        else
          for (final s in d.topDebtors)
            CustomerTile(
              key: ValueKey<String>('top_${s.customer.id}'),
              summary: s,
              onTap: () => Get.toNamed(AppRoutes.customerLedger,
                  arguments: <String, Object?>{RouteArgs.customerId: s.customer.id}),
            ),
        const SizedBox(height: 16),
        Text('recent_activity'.tr, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (d.recent.isEmpty)
          Text('no_activity'.tr)
        else
          for (final r in d.recent)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                r.transaction.type == TxnType.credit ? Icons.remove_circle : Icons.add_circle,
                color: r.transaction.type == TxnType.credit ? colors.danger : colors.success,
              ),
              title: Text(r.customerName, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text(AppDates.full(r.transaction.txnDate)),
              trailing: MoneyText(r.transaction.amount,
                  color: r.transaction.type == TxnType.credit ? colors.danger : colors.success),
            ),
      ],
    );
  }
}
