import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Wraps Google ML Kit's on-device text recognizer and adds a light
/// heuristic on top: medicine strip photos are full of noise (batch
/// numbers, MRP, expiry dates, storage instructions, regulatory text), and
/// there's no reliable general rule for "which printed line is the brand
/// vs. the product name." So instead of pretending to know for certain,
/// this filters out obvious noise and ranks what's left by prominence
/// (roughly: longer, more letter-heavy lines tend to be the product name
/// printed in large type) — good enough for a first guess, with the raw
/// candidate list still returned so the UI can let the user correct it.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static final RegExp _noiseWords = RegExp(
    r'(mrp|rs\.?\s|batch|b\.no|exp\.?|mfg|mfd|storage|store\s|composition|manufactured|marketed|www\.|http|schedule|tablets?\b|capsules?\b|syrup|strip of|each film)',
    caseSensitive: false,
  );
  static final RegExp _mostlyDateOrNumber = RegExp(r'^[\d\s\/\-\.:]+$');

  Future<List<String>> recognizeCandidateLines(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final result = await _recognizer.processImage(inputImage);

    final rawLines = <String>[];
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) rawLines.add(text);
      }
    }

    final candidates = rawLines.where((line) {
      if (line.length < 2) return false;
      if (_mostlyDateOrNumber.hasMatch(line)) return false;
      if (_noiseWords.hasMatch(line)) return false;
      return true;
    }).toList();

    // Rough prominence proxy: longer, letter-dense lines first.
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates;
  }

  void dispose() {
    _recognizer.close();
  }
}
