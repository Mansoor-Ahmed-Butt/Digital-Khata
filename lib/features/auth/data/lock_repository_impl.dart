import '../domain/lock_repository.dart';
import 'biometric_service.dart';
import 'pin_store.dart';

class LockRepositoryImpl implements LockRepository {
  LockRepositoryImpl(this._pins, this._biometrics);

  final PinStore _pins;
  final BiometricService _biometrics;

  @override
  Future<bool> hasPin() => _pins.hasPin();

  @override
  Future<void> setPin(String pin) => _pins.savePin(pin);

  @override
  Future<bool> verifyPin(String pin) => _pins.verify(pin);

  @override
  Future<void> clearPin() => _pins.clear();

  @override
  Future<bool> biometricAvailable() => _biometrics.isAvailable();

  @override
  Future<bool> biometricAuthenticate(String reason) => _biometrics.authenticate(reason);
}
