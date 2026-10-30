import 'package:flutter/material.dart' show Locale;
import 'package:shared_preferences/shared_preferences.dart';

/// Small key-value preferences. Sensitive data (the PIN) never goes here.
class SettingsStore {
  SettingsStore(this._prefs);

  final SharedPreferences _prefs;

  static const String _kLocale = 'locale';
  static const String _kShopName = 'shop_name';
  static const String _kOnboarded = 'onboarded';
  static const String _kLockEnabled = 'lock_enabled';
  static const String _kBiometric = 'biometric_enabled';
  static const String _kLastBackup = 'last_backup_at';

  static const List<String> supportedLanguageCodes = <String>['en', 'ur'];

  Locale get locale {
    final code = _prefs.getString(_kLocale);
    if (code != null && supportedLanguageCodes.contains(code)) return Locale(code);
    return const Locale('en');
  }

  Future<void> setLanguageCode(String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    await _prefs.setString(_kLocale, code);
  }

  String get shopName => _prefs.getString(_kShopName) ?? '';
  Future<void> setShopName(String value) => _prefs.setString(_kShopName, value);

  bool get onboarded => _prefs.getBool(_kOnboarded) ?? false;
  Future<void> setOnboarded(bool value) => _prefs.setBool(_kOnboarded, value);

  bool get lockEnabled => _prefs.getBool(_kLockEnabled) ?? false;
  Future<void> setLockEnabled(bool value) => _prefs.setBool(_kLockEnabled, value);

  bool get biometricEnabled => _prefs.getBool(_kBiometric) ?? false;
  Future<void> setBiometricEnabled(bool value) => _prefs.setBool(_kBiometric, value);

  DateTime? get lastBackupAt {
    final raw = _prefs.getString(_kLastBackup);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> setLastBackupAt(DateTime value) =>
      _prefs.setString(_kLastBackup, value.toUtc().toIso8601String());
}
