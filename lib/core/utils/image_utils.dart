import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class ImageUtils {
  ImageUtils._();

  static Future<String> xFileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  static Future<String> fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  static Uint8List base64ToBytes(String base64String) {
    final clean = base64String.contains(',')
        ? base64String.split(',').last
        : base64String;
    return base64Decode(clean);
  }

  static bool isBase64Image(String? url) {
    if (url == null) return false;
    return url.startsWith('data:image');
  }
}
