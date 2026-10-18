import '../../models/food_master.dart';
import '../../models/recipe.dart';

/// 逆算された単品食材の推奨分量提案モデル
class SuggestedFoodPortion {
  final FoodMaster food;
  final double recommendedAmount;
  final String reasonTag;

  const SuggestedFoodPortion({
    required this.food,
    required this.recommendedAmount,
    required this.reasonTag,
  });

  double get _ratio => food.baseAmount > 0 ? recommendedAmount / food.baseAmount : 0.0;
  double get calories => food.calories * _ratio;
  double get protein => food.protein * _ratio;
  double get fat => food.fat * _ratio;
  double get carbs => food.carbs * _ratio;
}

/// 残りPFC逆算アドバイス結果モデル
class RemainingPfcAdvice {
  final double remainingCalories;
  final double remainingProtein;
  final double remainingFat;
  final double remainingCarbs;
  final String headline;
  final bool isGoalMetOrExceeded;
  final List<SuggestedFoodPortion> suggestedFoods;
  final List<Recipe> matchingRecipes;

  const RemainingPfcAdvice({
    required this.remainingCalories,
    required this.remainingProtein,
    required this.remainingFat,
    required this.remainingCarbs,
    required this.headline,
    required this.isGoalMetOrExceeded,
    required this.suggestedFoods,
    required this.matchingRecipes,
  });
}

/// 残りPFC枠から最適な食材と分量を逆算する純粋ロジッククラス
class RemainingPfcAdvisor {
  const RemainingPfcAdvisor._();

