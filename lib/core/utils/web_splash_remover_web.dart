// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web環境向けの実装: index.htmlに定義されたremoveAppSplash()を実行
void removeWebSplash() {
  try {
    js.context.callMethod('removeAppSplash');
  } catch (_) {
    // スプラッシュが存在しないか呼び出し失敗時は安全に無視
  }
}
