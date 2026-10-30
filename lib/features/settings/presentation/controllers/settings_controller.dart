import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/utils/validators.dart';
import '../../data/settings_store.dart';

/// Language and shop profile. Registered permanently in InitialBinding.
class SettingsController extends GetxController {
  final SettingsStore _store = Get.find<SettingsStore>();

  final Rx<Locale> locale = const Locale('en').obs;
  final RxString shopName = ''.obs;
  final RxBool onboarded = false.obs;

  bool get isUrdu => locale.value.languageCode == 'ur';

  @override
  void onInit() {
    super.onInit();
    locale.value = _store.locale;
    shopName.value = _store.shopName;
    onboarded.value = _store.onboarded;
  }

  /// FR-06: switches language at runtime and mirrors the layout for RTL.
  Future<void> setLanguage(String code) async {
    if (!SettingsStore.supportedLanguageCodes.contains(code)) return;
    final next = Locale(code);
    locale.value = next;
    Get.updateLocale(next);
    try {
      await _store.setLanguageCode(code);
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'save_language');
    }
  }

  Future<Result<void>> saveShopName(String name) => guard<void>(() async {
        final error = Validators.name(name);
        if (error != null) throw Failure(error);
        final clean = name.trim();
        await _store.setShopName(clean);
        shopName.value = clean;
      });

  Future<Result<void>> completeOnboarding(String name) => guard<void>(() async {
        final error = Validators.name(name);
        if (error != null) throw Failure(error);
        final clean = name.trim();
        await _store.setShopName(clean);
        await _store.setOnboarded(true);
        shopName.value = clean;
        onboarded.value = true;
      });
}
