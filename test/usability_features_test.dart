import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_health_tracker/core/algorithms/remaining_pfc_advisor.dart';
import 'package:pfc_health_tracker/core/constants/default_foods.dart';
import 'package:pfc_health_tracker/core/utils/bmr_calculator.dart';
import 'package:pfc_health_tracker/core/utils/meal_assist_helper.dart';
import 'package:pfc_health_tracker/models/meal_record.dart';
import 'package:pfc_health_tracker/models/recipe.dart';
import 'package:pfc_health_tracker/models/user_profile.dart';
import 'package:pfc_health_tracker/models/weight_log.dart';
import 'package:pfc_health_tracker/services/storage_service.dart';

void main() {
  group('MealAssistHelper tests', () {
    test('inferDefaultMealType returns expected meal type for time of day', () {
      expect(
        MealAssistHelper.inferDefaultMealType(DateTime(2026, 10, 16, 7, 30)),
        MealType.breakfast,
      );
      expect(
        MealAssistHelper.inferDefaultMealType(DateTime(2026, 10, 16, 12, 15)),
        MealType.lunch,
      );
      expect(
        MealAssistHelper.inferDefaultMealType(DateTime(2026, 10, 16, 16, 0)),
        MealType.snack,
      );
      expect(
        MealAssistHelper.inferDefaultMealType(DateTime(2026, 10, 16, 19, 30)),
        MealType.dinner,
      );
    });

    test('scaleMealItem scales calories and PFC proportionally', () {
      const original = MealItem(
        id: 'item-1',
        name: '白米',
        amount: 200.0,
        unit: 'g',
        calories: 312.0,
        protein: 5.0,
        fat: 0.6,
        carbs: 74.2,
      );

      final scaled = MealAssistHelper.scaleMealItem(original, 150.0);
      expect(scaled.amount, 150.0);
      expect(scaled.calories, closeTo(234.0, 0.01));
      expect(scaled.protein, closeTo(3.75, 0.01));
      expect(scaled.fat, closeTo(0.45, 0.01));
      expect(scaled.carbs, closeTo(55.65, 0.01));
    });

    test('calculateCaloriesFromPfc uses Atwater 4-9-4 factors', () {
      final kcal = MealAssistHelper.calculateCaloriesFromPfc(
        protein: 30.0,
        fat: 10.0,
        carbs: 50.0,
      );
      // 30*4 + 10*9 + 50*4 = 120 + 90 + 200 = 410
      expect(kcal, 410.0);
    });
  });

  group('RemainingPfcAdvisor tests', () {
    test('analyze recommends high-protein low-fat foods when fat budget is tight', () {
      final advice = RemainingPfcAdvisor.analyze(
        targetCalories: 1800,
        currentCalories: 1350,
        targetProtein: 140,
        currentProtein: 105, // 残りP: 35g
        targetFat: 45,
        currentFat: 41, // 残りF: 4g (脂質タイト)
        targetCarbs: 200,
        currentCarbs: 155, // 残りC: 45g
        foods: DefaultFoods.list,
        recipes: const [],
      );

      expect(advice.isGoalMetOrExceeded, isFalse);
      expect(advice.suggestedFoods, isNotEmpty);
      final firstFood = advice.suggestedFoods.first;
      expect(firstFood.protein, greaterThan(15.0));
      expect(firstFood.fat, lessThan(5.0));
    });
  });

  group('StorageService JSON backup/restore tests', () {
    test('exportBackupJson and parseBackupJson round-trip all models accurately', () {
      final targetDate = DateTime(2026, 12, 31);
      final goals = BmrCalculator.calculateAdaptiveGoals(
        currentWeight: 68.0,
        targetWeight: 64.0,
        height: 172.0,
        age: 28,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goalType: GoalType.weightLoss,
        targetDate: targetDate,
      );
      final profile = UserProfile(
        id: 'u1',
        name: 'テスト太郎',
        height: 172.0,
        currentWeight: 68.0,
        targetWeight: 64.0,
        age: 28,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goalType: GoalType.weightLoss,
        targetDate: targetDate,
        goals: goals,
      );
      final weights = [
        WeightLog(id: 'w1', date: DateTime(2026, 10, 15), weight: 68.2),
        WeightLog(id: 'w2', date: DateTime(2026, 10, 16), weight: 68.0),
      ];
      final meals = [
        MealRecord(
          id: 'm1',
          date: DateTime(2026, 10, 16),
          type: MealType.breakfast,
          items: const [
            MealItem(
              id: 'i1',
              name: 'プロテイン',
              amount: 1.0,
              unit: '食',
              calories: 117.0,
              protein: 24.0,
              fat: 1.5,
              carbs: 2.0,
            ),
          ],
          createdAt: DateTime(2026, 10, 16, 8, 0),
        ),
      ];

      final jsonStr = StorageService.exportBackupJson(
        profile: profile,
        weightLogs: weights,
        meals: meals,
        recipes: const <Recipe>[],
        foodMasters: DefaultFoods.list.take(2).toList(),
      );

      final restored = StorageService.parseBackupJson(jsonStr);
      expect(restored.profile?.name, 'テスト太郎');
      expect(restored.weightLogs?.length, 2);
      expect(restored.meals?.first.items.first.name, 'プロテイン');
      expect(restored.foodMasters?.length, 2);
    });
  });
}
