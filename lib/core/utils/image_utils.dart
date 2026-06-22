import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  ImageUtils._();

  static Future<String> xFileToBase64(XFile file) async {
    final bytes = await file.readAsBytes();
    return bytesToBase64(bytes);
  }

  static String bytesToBase64(Uint8List bytes) {
    final base64String = base64Encode(bytes);
    return 'data:image/jpeg;base64,$base64String';
  }

  static Future<String> uploadXFileToStorage({
    required XFile file,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    final bytes = await file.readAsBytes();
    return uploadBytesToStorage(
      bytes: bytes,
      path: path,
      contentType: contentType,
    );
  }

  static Future<String> uploadBytesToStorage({
    required Uint8List bytes,
    required String path,
    String contentType = 'image/jpeg',
  }) async {
    final ref = FirebaseStorage.instance.ref(path);

    // Web cannot use dart:io File handles, so always upload bytes with putData.
    // This also works on Android/iOS and keeps one platform-safe upload path.
    final task = await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );
    return task.ref.getDownloadURL();
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
