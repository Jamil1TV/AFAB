import 'dart:typed_data';

enum ReceiptValidationError {
  empty,
  tooLarge,
  unsupportedType,
}

class ReceiptValidationResult {
  const ReceiptValidationResult._({this.mimeType, this.error});

  const ReceiptValidationResult.valid(String mimeType)
      : this._(mimeType: mimeType);

  const ReceiptValidationResult.invalid(ReceiptValidationError error)
      : this._(error: error);

  final String? mimeType;
  final ReceiptValidationError? error;

  bool get isValid => mimeType != null && error == null;
}

/// Validates receipt payloads against exact backend `ReceiptService.java` rules:
/// non-empty, `<= 10,485,760` bytes (10 MB), and magic bytes for PDF, PNG, JPEG, WEBP.
abstract final class ReceiptValidator {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10,485,760 bytes

  static ReceiptValidationResult validateBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      return const ReceiptValidationResult.invalid(ReceiptValidationError.empty);
    }
    if (bytes.length > maxFileSizeBytes) {
      return const ReceiptValidationResult.invalid(
        ReceiptValidationError.tooLarge,
      );
    }
    final detected = detectMimeType(bytes);
    if (detected == null) {
      return const ReceiptValidationResult.invalid(
        ReceiptValidationError.unsupportedType,
      );
    }
    return ReceiptValidationResult.valid(detected);
  }

  static String? detectMimeType(Uint8List bytes) {
    // PDF: %PDF- (25 50 44 46 2D)
    if (bytes.length >= 5 &&
        bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46 &&
        bytes[4] == 0x2D) {
      return 'application/pdf';
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return 'image/png';
    }

    // JPEG: FF D8 FF
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }

    // WEBP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && // R
        bytes[1] == 0x49 && // I
        bytes[2] == 0x46 && // F
        bytes[3] == 0x46 && // F
        bytes[8] == 0x57 && // W
        bytes[9] == 0x45 && // E
        bytes[10] == 0x42 && // B
        bytes[11] == 0x50) { // P
      return 'image/webp';
    }

    return null;
  }
}
