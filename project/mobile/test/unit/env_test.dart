import 'package:afab_mobile/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnv URL normalization & defaults', () {
    test('normalizeApiBaseUrl appends /api/v1 when missing and trims slashes',
        () {
      expect(
        AppEnv.normalizeApiBaseUrl('http://10.0.2.2:8080'),
        'http://10.0.2.2:8080/api/v1',
      );
      expect(
        AppEnv.normalizeApiBaseUrl('  https://api.afab.app/  '),
        'https://api.afab.app/api/v1',
      );
      expect(
        AppEnv.normalizeApiBaseUrl('http://192.168.0.172:8080/api/'),
        'http://192.168.0.172:8080/api/v1',
      );
      expect(
        AppEnv.normalizeApiBaseUrl('http://10.0.2.2:8080/api/v1/'),
        'http://10.0.2.2:8080/api/v1',
      );
    });

    test('apiBaseUrl resolves cleanly without dotenv loaded', () {
      expect(AppEnv.apiBaseUrl, endsWith('/api/v1'));
    });
  });
}
