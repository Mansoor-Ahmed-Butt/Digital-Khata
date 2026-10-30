import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/errors/failure.dart';

/// Stores a salted SHA-256 hash of the PIN in the platform keystore.
/// The PIN itself is never stored.
class PinStore {
  PinStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kSalt = 'pin_salt';
  static const String _kHash = 'pin_hash';

  Future<bool> hasPin() async {
    try {
      final hash = await _storage.read(key: _kHash);
      return hash != null && hash.isNotEmpty;
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pin_has');
      return false;
    }
  }

  Future<void> savePin(String pin) async {
    final salt = _newSalt();
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: _hash(salt, pin));
  }

  Future<bool> verify(String pin) async {
    try {
      final salt = await _storage.read(key: _kSalt);
      final stored = await _storage.read(key: _kHash);
      if (salt == null || stored == null) return false;
      return _constantTimeEquals(_hash(salt, pin), stored);
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pin_verify');
      return false;
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _kSalt);
      await _storage.delete(key: _kHash);
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'pin_clear');
    }
  }

  static String _newSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
