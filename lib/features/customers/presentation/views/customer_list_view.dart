import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/utils/ui_status.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../domain/customer.dart';
import '../controllers/customers_controller.dart';
import 'contact_picker_sheet.dart';
import 'customer_tile.dart';

/// Customer list tab (5.4): search, filter chips, sort menu, tiles.
class CustomerListView extends GetView<CustomersController> {
  const CustomerListView({super.key});

  void _openLedger(CustomerSummary s) {
    Get.toNamed(AppRoutes.customerLedger,
        arguments: <String, Object?>{RouteArgs.customerId: s.customer.id});
  }

  Future<void> _import() async {
    final candidates = await controller.loadContacts();
    if (candidates == null) return;
    final selected = await Get.bottomSheet<List<ContactCandidate>>(
      ContactPickerSheet(candidates: candidates),
      isScrollControlled: true,
      backgroundColor: Theme.of(Get.context ?? Get.overlayContext!).colorScheme.surface,
    );
    if (selected != null && selected.isNotEmpty) {
      await controller.importContacts(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('customers'.tr),
        actions: <Widget>[
          Obx(
            () => IconButton(
              tooltip: 'import_contacts'.tr,
              onPressed: controller.importing.value ? null : _import,
              icon: controller.importing.value
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.contacts_outlined),
            ),
          ),
          PopupMenuButton<CustomerSort>(
            tooltip: 'sort'.tr,
            icon: const Icon(Icons.sort),
            onSelected: (v) => controller.sort.value = v,
            itemBuilder: (context) => <PopupMenuEntry<CustomerSort>>[
              PopupMenuItem<CustomerSort>(
                  value: CustomerSort.name, child: Text('sort_name'.tr)),
              PopupMenuItem<CustomerSort>(
                  value: CustomerSort.balanceHigh, child: Text('sort_balance'.tr)),
              PopupMenuItem<CustomerSort>(
                  value: CustomerSort.recent, child: Text('sort_recent'.tr)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_customer_list',
        onPressed: () => Get.toNamed(AppRoutes.customerEdit),
        icon: const Icon(Icons.person_add_alt_1),
        label: Text('add_customer'.tr),
      ),
      body: Column(
        children: <Widget>[
          const _SearchBar(),
          const _FilterChips(),
          Expanded(child: _Body(onOpen: _openLedger)),
        ],
      ),
    );
  }
}

class _SearchBar extends GetView<CustomersController> {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        onChanged: (v) => controller.query.value = v,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'search'.tr,
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

class _FilterChips extends GetView<CustomersController> {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Obx(() {
        final current = controller.filter.value;
        Widget chip(CustomerFilter f, String key) => Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: ChoiceChip(
                label: Text(key.tr),
                selected: current == f,
                onSelected: (_) => controller.filter.value = f,
              ),
            );
        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: <Widget>[
            chip(CustomerFilter.all, 'filter_all'),
            chip(CustomerFilter.due, 'filter_due'),
            chip(CustomerFilter.clear, 'filter_clear'),
            chip(CustomerFilter.archived, 'filter_archived'),
          ],
        );
      }),
    );
  }
}

class _Body extends GetView<CustomersController> {
  const _Body({required this.onOpen});

  final ValueChanged<CustomerSummary> onOpen;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      switch (controller.status.value) {
        case UiStatus.loading:
          return const SkeletonLoader();
        case UiStatus.error:
          return ErrorRetry(message: controller.errorMessage.value, onRetry: controller.retry);
        case UiStatus.empty:
          return EmptyState(
            icon: Icons.people_outline,
            titleKey: 'customers_empty_title',
            messageKey: 'customers_empty_message',
            actionKey: 'add_customer',
            onAction: () => Get.toNamed(AppRoutes.customerEdit),
          );
        case UiStatus.data:
          final items = controller.visible;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.search_off,
              titleKey: 'no_results_title',
              messageKey: 'no_results_message',
            );
          }
          final archivedView = controller.filter.value == CustomerFilter.archived;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final s = items[index];
              return CustomerTile(
                key: ValueKey<String>(s.customer.id),
                summary: s,
                onTap: () => onOpen(s),
                onLongPress: () => archivedView ? controller.unarchive(s) : controller.archive(s),
              );
            },
          );
      }
    });
  }
}
