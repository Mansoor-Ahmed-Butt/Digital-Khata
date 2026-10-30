import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/khata_colors.dart';
import '../../../../core/utils/app_dates.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/khata_card.dart';
import '../../../../core/widgets/money_widgets.dart';
import '../controllers/statement_controller.dart';

/// Reports tab (5.9): date range, summary cards, pick a customer for a statement.
class ReportsView extends GetView<StatementController> {
  const ReportsView({super.key});

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year, now.month, now.day + 1),
      initialDateRange: DateTimeRange(start: controller.from.value, end: controller.to.value),
    );
    if (picked != null) await controller.setRange(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.khata;
    return Scaffold(
      appBar: AppBar(title: Text('reports'.tr)),
      body: RefreshIndicator(
        onRefresh: controller.refreshSummary,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Obx(() => OutlinedButton.icon(
                  onPressed: () => _pickRange(context),
                  icon: const Icon(Icons.date_range_outlined),
                  label: Text('${AppDates.full(controller.from.value)} - ${AppDates.full(controller.to.value)}'),
                )),
            const SizedBox(height: 16),
            Obx(() => Row(
                  children: <Widget>[
                    Expanded(
                      child: KhataCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('credit_given'.tr, style: theme.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: MoneyText(controller.totals.value.credit,
                                    style: theme.textTheme.titleLarge, color: colors.danger)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KhataCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('payment_received'.tr, style: theme.textTheme.labelMedium),
                            const SizedBox(height: 4),
                            FittedBox(
                                fit: BoxFit.scaleDown,
                                child: MoneyText(controller.totals.value.payment,
                                    style: theme.textTheme.titleLarge, color: colors.success)),
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 24),
            Text('customer_statement'.tr, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Obx(() {
              if (controller.customerList.isEmpty) return Text('customers_empty_message'.tr);
              return DropdownMenu<String>(
                expandedInsets: EdgeInsets.zero,
                hintText: 'select_customer'.tr,
                enableFilter: true,
                requestFocusOnTap: true,
                dropdownMenuEntries: <DropdownMenuEntry<String>>[
                  for (final s in controller.customerList)
                    DropdownMenuEntry<String>(value: s.customer.id, label: s.customer.name),
                ],
                onSelected: (v) => controller.selectedCustomerId.value = v,
              );
            }),
            const SizedBox(height: 16),
            Obx(() => PrimaryButton(
                  label: 'preview_statement'.tr,
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: controller.selectedCustomerId.value == null
                      ? null
                      : () => Get.toNamed(AppRoutes.statement, arguments: <String, Object?>{
                            RouteArgs.customerId: controller.selectedCustomerId.value,
                            RouteArgs.from: controller.from.value,
                            RouteArgs.to: controller.to.value,
                          }),
                )),
          ],
        ),
      ),
    );
  }
}
