import 'dart:math' as math;

/// 体重測定データ点
class WeightPoint {
  final DateTime date;
  final double weight;
  /// チートデイ・ハイカーボデイの翌日・翌々日フラグ（水分急増による外れ値）
  final bool isPostCheatDay;

  const WeightPoint({
    required this.date,
    required this.weight,
    this.isPostCheatDay = false,
  });
}

/// EMA平滑化後の計算結果点
class WeightEmaPoint {
  final DateTime date;
  final double rawWeight;
  final double emaWeight;

  const WeightEmaPoint({
    required this.date,
    required this.rawWeight,
    required this.emaWeight,
  });
}

/// 不等間隔（欠損日）対応の連続時間指数移動平均（EMA）計算クラス
class WeightEmaCalculator {
  /// デフォルトの時定数 tau（日数）。約7日間の平滑化に対応
  static const double defaultTauDays = 7.0;

  /// チート翌日などの外れ値に対する更新重み減衰比率（通常の20%のみ反映）
  static const double postCheatWeightDamping = 0.2;

  /// 時系列リストから不等間隔EMA系列を計算する
  ///
  /// [points] は日付順（昇順）にソートされている必要があります。
  /// [tauDays] はEMAの時定数（日）。値が大きいほど滑らかになり、小さいほど実測値に追従します。
  static List<WeightEmaPoint> calculateEmaSeries(
    List<WeightPoint> points, {
    double tauDays = defaultTauDays,
  }) {
    if (points.isEmpty) return [];

    // 日付昇順で安全にソート
    final sorted = List<WeightPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));

    final result = <WeightEmaPoint>[];

    // 初日: 実測値をそのまま初期EMA値とする
    double currentEma = sorted.first.weight;
    result.add(WeightEmaPoint(
      date: sorted.first.date,
      rawWeight: sorted.first.weight,
      emaWeight: currentEma,
    ));

    for (int i = 1; i < sorted.length; i++) {
      final prevDate = sorted[i - 1].date;
      final curr = sorted[i];

      // 前回の測定からの経過日数（差分時間 deltaT）
      final deltaDays = curr.date.difference(prevDate).inHours / 24.0;
      final dt = deltaDays > 0 ? deltaDays : 0.0;

      // 連続時間EMAの平滑化係数: alpha = 1 - exp(-dt / tau)
      double alpha = 1.0 - math.exp(-dt / tauDays);

      // チート翌日など水分貯留が疑われる日は重みを減衰
      if (curr.isPostCheatDay) {
        alpha *= postCheatWeightDamping;
      }

      // EMA更新式: EMA_t = EMA_{t-1} + alpha * (Raw_t - EMA_{t-1})
      currentEma = currentEma + alpha * (curr.weight - currentEma);

      result.add(WeightEmaPoint(
        date: curr.date,
        rawWeight: curr.weight,
        emaWeight: currentEma,
      ));
    }

    return result;
  }

  /// 最新の単一EMA値のみを高速に取得する（既存の最新EMAがわかっている場合）
  static double updateSingleEma({
    required double previousEma,
    required double currentRawWeight,
    required double deltaDays,
    bool isPostCheatDay = false,
    double tauDays = defaultTauDays,
  }) {
    final dt = deltaDays > 0 ? deltaDays : 0.0;
    double alpha = 1.0 - math.exp(-dt / tauDays);
    if (isPostCheatDay) {
      alpha *= postCheatWeightDamping;
    }
    return previousEma + alpha * (currentRawWeight - previousEma);
  }
}
