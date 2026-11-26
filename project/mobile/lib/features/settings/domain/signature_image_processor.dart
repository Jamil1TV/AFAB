import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Isolate-safe signature image processor replicating `processSignatureFile()`:
/// downscales max dimension to `800px`, converts light paper pixels
/// `(R+G+B)/3 > 215` to smooth transparent alpha, and deepens ink contrast.
Uint8List? processSignatureBytes(
  ({Uint8List rawBytes, bool makeTransparent}) args,
) {
  final decoded = img.decodeImage(args.rawBytes);
  if (decoded == null) return null;

  final resized = decoded.width > 800 || decoded.height > 800
      ? img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? 800 : null,
          height: decoded.height > decoded.width ? 800 : null,
        )
      : decoded;

  if (!args.makeTransparent) {
    return Uint8List.fromList(img.encodePng(resized));
  }

  final rgba = resized.convert(numChannels: 4);
  for (final pixel in rgba) {
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();
    final a = pixel.a.toInt();
    if (a == 0) continue;

    final brightness = (r + g + b) / 3.0;
    if (brightness > 215.0) {
      final newAlpha =
          math.max(0, (255.0 - (brightness - 215.0) * 8.0).round());
      pixel.setRgba(r, g, b, newAlpha);
    } else {
      pixel.setRgba(
        math.max(0, r - 20),
        math.max(0, g - 20),
        math.max(0, b - 15),
        a,
      );
    }
  }
  return Uint8List.fromList(img.encodePng(rgba));
}
