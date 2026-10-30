/// PIN and biometric lock (FR-01). Named LockRepository because the app is
/// offline-first; a cloud AuthRepository (Supabase) can be added beside it.
abstract class LockRepository {
  Future<bool> hasPin();
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearPin();
  Future<bool> biometricAvailable();
  Future<bool> biometricAuthenticate(String reason);
}
