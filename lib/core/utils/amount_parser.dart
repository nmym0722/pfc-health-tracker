class AmountParser {
  /// "1/2", "1／2", "2.5", "２．５", "1 1/2", "0.5" などの分数・小数をパースして double を返す
  static double? parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // 全角英数・記号を半角に正規化
    String normalized = trimmed
        .replaceAll('／', '/')
        .replaceAll('．', '.')
        .replaceAll('，', '.')
        .replaceAll('　', ' ');

    // 全角数字を半角数字に変換
    normalized = normalized.replaceAllMapped(RegExp(r'[０-９]'), (m) {
      return String.fromCharCode(m.group(0)!.codeUnitAt(0) - 0xFEE0);
    });

    // 1. "1 1/2" のような帯分数
    final mixedFractionRegex = RegExp(r'^(\d+)\s+(\d+)/(\d+)$');
    final mixedMatch = mixedFractionRegex.firstMatch(normalized);
    if (mixedMatch != null) {
      final whole = double.tryParse(mixedMatch.group(1)!) ?? 0.0;
      final num = double.tryParse(mixedMatch.group(2)!) ?? 0.0;
      final den = double.tryParse(mixedMatch.group(3)!) ?? 1.0;
      if (den != 0) return whole + (num / den);
    }

    // 2. "1/2", "3/4" のような分数
    final fractionRegex = RegExp(r'^(\d+(?:\.\d+)?)/(\d+(?:\.\d+)?)$');
    final fracMatch = fractionRegex.firstMatch(normalized);
    if (fracMatch != null) {
      final num = double.tryParse(fracMatch.group(1)!) ?? 0.0;
      final den = double.tryParse(fracMatch.group(2)!) ?? 1.0;
      if (den != 0) return num / den;
    }

    // 3. "2.5", "100" のような通常の小数・整数
    return double.tryParse(normalized);
  }

  /// 数値を料理表示用にフォーマット（0.5 -> "1/2"、1.5 -> "1.5"、1.0 -> "1"）
  static String formatAmount(double value) {
    if ((value - 0.5).abs() < 0.001) return '1/2';
    if ((value - 0.25).abs() < 0.001) return '1/4';
    if ((value - 0.75).abs() < 0.001) return '3/4';
    if ((value - 0.333).abs() < 0.01) return '1/3';
    if (value == value.toInt()) return value.toInt().toString();
    return value.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
