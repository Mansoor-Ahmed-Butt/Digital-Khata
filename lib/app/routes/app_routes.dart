abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String pinPad = '/lock/pin';
  static const String shell = '/';
  static const String customerEdit = '/customers/edit';
  static const String customerLedger = '/customers/ledger';
  static const String addTransaction = '/transactions/add';
  static const String reminder = '/reminders/compose';
  static const String statement = '/reports/statement';
}

/// Argument keys passed through Get.toNamed(arguments: ...).
abstract class RouteArgs {
  static const String customerId = 'customerId';
  static const String txnType = 'txnType';
  static const String pinMode = 'pinMode';
  static const String fromOnboarding = 'fromOnboarding';
  static const String from = 'from';
  static const String to = 'to';
}

/// Reads a typed argument from Get.arguments without ever throwing.
T? routeArg<T>(String key, [Object? arguments]) {
  final source = arguments;
  if (source is Map) {
    final value = source[key];
    if (value is T) return value;
  }
  return null;
}
