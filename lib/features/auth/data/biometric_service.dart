import 'package:local_auth/local_auth.dart';

import '../../../core/errors/failure.dart';

/// Thin, crash-proof wrapper around local_auth. Any platform error simply
/// means "biometrics not available"; the PIN always remains as a fallback.
class BiometricService {
  BiometricService([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'biometric_available');
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (e, s) {
      CrashReporter.record(e, s, reason: 'biometric_auth');
      return false;
    }
  }
}
