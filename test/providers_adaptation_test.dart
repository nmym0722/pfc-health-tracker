import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pfc_health_tracker/models/meal_record.dart';
import 'package:pfc_health_tracker/providers/adaptive_tdee_provider.dart';
import 'package:pfc_health_tracker/providers/meal_provider.dart';
import 'package:pfc_health_tracker/providers/refeed_provider.dart';
import 'package:pfc_health_tracker/providers/user_provider.dart';
import 'package:pfc_health_tracker/providers/weight_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Provider層 適応TDEE & リフィード統合テスト (STEP 2)', () {
    test('生体重ログから7日EMAトレンドが自動計算され、最新EMAが提供されること', () {
      final container = ProviderContainer();
      final weightNotifier = container.read(weightProvider.notifier);

      final now = DateTime(2026, 10, 1);
      weightNotifier.addWeightLog(75.0, date: now);
      weightNotifier.addWeightLog(75.5, date: now.add(const Duration(days: 1)), isCheatDay: true);
      // チート翌日の急増（+1.5kg水分）
      weightNotifier.addWeightLog(77.0, date: now.add(const Duration(days: 2)));

      final emaSeries = container.read(weightEmaSeriesProvider);
      final latestEma = container.read(latestWeightEmaProvider);

      expect(emaSeries.length, 3);
      expect(latestEma, isNotNull);
      // チート翌日の急増（77.0kg）に対して重み減衰が利き、EMAは77kgまで急騰しない
      expect(latestEma!.rawWeight, 77.0);
      expect(latestEma.emaWeight, lessThan(76.0));
    });

    test('食事記録とEMA体重系列から動的適応TDEEが推計されること', () {
      final container = ProviderContainer();
      final weightNotifier = container.read(weightProvider.notifier);
      final mealNotifier = container.read(mealProvider.notifier);

      final startDate = DateTime(2026, 10, 1);

      // 14日間の体重（減量進行）と食事ログを注入
      for (int i = 0; i < 14; i++) {
        final d = startDate.add(Duration(days: i));
        // 体重が14日で1.4kg減少 (0.1kg/日ペース)
        weightNotifier.addWeightLog(75.0 - (i * 0.1), date: d);

        // 毎日1,800kcal摂取
        mealNotifier.addMealItem(
          date: d,
          type: MealType.lunch,
          item: const MealItem(
            id: 'item-1',
            name: '定食',
            amount: 1,
            unit: '人前',
            calories: 1800.0,
            protein: 100.0,
            fat: 50.0,
            carbs: 235.0,
          ),
        );
      }

      final intakeLogs = container.read(dailyIntakeLogsProvider);
      expect(intakeLogs.length, 14);

      final result = container.read(adaptiveTdeeResultProvider);
      expect(result.isReliable, isTrue);
      // 減少ペースに応じて適応TDEEが算出される
      expect(result.adaptedTdee, greaterThan(1800.0));
      expect(result.completedIntakeDays, greaterThanOrEqualTo(7));

      // applyAdaptedTdeeAction の実行で userProfile に反映されること
      container.read(applyAdaptedTdeeProvider)();
      final user = container.read(userProvider);
      expect(user.currentAdaptedTdee, equals(result.adaptedTdee));
      expect(user.tdeeHistory.length, 1);
      expect(user.tdeeHistory.first.adaptedTdee, equals(result.adaptedTdee));
    });

    test('減量ペースが目標より先行している場合、リフィードボーナスが算出され適用できること', () {
      final container = ProviderContainer();
      final weightNotifier = container.read(weightProvider.notifier);

      final now = DateTime(2026, 10, 7);
      container.read(selectedDateProvider.notifier).state = now;

      // ユーザー設定: 75kgから65kgを目指す（90日計画）
      container.read(userProvider.notifier).updateProfile(
            container.read(userProvider).copyWith(
                  currentWeight: 75.0,
                  targetWeight: 65.0,
                  programStartDate: DateTime(2026, 10, 1),
                  targetDate: DateTime(2026, 12, 30),
                ),
          );

      // 計画線上（開始6日後）では約74.3kgが目標。実測72.5kg（EMA約73.6kgとなり約0.7kg以上の明確な先行クリア）
      weightNotifier.addWeightLog(75.0, date: DateTime(2026, 10, 1));
      weightNotifier.addWeightLog(72.5, date: now);

      final refeedDecision = container.read(refeedEvaluationProvider);
      expect(refeedDecision.isEligible, isTrue);
      expect(refeedDecision.extraCalories, greaterThan(0));
      expect(refeedDecision.extraCarbsGrams, greaterThan(0));

      // リフィード適用トグルをONにする
      container.read(isRefeedAppliedTodayProvider.notifier).state = true;
      final effectiveGoals = container.read(effectiveDailyGoalsProvider);

      expect(effectiveGoals.targetCalories, equals(refeedDecision.totalCalories));
      expect(effectiveGoals.targetCarbs, equals(refeedDecision.targetCarbsGrams));
    });
  });
}
