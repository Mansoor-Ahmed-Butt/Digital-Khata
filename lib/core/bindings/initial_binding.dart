import 'package:get/get.dart';

import '../../app/bootstrap.dart';
import '../../features/auth/data/biometric_service.dart';
import '../../features/auth/data/lock_repository_impl.dart';
import '../../features/auth/domain/lock_repository.dart';
import '../../features/auth/presentation/controllers/lock_controller.dart';
import '../../features/backup/domain/backup_service.dart';
import '../../features/customers/data/customers_repository_impl.dart';
import '../../features/customers/domain/customers_repository.dart';
import '../../features/customers/domain/save_customer_use_case.dart';
import '../../features/dashboard/data/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/dashboard_repository.dart';
import '../../features/ledger/data/transactions_repository_impl.dart';
import '../../features/ledger/domain/record_transaction_use_case.dart';
import '../../features/ledger/domain/transactions_repository.dart';
import '../../features/reminders/data/reminders_repository_impl.dart';
import '../../features/reminders/domain/reminders_repository.dart';
import '../../features/settings/data/settings_store.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../../features/subscription/data/subscriptions_repository_impl.dart';
import '../../features/subscription/domain/subscriptions_repository.dart';
import '../../features/subscription/presentation/controllers/subscription_controller.dart';
import '../database/app_database.dart';

/// Registers app-wide singletons once. Screen controllers are registered per
/// route in their own bindings so they are disposed with the route.
class InitialBinding extends Bindings {
  InitialBinding(this.boot);

  final Boot boot;

  @override
  void dependencies() {
    Get.put<AppDatabase>(boot.database, permanent: true);
    Get.put<SettingsStore>(boot.settings, permanent: true);

    Get.put<CustomersRepository>(CustomersRepositoryImpl(boot.database), permanent: true);
    Get.put<TransactionsRepository>(TransactionsRepositoryImpl(boot.database), permanent: true);
    Get.put<RemindersRepository>(RemindersRepositoryImpl(boot.database), permanent: true);
    Get.put<SubscriptionsRepository>(SubscriptionsRepositoryImpl(boot.database), permanent: true);
    Get.put<DashboardRepository>(DashboardRepositoryImpl(boot.database), permanent: true);
    Get.put<LockRepository>(LockRepositoryImpl(boot.pinStore, BiometricService()), permanent: true);
    Get.put<BackupService>(BackupService(boot.database), permanent: true);

    Get.put<SaveCustomerUseCase>(
        SaveCustomerUseCase(Get.find<CustomersRepository>(), Get.find<SubscriptionsRepository>()),
        permanent: true);
    Get.put<RecordTransactionUseCase>(
        RecordTransactionUseCase(Get.find<CustomersRepository>(), Get.find<TransactionsRepository>()),
        permanent: true);

    Get.put<SettingsController>(SettingsController(), permanent: true);
    Get.put<LockController>(LockController(), permanent: true);
    Get.put<SubscriptionController>(SubscriptionController(), permanent: true);
  }
}
