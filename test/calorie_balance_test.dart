import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfc_health_tracker/models/meal_record.dart';
import 'package:pfc_health_tracker/providers/meal_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Calorie Balance and Cheat Day Logic Tests', () {
    test('10/9時点（10/1〜10/8確定データ）での週計・月計の収支が正確に計算されること', () {
      final testMeals = <MealRecord>[
        for (final item in [
          {'day': 1, 'cal': 2100.0},
          {'day': 2, 'cal': 1950.0},
          {'day': 3, 'cal': 2200.0},
          {'day': 4, 'cal': 2050.0},
          {'day': 5, 'cal': 1900.0},
          {'day': 6, 'cal': 2000.0},
          {'day': 7, 'cal': 2100.0},
          {'day': 8, 'cal': 1950.0},
        ])
          MealRecord(
            id: 'm-${item['day']}',
            date: DateTime(2026, 10, item['day'] as int),
            type: MealType.lunch,
            items: [
              MealItem(
                id: 'i-${item['day']}',
                name: 'テスト食',
                amount: 1,
                unit: '食',
                calories: item['cal'] as double,
                protein: 30,
                fat: 10,
                carbs: 40,
              ),
            ],
            createdAt: DateTime(2026, 10, item['day'] as int),
          ),
        // 10/9 今日の途中データ
        MealRecord(
          id: 'm-today',
          date: DateTime(2026, 10, 9),
          type: MealType.breakfast,
          items: const [
            MealItem(
              id: 'i-today',
              name: '朝食',
              amount: 1,
              unit: '食',
              calories: 947,
              protein: 30,
              fat: 10,
              carbs: 40,
            ),
          ],
          createdAt: DateTime(2026, 10, 9),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          mealProvider.overrideWith((ref) => MealNotifier(initial: testMeals)),
        ],
      );
      addTearDown(container.dispose);

      final weekReport = container.read(weekBalanceProvider);
      final monthReport = container.read(monthBalanceProvider);

      // --- 週計の検証（10/5月曜〜10/8木曜の4日間） ---
      expect(weekReport.days, equals(7));
      expect(weekReport.recordedDays, equals(4)); // 4日間確定
      expect(weekReport.averageDailyCalories, closeTo(1987.5, 0.1)); // 7950 / 4 = 1987.5 kcal/日
      expect(weekReport.projectedTotalCalories, closeTo(13912.5, 0.1)); // 1987.5 * 7 = 13,912.5 kcal
      expect(weekReport.netBalance, lessThan(-4000.0));
      expect(weekReport.fatChangeKg, closeTo(-0.66, 0.05));
      expect(weekReport.canHaveCheatMeal, isTrue);

      // --- 月計の検証（10/1木曜〜10/8木曜の8日間） ---
      expect(monthReport.days, equals(30));
      expect(monthReport.recordedDays, equals(8)); // 8日間確定
      expect(monthReport.averageDailyCalories, closeTo(2031.25, 0.1)); // 16250 / 8 = 2031.25 kcal/日
      expect(monthReport.projectedTotalCalories, closeTo(60937.5, 0.1)); // 2031.25 * 30 = 60,937.5 kcal
      expect(monthReport.fatChangeKg, closeTo(-2.64, 0.05));
      expect(monthReport.canHaveCheatMeal, isTrue);
    });

    test('データ0件時の安全なレポート生成', () {
      final container = ProviderContainer(
        overrides: [
          mealProvider.overrideWith((ref) => MealNotifier(initial: [])),
        ],
      );
      addTearDown(container.dispose);

      final weekReport = container.read(weekBalanceProvider);
      expect(weekReport.recordedDays, equals(0));
      expect(weekReport.canHaveCheatMeal, isFalse);
    });

    test('チートデイ判定フラグの動作検証', () {
      const cheatOk = CalorieBalanceReport(
        days: 7,
        recordedDays: 4,
        averageDailyCalories: 1900,
        projectedTotalCalories: 13300,
        targetCaloriesTotal: 14700,
        tdeeTotal: 18600,
        calorieSavings: 1400, // +1400 kcal 貯金
        netBalance: -5300,
        fatChangeKg: -5300 / 7200,
      );
      expect(cheatOk.canHaveCheatMeal, isTrue);

      const cheatNg = CalorieBalanceReport(
        days: 7,
        recordedDays: 4,
        averageDailyCalories: 2300,
        projectedTotalCalories: 16100,
        targetCaloriesTotal: 14700,
        tdeeTotal: 18600,
        calorieSavings: -1400, // 超過
        netBalance: -2500,
        fatChangeKg: -2500 / 7200,
      );
      expect(cheatNg.canHaveCheatMeal, isFalse);
    });
  });
}
