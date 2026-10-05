// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// Web（ブラウザ/PWA）専用の写真取得ヘルパー
class AppImagePicker {
  /// カメラで撮影（スマホの背面カメラを直接起動）
  static Future<({Uint8List bytes, String mimeType})?> takePhoto() async {
    final completer = Completer<({Uint8List bytes, String mimeType})?>();
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('capture', 'environment'); // スマホの背面カメラを直接呼び出し

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        final mime = file.type.isEmpty ? 'image/jpeg' : file.type;
        if (result is Uint8List) {
          if (!completer.isCompleted) {
            completer.complete((bytes: result, mimeType: mime));
          }
        } else if (result is ByteBuffer) {
          if (!completer.isCompleted) {
            completer.complete((bytes: Uint8List.view(result), mimeType: mime));
          }
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      });
      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      reader.readAsArrayBuffer(file);
    });

    input.click();
    return completer.future;
  }

  /// 写真ライブラリから選択
  static Future<({Uint8List bytes, String mimeType})?> pickFromGallery() async {
    final completer = Completer<({Uint8List bytes, String mimeType})?>();
    final input = html.FileUploadInputElement()
      ..accept = 'image/*';

    input.onChange.listen((event) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files[0];
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        final mime = file.type.isEmpty ? 'image/jpeg' : file.type;
        if (result is Uint8List) {
          if (!completer.isCompleted) {
            completer.complete((bytes: result, mimeType: mime));
          }
        } else if (result is ByteBuffer) {
          if (!completer.isCompleted) {
            completer.complete((bytes: Uint8List.view(result), mimeType: mime));
          }
        } else {
          if (!completer.isCompleted) completer.complete(null);
        }
      });
      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      reader.readAsArrayBuffer(file);
    });

    input.click();
    return completer.future;
  }
}
