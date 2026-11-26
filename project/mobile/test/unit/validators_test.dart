import 'package:afab_mobile/core/validation/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppValidators', () {
    test('validates email addresses strictly', () {
      expect(AppValidators.isValidEmail('founder@afab.ai'), isTrue);
      expect(AppValidators.isValidEmail('  finance+ops@acme.co.uk  '), isTrue);
      expect(AppValidators.isValidEmail('not-an-email'), isFalse);
      expect(AppValidators.isValidEmail('missing@domain'), isFalse);
      expect(AppValidators.isValidEmail('a b@acme.com'), isFalse);
    });

    test('evaluates 5-rule password strength accurately', () {
      final weak = AppValidators.evaluatePassword('abc');
      expect(weak.hasMinLength, isFalse);
      expect(weak.hasLowercase, isTrue);
      expect(weak.hasUppercase, isFalse);
      expect(weak.hasDigit, isFalse);
      expect(weak.hasSpecial, isFalse);
      expect(weak.score, 1);
      expect(weak.isStrongEnough, isFalse);

      final missingSpecial = AppValidators.evaluatePassword('Password1');
      expect(missingSpecial.score, 4);
      expect(missingSpecial.hasSpecial, isFalse);
      expect(missingSpecial.isStrongEnough, isFalse);

      final strong = AppValidators.evaluatePassword('Afab!2026');
      expect(strong.score, 5);
      expect(strong.isStrongEnough, isTrue);
    });

    test('preserves Base64URL underscores and hyphens in reset tokens', () {
      const tokenWithUnderscore = 'AbC_123-xyZ_987';
      expect(
        AppValidators.sanitizeResetToken('  AbC_123-xyZ_987!@#  '),
        tokenWithUnderscore,
      );
      expect(
        AppValidators.sanitizeResetToken('AbC%5F123-xyZ_987'),
        tokenWithUnderscore,
      );
    });
  });
}
