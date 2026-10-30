import 'package:get/get.dart';

import '../../features/auth/presentation/bindings/auth_binding.dart';
import '../../features/auth/presentation/views/onboarding_view.dart';
import '../../features/auth/presentation/views/pin_setup_view.dart';
import '../../features/auth/presentation/views/splash_lock_view.dart';
import '../../features/customers/presentation/bindings/customers_binding.dart';
import '../../features/customers/presentation/views/customer_edit_view.dart';
import '../../features/ledger/presentation/bindings/ledger_binding.dart';
import '../../features/ledger/presentation/views/add_transaction_view.dart';
import '../../features/ledger/presentation/views/ledger_view.dart';
import '../../features/reminders/presentation/bindings/reminders_binding.dart';
import '../../features/reminders/presentation/views/reminder_composer_view.dart';
import '../../features/settings/presentation/bindings/settings_binding.dart';
import '../../features/shell/presentation/bindings/shell_binding.dart';
import '../../features/shell/presentation/views/app_shell_view.dart';
import '../../features/statements/presentation/views/statement_view.dart';
import '../middleware/lock_middleware.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage<dynamic>> pages = <GetPage<dynamic>>[
    GetPage<dynamic>(
        name: AppRoutes.splash,
        page: () => const SplashLockView(),
        binding: SplashBinding()),
    GetPage<dynamic>(
        name: AppRoutes.onboarding,
        page: () => const OnboardingView(),
        binding: OnboardingBinding()),
    GetPage<dynamic>(
        name: AppRoutes.pinPad,
        page: () => const PinSetupView(),
        binding: PinPadBinding()),
    GetPage<dynamic>(
      name: AppRoutes.shell,
      page: () => const AppShellView(),
      bindings: <Bindings>[ShellBinding(), SettingsBinding()],
      middlewares: <GetMiddleware>[LockMiddleware()],
    ),
    GetPage<dynamic>(
        name: AppRoutes.customerEdit,
        page: () => const CustomerEditView(),
        binding: CustomerFormBinding(),
        middlewares: <GetMiddleware>[LockMiddleware()]),
    GetPage<dynamic>(
        name: AppRoutes.customerLedger,
        page: () => const LedgerView(),
        binding: LedgerBinding(),
        middlewares: <GetMiddleware>[LockMiddleware()]),
    GetPage<dynamic>(
        name: AppRoutes.addTransaction,
        page: () => const AddTransactionView(),
        binding: AddTransactionBinding(),
        middlewares: <GetMiddleware>[LockMiddleware()]),
    GetPage<dynamic>(
        name: AppRoutes.reminder,
        page: () => const ReminderComposerView(),
        binding: RemindersBinding(),
        middlewares: <GetMiddleware>[LockMiddleware()]),
    GetPage<dynamic>(
        name: AppRoutes.statement,
        page: () => const StatementView(),
        middlewares: <GetMiddleware>[LockMiddleware()]),
  ];
}
