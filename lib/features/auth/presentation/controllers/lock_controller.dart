import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../settings/data/settings_store.dart';
import '../../domain/lock_repository.dart';

/// Owns the lock state for the whole app (FR-01): PIN, biometric, auto-lock
/// when the app returns from the background.
class LockController extends GetxController with WidgetsBindingObserver {
  final LockRepository _repo = Get.find<LockRepository>();
  final SettingsStore _store = Get.find<SettingsStore>();

  static const int pinLength = 4;
  static const Duration autoLockAfter = Duration(seconds: 60);
  static const int maxAttempts = 5;
  static const Duration cooldown = Duration(seconds: 30);

  final RxBool lockEnabled = false.obs;
  final RxBool biometricEnabled = false.obs;
  final RxBool biometricAvailable = false.obs;
  final RxBool isLocked = false.obs;

  final Completer<void> _ready = Completer<void>();
  Future<void> get ready => _ready.future;

  DateTime? _pausedAt;
  bool _suppressRelock = false;
  int _failedAttempts = 0;
  DateTime? _cooldownUntil;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    lockEnabled.value = _store.lockEnabled;
    biometricEnabled.value = _store.biometricEnabled;
    isLocked.value = _store.lockEnabled;
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      // If the keystore lost the PIN, do not trap the owner behind a lock
      // nobody can open: turn the lock off and let them set a new one.
      if (lockEnabled.value && !await _repo.hasPin()) {
        await _store.setLockEnabled(false);
        await _store.setBiometricEnabled(false);
        lockEnabled.value = false;
        biometricEnabled.value = false;
        isLocked.value = false;
      }
      biometricAvailable.value = await _repo.biometricAvailable();
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'lock_init');
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final pausedAt = _pausedAt;
      _pausedAt = null;
      if (pausedAt == null || _suppressRelock) return;
      if (lockEnabled.value &&
          !isLocked.value &&
          DateTime.now().difference(pausedAt) >= autoLockAfter) {
        lockNow();
      }
    }
  }

  /// Wrap calls that leave the app (camera, file picker, share sheet) so a
  /// long trip outside does not immediately re-lock on return.
  Future<T> external<T>(Future<T> Function() action) async {
    _suppressRelock = true;
    try {
      return await action();
    } finally {
      _suppressRelock = false;
      _pausedAt = null;
    }
  }

  void lockNow() {
    if (!lockEnabled.value || isLocked.value) return;
    isLocked.value = true;
    if (Get.currentRoute != AppRoutes.splash) {
      Get.offAllNamed(AppRoutes.splash);
    }
  }

  int get cooldownSecondsLeft {
    final until = _cooldownUntil;
    if (until == null) return 0;
    final left = until.difference(DateTime.now()).inSeconds + 1;
    return left > 0 ? left : 0;
  }

  /// Returns true when the PIN is correct. Too many wrong tries start a cooldown.
  Future<bool> checkPin(String pin) async {
    if (cooldownSecondsLeft > 0) return false;
    final ok = await _repo.verifyPin(pin);
    if (ok) {
      _failedAttempts = 0;
      _cooldownUntil = null;
      return true;
    }
    _failedAttempts++;
    if (_failedAttempts >= maxAttempts) {
      _failedAttempts = 0;
      _cooldownUntil = DateTime.now().add(cooldown);
    }
    return false;
  }

  Future<bool> unlockWithPin(String pin) async {
    final ok = await checkPin(pin);
    if (ok) isLocked.value = false;
    return ok;
  }

  Future<bool> unlockWithBiometric() async {
    if (!biometricEnabled.value || !biometricAvailable.value) return false;
    final ok = await external(() => _repo.biometricAuthenticate('biometric_reason'.tr));
    if (ok) isLocked.value = false;
    return ok;
  }

  Future<Result<void>> setPin(String pin) => guard<void>(() async {
        await _repo.setPin(pin);
        await _store.setLockEnabled(true);
        lockEnabled.value = true;
        isLocked.value = false;
      });

  Future<Result<void>> disableLock() => guard<void>(() async {
        await _store.setLockEnabled(false);
        await _store.setBiometricEnabled(false);
        await _repo.clearPin();
        lockEnabled.value = false;
        biometricEnabled.value = false;
        isLocked.value = false;
      });

  Future<Result<void>> setBiometricEnabled(bool value) => guard<void>(() async {
        if (value) {
          if (!biometricAvailable.value) throw const Failure('err_biometric_unavailable');
          final ok =
              await external(() => _repo.biometricAuthenticate('biometric_reason'.tr));
          if (!ok) throw const Failure('err_biometric_failed');
        }
        await _store.setBiometricEnabled(value);
        biometricEnabled.value = value;
      });
}
