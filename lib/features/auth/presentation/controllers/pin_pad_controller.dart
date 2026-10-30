import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../app/routes/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/widgets/app_snack.dart';
import 'lock_controller.dart';

enum PinMode { unlock, create, verifyDisable, verifyChange }

/// Drives the PIN pad for unlocking, creating, changing and removing the PIN.
class PinPadController extends GetxController {
  final LockController _lock = Get.find<LockController>();

  final Rx<PinMode> mode = PinMode.unlock.obs;
  final RxString pin = ''.obs;
  final RxnString errorText = RxnString();
  final RxBool busy = false.obs;
  final RxBool confirming = false.obs;

  String? _firstEntry;
  bool fromOnboarding = false;

  int get length => LockController.pinLength;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    mode.value = routeArg<PinMode>(RouteArgs.pinMode, args) ?? PinMode.unlock;
    fromOnboarding = routeArg<bool>(RouteArgs.fromOnboarding, args) ?? false;
  }

  @override
  void onReady() {
    super.onReady();
    if (mode.value == PinMode.unlock) {
      _lock.ready.then((_) {
        if (!isClosed) tryBiometric();
      });
    }
  }

  String get titleKey {
    switch (mode.value) {
      case PinMode.unlock:
        return 'enter_pin';
      case PinMode.create:
        return confirming.value ? 'confirm_pin' : 'create_pin';
      case PinMode.verifyDisable:
      case PinMode.verifyChange:
        return 'enter_current_pin';
    }
  }

  bool get biometricOffered =>
      mode.value == PinMode.unlock &&
      _lock.biometricEnabled.value &&
      _lock.biometricAvailable.value;

  Future<void> tryBiometric() async {
    if (!_lock.isLocked.value || !biometricOffered) return;
    final ok = await _lock.unlockWithBiometric();
    if (ok) Get.offAllNamed(AppRoutes.shell);
  }

  void onDigit(String digit) {
    if (busy.value || pin.value.length >= length) return;
    final left = _lock.cooldownSecondsLeft;
    if (left > 0) {
      errorText.value = 'err_pin_cooldown'.trParams(<String, String>{'s': '$left'});
      return;
    }
    errorText.value = null;
    pin.value = pin.value + digit;
    if (pin.value.length == length) _submit();
  }

  void onBackspace() {
    if (busy.value || pin.value.isEmpty) return;
    pin.value = pin.value.substring(0, pin.value.length - 1);
    errorText.value = null;
  }

  Future<void> _submit() async {
    busy.value = true;
    final entered = pin.value;
    try {
      switch (mode.value) {
        case PinMode.unlock:
          if (await _lock.unlockWithPin(entered)) {
            Get.offAllNamed(AppRoutes.shell);
          } else {
            _wrong();
          }
        case PinMode.verifyDisable:
          if (await _lock.checkPin(entered)) {
            final result = await _lock.disableLock();
            result.when(
              ok: (_) {
                Get.back();
                AppSnack.showKey('lock_disabled');
              },
              err: (f) => _fail(f.messageKey),
            );
          } else {
            _wrong();
          }
        case PinMode.verifyChange:
          if (await _lock.checkPin(entered)) {
            mode.value = PinMode.create;
            pin.value = '';
          } else {
            _wrong();
          }
        case PinMode.create:
          await _handleCreate(entered);
      }
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pin_submit');
      _fail('err_generic');
    } finally {
      busy.value = false;
    }
  }

  Future<void> _handleCreate(String entered) async {
    if (!confirming.value) {
      _firstEntry = entered;
      confirming.value = true;
      pin.value = '';
      return;
    }
    if (entered != _firstEntry) {
      HapticFeedback.vibrate();
      errorText.value = 'err_pin_mismatch'.tr;
      _firstEntry = null;
      confirming.value = false;
      pin.value = '';
      return;
    }
    final result = await _lock.setPin(entered);
    result.when(
      ok: (_) {
        HapticFeedback.mediumImpact();
        if (fromOnboarding) {
          Get.offAllNamed(AppRoutes.shell);
        } else {
          Get.back();
          AppSnack.showKey('lock_enabled');
        }
      },
      err: (f) => _fail(f.messageKey),
    );
  }

  void skip() => Get.offAllNamed(AppRoutes.shell);

  void _wrong() {
    HapticFeedback.vibrate();
    final left = _lock.cooldownSecondsLeft;
    errorText.value = left > 0
        ? 'err_pin_cooldown'.trParams(<String, String>{'s': '$left'})
        : 'err_pin_wrong'.tr;
    pin.value = '';
  }

  void _fail(String key) {
    errorText.value = key.tr;
    confirming.value = false;
    _firstEntry = null;
    pin.value = '';
  }
}
