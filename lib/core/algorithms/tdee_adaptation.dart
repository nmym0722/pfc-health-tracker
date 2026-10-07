import 'weight_ema.dart';

/// 1日の食事エネルギー摂取記録
class DailyIntakeLog {
  final DateTime date;
  final double caloriesConsumed;
  /// その日の食事が漏れなく完全に記録されたか（外食放置や記録漏れはfalse）
  final bool isCompleted;

  const DailyIntakeLog({
    required this.date,
    required this.caloriesConsumed,
    this.isCompleted = true,
  });
}

/// 動的TDEE適応の計算結果
class TdeeAdaptationResult {
  /// 推定された新しい実効TDEE (kcal/日)
  final double adaptedTdee;
  /// 推定された粗実効TDEE（クランプ前）
  final double rawEstimatedTdee;
  /// 体重変化トレンドの傾き (kg/日, 減少はマイナス)
  final double weightTrendSlopePerDay;
  /// 有効な食事記録完了日数
  final int completedIntakeDays;
  /// 有効な体重データ点数
  final int validWeightPoints;
  /// 補正の信頼性が十分か（データ不足時はfalse）
  final bool isReliable;
  /// 理由・ステータスメッセージ
  final String statusMessage;

  const TdeeAdaptationResult({
    required this.adaptedTdee,
    required this.rawEstimatedTdee,
    required this.weightTrendSlopePerDay,
    required this.completedIntakeDays,
    required this.validWeightPoints,
    required this.isReliable,
    required this.statusMessage,
  });
}

/// エネルギー保存則に基づく実効TDEE動的適応クラス
class TdeeAdaptationCalculator {
  /// 体脂肪・体重1kgあたりのエネルギー当量 (約7,200kcal)
  static const double kcalPerKg = 7200.0;

  /// TDEEの1週間あたりの最大調整幅 (kcal/日)
  static const double maxWeeklyAdjustmentKcal = 150.0;

  /// 適応計算に必要な最小記録日数（信頼性の担保）
  static const int minRequiredDays = 7;

  /// 過去の食事摂取ログとEMA体重系列から実効TDEEを計算する
  ///
  /// [currentTdee]: 現在設定されているTDEE（初期推計値または前週の適応TDEE）
  /// [intakeLogs]: 過去14〜21日間の食事摂取ログ
  /// [emaPoints]: 過去14〜21日間のEMA平滑化体重系列
  /// [windowDays]: 計算対象期間（デフォルト14日間）
  static TdeeAdaptationResult calculateAdaptedTdee({
    required double currentTdee,
    required List<DailyIntakeLog> intakeLogs,
    required List<WeightEmaPoint> emaPoints,
    int windowDays = 14,
  }) {
    if (emaPoints.length < minRequiredDays) {
      return TdeeAdaptationResult(
        adaptedTdee: currentTdee,
        rawEstimatedTdee: currentTdee,
        weightTrendSlopePerDay: 0.0,
        completedIntakeDays: 0,
        validWeightPoints: emaPoints.length,
        isReliable: false,
        statusMessage: '体重データが不足しています（最低$minRequiredDays日必要）',
      );
    }

    // 1. 食事記録完了日のみを抽出し、平均摂取カロリーを算出
    final completedIntakes = intakeLogs.where((log) => log.isCompleted).toList();
    if (completedIntakes.length < (windowDays * 0.5).ceil()) {
      return TdeeAdaptationResult(
        adaptedTdee: currentTdee,
        rawEstimatedTdee: currentTdee,
        weightTrendSlopePerDay: 0.0,
        completedIntakeDays: completedIntakes.length,
        validWeightPoints: emaPoints.length,
        isReliable: false,
        statusMessage: '完了した食事記録が不足しています（対象期間の半分以上の記録が必要）',
      );
    }

    final totalCalories = completedIntakes.fold<double>(
      0.0,
      (sum, item) => sum + item.caloriesConsumed,
    );
    final avgIntakeCalories = totalCalories / completedIntakes.length;

    // 2. EMA体重系列の線形回帰トレンド（傾き: kg/日）を計算
    final slopePerDay = _calculateLinearRegressionSlope(emaPoints);

    // 3. エネルギー保存則から実効TDEEを逆算
    // 傾き > 0 (体重増): 摂取 > 消費 なので TDEE = 摂取 - 余剰
    // 傾き < 0 (体重減): 摂取 < 消費 なので TDEE = 摂取 - (-赤字) = 摂取 + 赤字
    // 日次エネルギー過不足 = slopePerDay * 7200 kcal
    final dailySurplusOrDeficit = slopePerDay * kcalPerKg;
    final rawEstimatedTdee = avgIntakeCalories - dailySurplusOrDeficit;

    // 4. 急激な変動を防ぐ週次リミッター（クランプ）
    const maxAllowedChange = maxWeeklyAdjustmentKcal;
    final diff = rawEstimatedTdee - currentTdee;
    final clampedDiff = diff.clamp(-maxAllowedChange, maxAllowedChange);
    final adaptedTdee = (currentTdee + clampedDiff).roundToDouble();

    return TdeeAdaptationResult(
      adaptedTdee: adaptedTdee,
      rawEstimatedTdee: rawEstimatedTdee.roundToDouble(),
      weightTrendSlopePerDay: slopePerDay,
      completedIntakeDays: completedIntakes.length,
      validWeightPoints: emaPoints.length,
      isReliable: true,
      statusMessage: clampedDiff != diff
          ? '補正リミッター適用: 週最大補正幅 (±${maxAllowedChange.toInt()}kcal) で調整しました'
          : '正常に適応更新されました',
    );
  }

  /// 最小二乗法による線形回帰で1日あたりの傾き（kg/日）を算出
  static double _calculateLinearRegressionSlope(List<WeightEmaPoint> points) {
    if (points.length < 2) return 0.0;

    final sorted = List<WeightEmaPoint>.from(points)
      ..sort((a, b) => a.date.compareTo(b.date));

    final baseDate = sorted.first.date;
    final n = sorted.length;

    double sumX = 0.0;
    double sumY = 0.0;
    double sumXY = 0.0;
    double sumXX = 0.0;

    for (final pt in sorted) {
      final x = pt.date.difference(baseDate).inHours / 24.0;
      final y = pt.emaWeight;

      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumXX += x * x;
    }

    final denominator = (n * sumXX - sumX * sumX);
    if (denominator.abs() < 1e-9) return 0.0;

    final slope = (n * sumXY - sumX * sumY) / denominator;
    return slope;
  }
}
