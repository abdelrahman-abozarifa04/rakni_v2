import 'dart:typed_data';

class LicenseImageProcessor {
  LicenseImageProcessor._();
  static final instance = LicenseImageProcessor._();

  Future<Uint8List> process(Uint8List rawBytes) async {
    // For now, just return the raw bytes.
    // In a real app, this might resize, grayscale, or enhance contrast
    // to improve OCR accuracy.
    return rawBytes;
  }
}
