import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

/// モバイル・テスト用の写真取得ヘルパー
class AppImagePicker {
  static final _picker = ImagePicker();

  static Future<({Uint8List bytes, String mimeType})?> takePhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return (bytes: bytes, mimeType: file.mimeType ?? 'image/jpeg');
    } catch (_) {
      return null;
    }
  }

  static Future<({Uint8List bytes, String mimeType})?> pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      final bytes = await file.readAsBytes();
      return (bytes: bytes, mimeType: file.mimeType ?? 'image/jpeg');
    } catch (_) {
      return null;
    }
  }
}
