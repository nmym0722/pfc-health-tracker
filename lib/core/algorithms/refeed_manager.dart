/// リフィードの種類
enum RefeedType {
  none,               // 通常日（リフィードなし）
  scheduled,          // 定期的な計画的リフィード（週1日等の代謝維持）
  performanceBonus,   // 減量先行ボーナスリフィード（目標ペースクリアによる解放）
}

/// リフィード判定結果と推奨PFC
class RefeedDecision {
  final RefeedType type;
  final bool isEligible;
  /// 追加解放カロリー (kcal)
  final double extraCalories;
  /// リフィード時の総目標カロリー (kcal)
  final double totalCalories;
  /// 推奨PFC (g)
  final double targetProteinGrams;
  final double targetFatGrams;
  final double targetCarbsGrams;
  /// 追加炭水化物量 (g)
  final double extraCarbsGrams;
  /// 判定理由メッセージ
  final String message;

  const RefeedDecision({
    required this.type,
    required this.isEligible,
    required this.extraCalories,
    required this.totalCalories,
    required this.targetProteinGrams,
    required this.targetFatGrams,
    required this.targetCarbsGrams,
    required this.extraCarbsGrams,
    required this.message,
  });
}

/// リフィード管理・計算クラス
class RefeedManager {
  /// 体重1kgあたりの脂肪エネルギー当量
  static const double kcalPerKg = 7200.0;

  /// 先行ボーナス枠の最大解放エネルギー上限 (kcal)
  static const double maxBonusCapKcal = 1500.0;

  /// 先行エネルギーの解放比率（浮いたカロリーの50%）
  static const double bonusReleaseRatio = 0.5;

  /// リフィードの適格性と推奨マクロ栄養素を判定する
  ///
  /// [currentEmaWeight]: 最新のEMA平滑化体重 (kg)
  /// [plannedTargetWeight]: 現時点での計画線（理想ペース目標体重） (kg)
  /// [baseTargetCalories]: 通常日の目標カロリー (kcal)
  /// [currentTdee]: 現在の実効TDEE (kcal)
  /// [baseProteinGrams]: 通常日の目標タンパク質 (g)
  /// [baseFatGrams]: 通常日の目標脂質 (g)
  /// [baseCarbsGrams]: 通常日の目標炭水化物 (g)
  /// [isScheduledRefeedDay]: 今日が設定された定期リフィード曜日か
  static RefeedDecision evaluateRefeed({
    required double currentEmaWeight,
    required double plannedTargetWeight,
    required double baseTargetCalories,
    required double currentTdee,
    required double baseProteinGrams,
    required double baseFatGrams,
    required double baseCarbsGrams,
    bool isScheduledRefeedDay = false,
  }) {
    // 計画線との差分（先行している場合は正の値: 例 計画70.5kgに対し実測EMA70.0kgなら +0.5kg先行）
    final weightLeadKg = plannedTargetWeight - currentEmaWeight;

    // 1. 定期計画的リフィードの場合（維持カロリーTDEEまで解放）
    if (isScheduledRefeedDay) {
      double extraCalories = (currentTdee - baseTargetCalories);
      if (extraCalories < 200.0) extraCalories = 200.0; // 最低でも200kcalはバッファ付与

      // 先行ボーナスがあれば追加（最大キャップあり）
      if (weightLeadKg > 0) {
        final bonus = (weightLeadKg * kcalPerKg * bonusReleaseRatio).clamp(0.0, 500.0);
        extraCalories += bonus;
      }

      final extraCarbs = extraCalories / 4.0; // 全て炭水化物に変換
      final totalCalories = baseTargetCalories + extraCalories;
      final targetCarbs = baseCarbsGrams + extraCarbs;

      return RefeedDecision(
        type: RefeedType.scheduled,
        isEligible: true,
        extraCalories: extraCalories.roundToDouble(),
        totalCalories: totalCalories.roundToDouble(),
        targetProteinGrams: baseProteinGrams.roundToDouble(),
        targetFatGrams: baseFatGrams.roundToDouble(),
        targetCarbsGrams: targetCarbs.roundToDouble(),
        extraCarbsGrams: extraCarbs.roundToDouble(),
        message: '計画的リフィード日です。代謝維持のため炭水化物を中心に+${extraCalories.toInt()}kcal補給しましょう。',
      );
    }

    // 2. 先行ボーナス枠（計画より0.2kg以上先行している場合）
    if (weightLeadKg >= 0.2) {
      final totalSavedEnergy = weightLeadKg * kcalPerKg;
      final extraCalories = (totalSavedEnergy * bonusReleaseRatio).clamp(0.0, maxBonusCapKcal);
      final extraCarbs = extraCalories / 4.0;
      final totalCalories = baseTargetCalories + extraCalories;
      final targetCarbs = baseCarbsGrams + extraCarbs;

      return RefeedDecision(
        type: RefeedType.performanceBonus,
        isEligible: true,
        extraCalories: extraCalories.roundToDouble(),
        totalCalories: totalCalories.roundToDouble(),
        targetProteinGrams: baseProteinGrams.roundToDouble(),
        targetFatGrams: baseFatGrams.roundToDouble(),
        targetCarbsGrams: targetCarbs.roundToDouble(),
        extraCarbsGrams: extraCarbs.roundToDouble(),
        message: '減量ペースが順調に先行しています（-${weightLeadKg.toStringAsFixed(1)}kgクリア）。ハイカーボボーナスとして+${extraCalories.toInt()}kcal（炭水化物+${extraCarbs.toInt()}g）が利用可能です。',
      );
    }

    // 3. 通常日（通常ペースまたは遅延中）
    return RefeedDecision(
      type: RefeedType.none,
      isEligible: false,
      extraCalories: 0.0,
      totalCalories: baseTargetCalories,
      targetProteinGrams: baseProteinGrams,
      targetFatGrams: baseFatGrams,
      targetCarbsGrams: baseCarbsGrams,
      extraCarbsGrams: 0.0,
      message: '本日は通常の目標カロリーで進行します。',
    );
  }
}
