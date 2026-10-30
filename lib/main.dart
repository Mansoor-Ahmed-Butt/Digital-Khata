import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/errors/failure.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      CrashReporter.record(details.exception, details.stack, reason: 'flutter');
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      CrashReporter.record(error, stack, reason: 'platform');
      return true;
    };
    // A failed widget shows nothing in release instead of a grey/red screen.
    ErrorWidget.builder = (details) =>
        kDebugMode ? ErrorWidget(details.exception) : const SizedBox.shrink();

    try {
      await initializeDateFormatting();
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'date_formatting');
    }
    await _start();
  }, (error, stack) => CrashReporter.record(error, stack, reason: 'zone'));
}

Future<void> _start() async {
  try {
    final boot = await Bootstrap.run();
    runApp(DigitalKhataApp(boot: boot));
  } catch (e, s) {
    CrashReporter.record(e, s, reason: 'boot');
    runApp(BootFailureApp(onRetry: _start));
  }
}
