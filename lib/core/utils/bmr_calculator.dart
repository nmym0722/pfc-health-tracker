import '../../models/user_profile.dart';

class BmrCalculator {
  /// 1. 基礎代謝 (BMR) 算出: ハリス・ベネディクト改訂式 (Roza and Shizgal, 1984)
  static double calculateBmr({
    required double weight, // kg
    required double height, // cm
    required int age,
    required Gender gender,
  }) {
    if (gender == Gender.male) {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  /// 2. 活動レベル係数
  static double getActivityMultiplier(ActivityLevel level) {
    switch (level) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
    }
  }

  /// 3. 総消費カロリー (TDEE) 算出
  static double calculateTdee({
    required double weight,
    required double height,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
  }) {
    final bmr = calculateBmr(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );
    return bmr * getActivityMultiplier(activityLevel);
  }

  /// 4. 【仕様F-4】体重更新時の動的目標カロリー & PFC算定
  /// [adaptedTdee] が指定された場合は、数式による推定TDEEではなくエネルギー保存則から逆算された実効TDEEを基準とします。
  static UserGoals calculateAdaptiveGoals({
    required double currentWeight,
    required double targetWeight,
    required double height,
    required int age,
    required Gender gender,
    required ActivityLevel activityLevel,
    required GoalType goalType,
    required DateTime targetDate,
    DateTime? currentDate,
    double? adaptedTdee,
  }) {
    final now = currentDate ?? DateTime.now();
    final daysRemaining = targetDate.difference(now).inDays;
    final validDays = daysRemaining > 0 ? daysRemaining : 1;

    // 基準TDEE: 動的適応TDEEがあればそれを採用、なければハリス・ベネディクト式で算出
    final baseTdee = adaptedTdee ??
        calculateTdee(
          weight: currentWeight,
          height: height,
          age: age,
          gender: gender,
          activityLevel: activityLevel,
        );

    double dailyCalorieAdjustment = 0.0;
    final weightDiff = currentWeight - targetWeight; // 減量の場合は正の値

    if (goalType == GoalType.weightLoss && weightDiff > 0) {
      // 1kgあたり約7,200kcalの赤字が必要
      final totalDeficitNeeded = weightDiff * 7200.0;
      dailyCalorieAdjustment = -(totalDeficitNeeded / validDays);
      // 安全のため1日の最大カロリー赤字は -1000kcal にクランプ
      if (dailyCalorieAdjustment < -1000.0) {
        dailyCalorieAdjustment = -1000.0;
      }
    } else if (goalType == GoalType.weightGain && weightDiff < 0) {
      final totalSurplusNeeded = (-weightDiff) * 7200.0;
      dailyCalorieAdjustment = (totalSurplusNeeded / validDays);
      if (dailyCalorieAdjustment > 800.0) {
        dailyCalorieAdjustment = 800.0;
      }
    }

    double targetCalories = baseTdee + dailyCalorieAdjustment;

    // BMR未満にならないようセーフティチェック（BMRフロア値防衛）
    final bmr = calculateBmr(
      weight: currentWeight,
      height: height,
      age: age,
      gender: gender,
    );
    if (targetCalories < bmr) {
      targetCalories = bmr;
    }

    // PFC配分計算
    // P (Protein): 体重 × 2.0g (4kcal/g)
    final targetProtein = currentWeight * 2.0;
    final proteinCalories = targetProtein * 4.0;

    // F (Fat): 総カロリーの 22.5% (9kcal/g)
    final fatCalories = targetCalories * 0.225;
    final targetFat = fatCalories / 9.0;

    // C (Carbs): 残りカロリー (4kcal/g)
    final remainingCalories = targetCalories - (proteinCalories + fatCalories);
    final targetCarbs = remainingCalories > 0 ? remainingCalories / 4.0 : 50.0;

    return UserGoals(
      targetCalories: targetCalories.roundToDouble(),
      targetProtein: targetProtein.roundToDouble(),
      targetFat: targetFat.roundToDouble(),
      targetCarbs: targetCarbs.roundToDouble(),
    );
  }
}
