import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/meal_record.dart';
import '../../models/user_profile.dart';
import '../../models/weight_log.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/weight_provider.dart';
import '../../services/storage_service.dart';

class DemoDataGenerator {
  /// 過去14日分のリアルな検証用デモデータを一括生成・投入する
  static Future<void> loadDemoData(WidgetRef ref) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 14));
    final targetDate = today.add(const Duration(days: 76)); // 全90日プログラム

    // 1. プロフィールの設定
    final currentProfile = ref.read(userProvider);
    final updatedProfile = currentProfile.copyWith(
      name: 'テストユーザー',
      currentWeight: 73.8,
      targetWeight: 68.0,
      programStartDate: startDate,
      targetDate: targetDate,
      refeedSettings: const RefeedSettings(
        isScheduledRefeedEnabled: true,
        scheduledDayOfWeek: DateTime.sunday,
        isBonusRefeedEnabled: true,
      ),
    );

    // 2. 14日間の体重推移（チートデイ + 翌日水分急増を含む）
    // 76.0kg -> 73.8kg、7日前にチートデイ、6日前に水分+1.2kg
    final weights = <WeightLog>[];
    final baseWeights = [
      76.0, 75.8, 75.6, 75.5, 75.2, 75.0, 74.8, // 14日前〜8日前
      74.7, // 7日前（チートデイ: 外食）
      75.9, // 6日前（翌日: 水分貯留で急増！）
      75.1, // 5日前（水分が抜け始める）
      74.5, 74.2, 74.0, 73.8, // 4日前〜今日
    ];

    for (int i = 0; i < baseWeights.length; i++) {
      final logDate = startDate.add(Duration(days: i));
      final isCheat = (i == 7); // 7日前がチートデイ
      weights.add(WeightLog(
        id: 'demo-w-$i',
        date: logDate,
        weight: baseWeights[i],
        bodyFat: 18.5 - (i * 0.1),
        isCheatDay: isCheat,
      ));
    }

    // 3. 14日間の食事ログ
    final meals = <MealRecord>[];
    for (int i = 0; i < 14; i++) {
      final mealDate = startDate.add(Duration(days: i));
      final isCheat = (i == 7);

      if (isCheat) {
        // チートデイ（外食）: 2,800kcal
        meals.add(MealRecord(
          id: 'demo-m-$i-1',
          date: mealDate,
          type: MealType.breakfast,
          items: const [
            MealItem(id: 'i1', name: '全卵トースト', amount: 1, unit: '食', calories: 450, protein: 20, fat: 15, carbs: 55),
          ],
          createdAt: mealDate,
        ));
        meals.add(MealRecord(
          id: 'demo-m-$i-2',
          date: mealDate,
          type: MealType.dinner,
          items: const [
            MealItem(id: 'i2', name: '焼肉・ハイボール・白米大盛り（外食）', amount: 1, unit: '人前', calories: 2350, protein: 95, fat: 110, carbs: 240),
          ],
          createdAt: mealDate,
        ));
      } else {
        // 通常日: 約1,800kcal（朝450 / 昼750 / 夕600）
        meals.add(MealRecord(
          id: 'demo-m-$i-1',
          date: mealDate,
          type: MealType.breakfast,
          items: const [
            MealItem(id: 'i1', name: 'オートミール & プロテイン', amount: 1, unit: '食', calories: 420, protein: 35, fat: 8, carbs: 50),
          ],
          createdAt: mealDate,
        ));
        meals.add(MealRecord(
          id: 'demo-m-$i-2',
          date: mealDate,
          type: MealType.lunch,
          items: const [
            MealItem(id: 'i2', name: '鶏むね肉と玄米定食', amount: 1, unit: '食', calories: 760, protein: 55, fat: 16, carbs: 95),
          ],
          createdAt: mealDate,
        ));
        meals.add(MealRecord(
          id: 'demo-m-$i-3',
          date: mealDate,
          type: MealType.dinner,
          items: const [
            MealItem(id: 'i3', name: '鮭の塩焼き & 具だくさん味噌汁', amount: 1, unit: '食', calories: 610, protein: 42, fat: 18, carbs: 65),
          ],
          createdAt: mealDate,
        ));
      }
    }

    // 永続化ストレージへ保存
    await StorageService.saveUserProfile(updatedProfile);
    await StorageService.saveWeightLogs(weights);
    await StorageService.saveMeals(meals);

    // Riverpod ProviderのStateを更新
    ref.read(userProvider.notifier).updateProfile(updatedProfile);
    final weightNotifier = ref.read(weightProvider.notifier);
    weightNotifier.clearAll();
    for (final w in weights) {
      weightNotifier.addWeightLog(
        w.weight,
        date: w.date,
        bodyFat: w.bodyFat,
        isCheatDay: w.isCheatDay,
      );
    }

    final mealNotifier = ref.read(mealProvider.notifier);
    mealNotifier.clearAll();
    for (final m in meals) {
      mealNotifier.addMealItems(date: m.date, type: m.type, items: m.items);
    }
  }
}
