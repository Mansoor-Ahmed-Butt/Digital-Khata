import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../customers/presentation/views/customer_list_view.dart';
import '../../../dashboard/presentation/views/home_view.dart';
import '../../../settings/presentation/views/settings_view.dart';
import '../../../statements/presentation/views/reports_view.dart';
import '../controllers/nav_controller.dart';

/// Bottom navigation shell: Home, Customers, Reports, Settings.
class AppShellView extends GetView<NavController> {
  const AppShellView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.tabIndex.value;
      return PopScope(
        canPop: index == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) controller.go(0);
        },
        child: Scaffold(
          body: IndexedStack(
            index: index,
            children: const <Widget>[
              HomeView(),
              CustomerListView(),
              ReportsView(),
              SettingsView(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: controller.go,
            destinations: <NavigationDestination>[
              NavigationDestination(
                  icon: const Icon(Icons.home_outlined),
                  selectedIcon: const Icon(Icons.home),
                  label: 'nav_home'.tr),
              NavigationDestination(
                  icon: const Icon(Icons.people_outline),
                  selectedIcon: const Icon(Icons.people),
                  label: 'nav_customers'.tr),
              NavigationDestination(
                  icon: const Icon(Icons.bar_chart_outlined),
                  selectedIcon: const Icon(Icons.bar_chart),
                  label: 'nav_reports'.tr),
              NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: 'nav_settings'.tr),
            ],
          ),
        ),
      );
    });
  }
}
