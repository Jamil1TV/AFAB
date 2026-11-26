import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

abstract class BiometricLockService {
  Future<bool> isSupportedAndEnrolled();
  Future<bool> authenticate(String reason);
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
  Future<void> clearFlag();
}

class DeviceBiometricLockService implements BiometricLockService {
  DeviceBiometricLockService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String _enabledKey = 'afab_biometric_lock_enabled';

  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<bool> isSupportedAndEnrolled() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _localAuth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        sensitiveTransaction: true,
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isEnabled() async {
    try {
      final raw = await _secureStorage.read(key: _enabledKey);
      return raw == 'true';
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    try {
      if (enabled) {
        await _secureStorage.write(key: _enabledKey, value: 'true');
      } else {
        await _secureStorage.delete(key: _enabledKey);
      }
    } catch (_) {}
  }

  @override
  Future<void> clearFlag() => setEnabled(false);
}

final biometricLockServiceProvider = Provider<BiometricLockService>((ref) {
  return DeviceBiometricLockService();
});

final biometricLockEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.read(biometricLockServiceProvider).isEnabled();
});
