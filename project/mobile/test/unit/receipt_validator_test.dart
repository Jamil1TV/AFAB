import 'dart:typed_data';

import 'package:afab_mobile/features/receipts/data/receipt_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReceiptValidator magic bytes & size limits', () {
    test('accepts valid PDF magic header', () {
      final bytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31]);
      final res = ReceiptValidator.validateBytes(bytes);
      expect(res.isValid, isTrue);
      expect(res.mimeType, 'application/pdf');
    });

    test('accepts valid PNG, JPEG, and WEBP magic headers', () {
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final webp = Uint8List.fromList([
        0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50,
      ]);

      expect(ReceiptValidator.validateBytes(png).mimeType, 'image/png');
      expect(ReceiptValidator.validateBytes(jpeg).mimeType, 'image/jpeg');
      expect(ReceiptValidator.validateBytes(webp).mimeType, 'image/webp');
    });

    test('rejects empty, oversized (>10MB), and unsupported bytes', () {
      expect(
        ReceiptValidator.validateBytes(Uint8List(0)).error,
        ReceiptValidationError.empty,
      );
      expect(
        ReceiptValidator.validateBytes(
          Uint8List(ReceiptValidator.maxFileSizeBytes + 1),
        ).error,
        ReceiptValidationError.tooLarge,
      );
      final fakeText = Uint8List.fromList('hello world text'.codeUnits);
      expect(
        ReceiptValidator.validateBytes(fakeText).error,
        ReceiptValidationError.unsupportedType,
      );
    });
  });
}