  static RemainingPfcAdvice analyze({
    required double targetCalories,
    required double currentCalories,
    required double targetProtein,
    required double currentProtein,
    required double targetFat,
    required double currentFat,
    required double targetCarbs,
    required double currentCarbs,
    required List<FoodMaster> foods,
    required List<Recipe> recipes,
  }) {
    final remCal = targetCalories - currentCalories;
    final remP = targetProtein - currentProtein;
    final remF = targetFat - currentFat;
    final remC = targetCarbs - currentCarbs;

    // 目標をほぼ達成している、またはカロリー残枠が80kcal未満の場合
    if (remCal < 80 || (remP <= 5 && remC <= 10)) {
      final isOver = remCal < -100;
      return RemainingPfcAdvice(
        remainingCalories: remCal,
        remainingProtein: remP,
        remainingFat: remF,
        remainingCarbs: remC,
        headline: isOver
            ? '本日の目標カロリーを超過しています。以降の食事は低カロリーな汁物や海藻・きのこ類がおすすめです。'
            : '本日のPFC目標をほぼ達成しています！素晴らしいペースです。',
        isGoalMetOrExceeded: true,
        suggestedFoods: const [],
        matchingRecipes: const [],
      );
    }

    final suggestions = <SuggestedFoodPortion>[];
    final usedFoodIds = <String>{};

    final bool isFatTight = remF <= 8.0;

    // 1. タンパク質が不足している場合 (残り10g以上)
    if (remP >= 10.0) {
      // 高タンパクかつ残り脂質枠を超えにくい食材をスコア順でソート
      final pCandidates = foods.where((f) {
        if (f.protein < 8.0 || f.calories <= 0) return false;
        final pCalRatio = (f.protein * 4.0) / f.calories;
        if (isFatTight) {
          return pCalRatio >= 0.55 && f.fat <= 3.5;
        }
        return pCalRatio >= 0.35;
      }).toList()
        ..sort((a, b) {
          // お気に入り優先＋高P/低Fスコア順
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          final scoreA = a.protein / (a.fat + 1.0);
          final scoreB = b.protein / (b.fat + 1.0);
          return scoreB.compareTo(scoreA);
        });

      for (final food in pCandidates.take(2)) {
        // 残りPの60〜100%（最大40gのP）を補う分量を逆算
        final targetPForSingle = remP.clamp(12.0, 38.0);
        final rawRatio = targetPForSingle / food.protein;
        final roundedAmount = _roundNiceAmount(food, food.baseAmount * rawRatio);

        if (roundedAmount > 0) {
          final portion = SuggestedFoodPortion(
            food: food,
            recommendedAmount: roundedAmount,
            reasonTag: isFatTight ? '高P・超低脂質' : 'タンパク質補給',
          );
          if (portion.calories <= remCal + 80) {
            suggestions.add(portion);
            usedFoodIds.add(food.id);
          }
        }
      }
    }

    // 2. 炭水化物が不足している場合 (残り20g以上)
    if (remC >= 20.0) {
      final cCandidates = foods.where((f) {
        if (usedFoodIds.contains(f.id)) return false;
        if (f.carbs < 15.0 || f.calories <= 0) return false;
        final cCalRatio = (f.carbs * 4.0) / f.calories;
        return cCalRatio >= 0.65 && f.fat <= 3.0;
      }).toList()
        ..sort((a, b) {
          if (a.isFavorite != b.isFavorite) {
            return a.isFavorite ? -1 : 1;
          }
          return b.carbs.compareTo(a.carbs);
        });

      for (final food in cCandidates.take(2)) {
        // 残りC（最大75gのC、かつ残りカロリー内）を補う分量を逆算
        final maxCByCal = ((remCal * 0.7) / 4.0).clamp(15.0, 80.0);
        final targetCForSingle = remC.clamp(15.0, maxCByCal);
        final rawRatio = targetCForSingle / food.carbs;
        final roundedAmount = _roundNiceAmount(food, food.baseAmount * rawRatio);

        if (roundedAmount > 0) {
          final portion = SuggestedFoodPortion(
            food: food,
            recommendedAmount: roundedAmount,
            reasonTag: 'クリーン糖質補給',
          );
          if (portion.calories <= remCal + 80) {
            suggestions.add(portion);
            usedFoodIds.add(food.id);
          }
        }
      }
    }

    // 3. 良質な脂質も余裕がある場合 (残りFが12g以上かつ提案数が少ない時)
    if (remF >= 12.0 && suggestions.length < 3) {
      final balancedCandidates = foods.where((f) {
        if (usedFoodIds.contains(f.id)) return false;
        return f.protein >= 6.0 && f.fat >= 4.0 && f.fat <= remF;
      }).toList();

      for (final food in balancedCandidates.take(1)) {
        final roundedAmount = _roundNiceAmount(food, food.baseAmount);
        suggestions.add(
          SuggestedFoodPortion(
            food: food,
            recommendedAmount: roundedAmount,
            reasonTag: 'P+良質脂質',
          ),
        );
      }
    }

    // 4. 残りカロリー・PFC枠に収まるマイレシピの抽出
    final matchedRecipes = recipes.where((r) {
      final cal = r.caloriesPerServing;
      final p = r.proteinPerServing;
      final f = r.fatPerServing;
      if (cal <= 0 || cal > remCal + 100) return false;
      if (isFatTight && f > remF + 4.0) return false;
      return (remP >= 10 && p >= 12) || (remC >= 20 && r.carbsPerServing >= 20);
    }).take(2).toList();

    // ヘッドライン文の生成
    final List<String> needs = [];
    if (remP >= 10) needs.add('P あと${remP.round()}g');
    if (remC >= 20) needs.add('C あと${remC.round()}g');
    if (!isFatTight && remF >= 10) needs.add('F 残り${remF.round()}g');

    final String headline;
    if (isFatTight && remP >= 10) {
      headline = '脂質枠が残り${remF > 0 ? remF.toStringAsFixed(0) : 0}gです。低脂質・高タンパクな食材で残りP（${remP.round()}g）を埋めましょう。';
    } else if (needs.isNotEmpty) {
      headline = '残り ${remCal.round()} kcal（${needs.join(' / ')}）にフィットする逆算メニュー提案:';
    } else {
      headline = '残り ${remCal.round()} kcal の範囲内で調整可能です。';
    }

    return RemainingPfcAdvice(
      remainingCalories: remCal,
      remainingProtein: remP,
      remainingFat: remF,
      remainingCarbs: remC,
      headline: headline,
      isGoalMetOrExceeded: false,
      suggestedFoods: suggestions.take(4).toList(),
      matchingRecipes: matchedRecipes,
    );
  }

  /// 食材の単位に応じてキリの良い数値（g/mlは10刻み、個/食は0.5刻み）に丸める
  static double _roundNiceAmount(FoodMaster food, double rawAmount) {
    if (rawAmount <= 0) return food.baseAmount;
    switch (food.unit) {
      case FoodUnit.g:
      case FoodUnit.ml:
        final rounded10 = (rawAmount / 10.0).round() * 10.0;
        return rounded10.clamp(20.0, 400.0);
      case FoodUnit.piece:
      case FoodUnit.serving:
      case FoodUnit.tablespoon:
      case FoodUnit.teaspoon:
        final roundedHalf = (rawAmount * 2.0).round() / 2.0;
        return roundedHalf.clamp(0.5, 5.0);
    }
  }
}
