import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfc_health_tracker/models/food_master.dart';
import 'package:pfc_health_tracker/models/meal_record.dart';
import 'package:pfc_health_tracker/models/user_profile.dart';
import 'package:pfc_health_tracker/models/weight_log.dart';
import 'package:pfc_health_tracker/services/storage_service.dart';

void main() {
  group('StorageService Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('WeightLogs の保存と復元が正しく動作すること', () async {
      final logs = [
        WeightLog(
          id: 'w-test-1',
          date: DateTime(2026, 10, 8),
          weight: 71.5,
          bodyFat: 17.8,
        ),
      ];

      await StorageService.saveWeightLogs(logs);
      final loaded = await StorageService.loadWeightLogs();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(1));
      expect(loaded.first.id, equals('w-test-1'));
      expect(loaded.first.weight, equals(71.5));
      expect(loaded.first.bodyFat, equals(17.8));
    });

    test('MealRecords の保存と復元が正しく動作すること', () async {
      final meals = [
        MealRecord(
          id: 'm-test-1',
          date: DateTime(2026, 10, 9),
          type: MealType.breakfast,
          items: const [
            MealItem(
              id: 'item-t1',
              name: 'プロテインシェイク',
              amount: 1,
              unit: '杯',
              calories: 120,
              protein: 24,
              fat: 1.5,
              carbs: 3,
            ),
          ],
          createdAt: DateTime(2026, 10, 9),
        ),
      ];

      await StorageService.saveMeals(meals);
      final loaded = await StorageService.loadMeals();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(1));
      expect(loaded.first.items.length, equals(1));
      expect(loaded.first.items.first.name, equals('プロテインシェイク'));
      expect(loaded.first.totalCalories, equals(120));
    });

    test('UserProfile の保存と復元が正しく動作すること', () async {
      final profile = UserProfile(
        id: 'u-1',
        name: 'テストユーザー',
        height: 175.0,
        currentWeight: 70.0,
        targetWeight: 65.0,
        age: 30,
        gender: Gender.male,
        activityLevel: ActivityLevel.moderate,
        goalType: GoalType.weightLoss,
        targetDate: DateTime(2026, 12, 31),
        goals: const UserGoals(
          targetCalories: 2000,
          targetProtein: 140,
          targetFat: 45,
          targetCarbs: 260,
        ),
      );

      await StorageService.saveUserProfile(profile);
      final loaded = await StorageService.loadUserProfile();

      expect(loaded, isNotNull);
      expect(loaded!.name, equals('テストユーザー'));
      expect(loaded.height, equals(175.0));
      expect(loaded.goals.targetCalories, equals(2000));
    });

    test('FoodMaster の保存と復元（カスタム食材・栄養価調整）が正しく動作すること', () async {
      final foods = [
        const FoodMaster(
          id: 'custom-food-test',
          name: '自家製プロテインオートミール',
          baseAmount: 100,
          unit: FoodUnit.g,
          calories: 380,
          protein: 30,
          fat: 6,
          carbs: 52,
          category: '主食・穀物',
          isCustom: true,
        ),
      ];

      await StorageService.saveFoodMasters(foods);
      final loaded = await StorageService.loadFoodMasters();

      expect(loaded, isNotNull);
      expect(loaded!.length, equals(1));
      expect(loaded.first.id, equals('custom-food-test'));
      expect(loaded.first.name, equals('自家製プロテインオートミール'));
      expect(loaded.first.calories, equals(380));
      expect(loaded.first.protein, equals(30));
      expect(loaded.first.fat, equals(6));
      expect(loaded.first.carbs, equals(52));
      expect(loaded.first.isCustom, isTrue);
    });
  });
}
