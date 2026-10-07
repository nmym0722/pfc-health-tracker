import 'weight_ema.dart';

/// ガードレール評価結果
class GuardrailEvaluation {
  /// 初期ウォームアップ（マスク）期間中か
  final bool isWarmupActive;
  /// 停滞期（プラトー）が検出されたか
  final bool isPlateauDetected;
  /// BMR下限防衛が発動したか（目標カロリーが強制的にBMRでクランプされたか）
  final bool isBmrFloorActive;
  /// 期日の延長または目標緩和の提案が必要か
  final bool suggestExtendDeadline;
  /// ガードレール適用後の安全な目標摂取カロリー (kcal)
  final double safeTargetCalories;
  /// 警告・アドバイスメッセージ
  final List<String> warnings;

  const GuardrailEvaluation({
    required this.isWarmupActive,
    required this.isPlateauDetected,
    required this.isBmrFloorActive,
    required this.suggestExtendDeadline,
    required this.safeTargetCalories,
    required this.warnings,
  });
}

/// 人体生理に基づいた安全ガードレール判定クラス
class SafetyGuardrails {
  /// 初期ウォームアップ期間（日数）。水分が抜ける期間のマスク
  static const int warmupDurationDays = 14;

  /// プラトー（停滞期）判定の観察期間（日数）
  static const int plateauWindowDays = 14;

  /// プラトーとみなすEMA体重変動の許容幅 (kg)
  static const double plateauWeightThresholdKg = 0.15;

  /// ガードレールの総合評価を実行する
  ///
  /// [startDate]: 減量プログラム開始日
  /// [evaluationDate]: 評価日（通常は今日）
  /// [rawCalculatedTargetCalories]: 計算された生の目標カロリー
  /// [bmr]: ユーザーの基礎代謝 (BMR)
  /// [recentEmaPoints]: 直近14日以上のEMA体重系列
  /// [isAdherenceHigh]: 食事目標が概ね守られているか（過食していないか）
  static GuardrailEvaluation evaluate({
    required DateTime startDate,
    required DateTime evaluationDate,
    required double rawCalculatedTargetCalories,
    required double bmr,
    required List<WeightEmaPoint> recentEmaPoints,
    bool isAdherenceHigh = true,
  }) {
    final warnings = <String>[];

    // 1. 初期ウォームアップ期間判定
    final daysSinceStart = evaluationDate.difference(startDate).inDays;
    final isWarmupActive = daysSinceStart < warmupDurationDays;
    if (isWarmupActive) {
      warnings.add(
        '開始後初期ウォームアップ期間中です（残り${warmupDurationDays - daysSinceStart}日）。水分の急減を考慮し、代謝適応およびボーナス解放はマスクされます。',
      );
    }

    // 2. 停滞期（プラトー）検出
    bool isPlateauDetected = false;
    if (!isWarmupActive && recentEmaPoints.length >= plateauWindowDays && isAdherenceHigh) {
      final sortedPoints = List<WeightEmaPoint>.from(recentEmaPoints)
        ..sort((a, b) => a.date.compareTo(b.date));

      final firstEma = sortedPoints.first.emaWeight;
      final lastEma = sortedPoints.last.emaWeight;
      final weightChange = (lastEma - firstEma).abs();

      // 14日間でEMA体重がほとんど変化していない場合
      if (weightChange <= plateauWeightThresholdKg) {
        isPlateauDetected = true;
        warnings.add(
          '停滞期（プラトー）の可能性があります。食事制限をこれ以上強化せず、水分貯留か活動量低下かのセルフチェックを推奨します。',
        );
      }
    }

    // 3. BMRフロア値防衛 & 期日延長サジェスト
    bool isBmrFloorActive = false;
    bool suggestExtendDeadline = false;
    double safeCalories = rawCalculatedTargetCalories;

    if (rawCalculatedTargetCalories < bmr) {
      isBmrFloorActive = true;
      safeCalories = bmr;
      warnings.add(
        '健康維持のため、目標カロリーが基礎代謝（${bmr.toInt()}kcal）未満にならないよう下限ガードを適用しました。',
      );

      // 生の計算値がBMRを150kcal以上下回っている場合は、目標ペースに無理があるため期日延長を提案
      if ((bmr - rawCalculatedTargetCalories) >= 150.0) {
        suggestExtendDeadline = true;
        warnings.add(
          '現在の減量ペースを維持するには過度な食事制限が必要です。達成期日の延長または目標体重の緩和を推奨します。',
        );
      }
    }

    return GuardrailEvaluation(
      isWarmupActive: isWarmupActive,
      isPlateauDetected: isPlateauDetected,
      isBmrFloorActive: isBmrFloorActive,
      suggestExtendDeadline: suggestExtendDeadline,
      safeTargetCalories: safeCalories.roundToDouble(),
      warnings: warnings,
    );
  }
}
