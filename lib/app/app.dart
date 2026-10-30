import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../core/bindings/initial_binding.dart';
import '../core/widgets/app_snack.dart';
import 'bootstrap.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';
import 'translations/app_translations.dart';

class DigitalKhataApp extends StatelessWidget {
  const DigitalKhataApp({super.key, required this.boot});

  final Boot boot;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Digital Khata',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(boot),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      translations: AppTranslations(),
      locale: boot.settings.locale,
      fallbackLocale: const Locale('en'),
      supportedLocales: const <Locale>[Locale('en'), Locale('ur')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: AppSnack.messengerKey,
      transitionDuration: const Duration(milliseconds: 200),
      unknownRoute: AppPages.pages.first,
    );
  }
}

/// Shown if the local database cannot be opened. Offers a retry instead of crashing.
class BootFailureApp extends StatelessWidget {
  const BootFailureApp({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 16),
                const Text(
                  'Digital Khata could not open its data. Your data has not been deleted.\n\n'
                  'ڈیٹا کھولا نہیں جا سکا۔ آپ کا ڈیٹا محفوظ ہے۔',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onRetry, child: const Text('Retry / دوبارہ کوشش')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
