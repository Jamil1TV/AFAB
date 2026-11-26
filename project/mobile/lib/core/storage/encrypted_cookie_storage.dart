import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Encrypted `cookie_jar.Storage` backed by `flutter_secure_storage`
/// (Android Keystore AES-GCM / iOS Keychain `first_unlock_this_device`).
/// Persists HttpOnly `refreshToken` and double-submit `afab_csrf` cookies safely.
class EncryptedCookieStorage implements Storage {
  EncryptedCookieStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String _keyPrefix = 'afab_cookie_jar::';
  final FlutterSecureStorage _secureStorage;
  final Map<String, String> _cache = <String, String>{};
  bool _initialized = false;

  @override
  Future<void> init(bool persistSession, bool ignoreExpires) async {
    if (_initialized) return;
    final allEntries = await _secureStorage.readAll();
    for (final entry in allEntries.entries) {
      if (entry.key.startsWith(_keyPrefix)) {
        final rawKey = entry.key.substring(_keyPrefix.length);
        _cache[rawKey] = entry.value;
      }
    }
    _initialized = true;
  }

  @override
  Future<String?> read(String key) async {
    if (_cache.containsKey(key)) {
      return _cache[key];
    }
    final value = await _secureStorage.read(key: '$_keyPrefix$key');
    if (value != null) {
      _cache[key] = value;
    }
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    _cache[key] = value;
    await _secureStorage.write(key: '$_keyPrefix$key', value: value);
  }

  @override
  Future<void> delete(String key) async {
    _cache.remove(key);
    await _secureStorage.delete(key: '$_keyPrefix$key');
  }

  @override
  Future<void> deleteAll(List<String> keys) async {
    for (final key in keys) {
      _cache.remove(key);
      await _secureStorage.delete(key: '$_keyPrefix$key');
    }
  }

  Future<bool> hasAnyPersistedCookies() async {
    if (!_initialized) {
      await init(true, false);
    }
    return _cache.values.any((v) => v.contains('refreshToken'));
  }

  Future<void> clearAllCookies() async {
    final keys = List<String>.from(_cache.keys);
    await deleteAll(keys);
  }
}
