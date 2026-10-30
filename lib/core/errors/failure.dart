import 'package:flutter/foundation.dart';

/// A recoverable, user-presentable error. [messageKey] is a translation key.
class Failure implements Exception {
  const Failure(this.messageKey, [this.cause]);

  final String messageKey;
  final Object? cause;

  @override
  String toString() => 'Failure($messageKey, $cause)';
}

/// Single place to report crashes and non-fatal errors.
///
/// Wire Firebase Crashlytics here once `google-services.json` is added:
/// `FirebaseCrashlytics.instance.recordError(error, stack, reason: reason)`.
/// Never pass personal data (names, phones, amounts) in [reason].
class CrashReporter {
  CrashReporter._();

  static void record(Object error, StackTrace? stack, {String? reason}) {
    if (kDebugMode) {
      debugPrint('[CrashReporter] ${reason ?? 'error'}: $error');
      if (stack != null) debugPrint(stack.toString());
    }
  }
}

sealed class Result<T> {
  const Result();

  R when<R>({required R Function(T value) ok, required R Function(Failure failure) err}) {
    final self = this;
    return switch (self) {
      Ok<T>() => ok(self.value),
      Err<T>() => err(self.failure),
    };
  }

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

/// Runs [action] and converts any thrown error into an [Err]. Never throws.
Future<Result<T>> guard<T>(Future<T> Function() action) async {
  try {
    return Ok<T>(await action());
  } on Failure catch (f) {
    return Err<T>(f);
  } catch (e, s) {
    CrashReporter.record(e, s, reason: 'guard');
    return Err<T>(Failure('err_generic', e));
  }
}
