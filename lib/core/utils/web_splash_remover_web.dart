import 'dart:js_interop';

@JS('removeAppSplash')
external void _removeAppSplash();

/// Web環境向けの実装: index.htmlに定義されたremoveAppSplash()を実行
void removeWebSplash() {
  try {
    _removeAppSplash();
  } catch (_) {
    // スプラッシュが存在しないか呼び出し失敗時は安全に無視
  }
}
