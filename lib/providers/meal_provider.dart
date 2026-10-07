import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/bmr_calculator.dart';
import '../models/meal_record.dart';
import '../services/storage_service.dart';
import 'user_provider.dart';

class MealNotifier extends StateNotifier<List<MealRecord>> {
  MealNotifier({List<MealRecord>? initial}) : super(initial ?? _initialMeals);

  static List<MealRecord> get _initialMeals => const [];

  /// 指定した日付の食事レコード一覧を取得
  List<MealRecord> getMealsForDate(DateTime targetDate) {
    return state.where((m) =>
      m.date.year == targetDate.year &&
      m.date.month == targetDate.month &&
      m.date.day == targetDate.day
    ).toList();
  }

  /// 食事アイテムの追加
  void addMealItem({
    required DateTime date,
    required MealType type,
    required MealItem item,
  }) {
    addMealItems(date: date, type: type, items: [item]);
  }

  /// 複数食事アイテムの一括追加（自炊合算・マイレシピ展開用）
  void addMealItems({
    required DateTime date,
    required MealType type,
    required List<MealItem> items,
  }) {
    if (items.isEmpty) return;

    final existingIndex = state.indexWhere((m) =>
      m.date.year == date.year &&
      m.date.month == date.month &&
      m.date.day == date.day &&
      m.type == type
    );

    if (existingIndex >= 0) {
      final targetRecord = state[existingIndex];
      final updatedItems = [...targetRecord.items, ...items];
      final updatedRecord = targetRecord.copyWith(items: updatedItems);
      
      final newState = [...state];
      newState[existingIndex] = updatedRecord;
      state = newState;
    } else {
      final newRecord = MealRecord(
        id: 'meal-${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        type: type,
        items: items,
        createdAt: DateTime.now(),
      );
      state = [...state, newRecord];
    }
    StorageService.saveMeals(state);
  }

  /// アイテムの削除
  void removeMealItem(String recordId, String itemId) {
    final recordIndex = state.indexWhere((m) => m.id == recordId);
    if (recordIndex < 0) return;

    final targetRecord = state[recordIndex];
    final updatedItems = targetRecord.items.where((i) => i.id != itemId).toList();

    if (updatedItems.isEmpty) {
      state = state.where((m) => m.id != recordId).toList();
    } else {
      final updatedRecord = targetRecord.copyWith(items: updatedItems);
      final newState = [...state];
      newState[recordIndex] = updatedRecord;
      state = newState;
    }
    StorageService.saveMeals(state);
  }

  /// 複数アイテムの一括削除（レシピグループ削除用）
  void removeMealItems(String recordId, List<String> itemIds) {
    final recordIndex = state.indexWhere((m) => m.id == recordId);
    if (recordIndex < 0) return;

    final targetRecord = state[recordIndex];
    final updatedItems = targetRecord.items.where((i) => !itemIds.contains(i.id)).toList();

    if (updatedItems.isEmpty) {
      state = state.where((m) => m.id != recordId).toList();
    } else {
      final updatedRecord = targetRecord.copyWith(items: updatedItems);
      final newState = [...state];
      newState[recordIndex] = updatedRecord;
      state = newState;
    }
    StorageService.saveMeals(state);
  }

  /// 全食事データの消去
  void clearAll() {
    state = [];
    StorageService.saveMeals(state);
  }
}

final mealProvider = StateNotifierProvider<MealNotifier, List<MealRecord>>((ref) {
  return MealNotifier();
});

/// 選択中の日付プロバイダー（初期値: 今日）
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// 選択中日付の食事レコード一覧プロバイダー
final selectedDateMealsProvider = Provider.autoDispose<List<MealRecord>>((ref) {
  final meals = ref.watch(mealProvider);
  final targetDate = ref.watch(selectedDateProvider);

  return meals.where((m) =>
    m.date.year == targetDate.year &&
    m.date.month == targetDate.month &&
    m.date.day == targetDate.day
  ).toList();
});

/// 選択中日付の総摂取集計プロバイダー
final selectedDateTotalsProvider = Provider.autoDispose<Map<String, double>>((ref) {
  final targetMeals = ref.watch(selectedDateMealsProvider);

  double calories = 0.0;
  double protein = 0.0;
  double fat = 0.0;
  double carbs = 0.0;

  for (final meal in targetMeals) {
    calories += meal.totalCalories;
    protein += meal.totalProtein;
    fat += meal.totalFat;
    carbs += meal.totalCarbs;
  }

  return {
    'calories': calories,
    'protein': protein,
    'fat': fat,
    'carbs': carbs,
  };
});

/// 後方互換用: 本日の総摂取集計プロバイダー
final todayTotalsProvider = selectedDateTotalsProvider;

/// 選択中日付の朝食・昼食・夕食・間食のカテゴリ別カロリー集計プロバイダー
final selectedDateCategoryCaloriesProvider = Provider.autoDispose<Map<MealType, double>>((ref) {
  final targetMeals = ref.watch(selectedDateMealsProvider);

  final Map<MealType, double> categoryCalories = {
    MealType.breakfast: 0.0,
    MealType.lunch: 0.0,
    MealType.dinner: 0.0,
    MealType.snack: 0.0,
  };

  for (final meal in targetMeals) {
    categoryCalories[meal.type] =
        (categoryCalories[meal.type] ?? 0.0) + meal.totalCalories;
  }

  return categoryCalories;
});

/// 後方互換用: 本日のカテゴリ別カロリー集計プロバイダー
final todayCategoryCaloriesProvider = selectedDateCategoryCaloriesProvider;

/// カロリー収支レポートモデル（週・月集計用）
class CalorieBalanceReport {
  final int days; // 期間日数（週: 7, 月: 30）
  final int recordedDays; // 確定した入力日数（週: 4日, 月: 8日など）
  final double averageDailyCalories; // 確定した1日平均摂取カロリー
  final double projectedTotalCalories; // 期間予測総摂取カロリー (averageDailyCalories * days)
  final double targetCaloriesTotal; // 期間目標総カロリー
  final double tdeeTotal; // 期間総消費カロリー (TDEE)
  final double calorieSavings; // 予測貯金（目標 - 予測摂取）
  final double netBalance; // 予測純収支（予測摂取 - TDEE）
  final double fatChangeKg; // 換算体脂肪増減（netBalance / 7200）

  const CalorieBalanceReport({
    required this.days,
    required this.recordedDays,
    required this.averageDailyCalories,
    required this.projectedTotalCalories,
    required this.targetCaloriesTotal,
    required this.tdeeTotal,
    required this.calorieSavings,
    required this.netBalance,
    required this.fatChangeKg,
  });

  /// 互換用ゲッター
  double get totalCalories => projectedTotalCalories;

  /// チートデイ可能判定（目標に対して300kcal以上の貯金ペースがあるか）
  bool get canHaveCheatMeal => calorieSavings >= 300.0;
}

/// 指定した日数（7日/30日）の収支レポート計算ヘルパー
CalorieBalanceReport _calculateBalanceReport(Ref ref, int days, [DateTime? customToday]) {
  final meals = ref.watch(mealProvider);
  final user = ref.watch(userProvider);

  // 基準日（今日）: 指定がなければ食事データ中の最新日（今日）、または現在日
  final DateTime effectiveToday;
  if (customToday != null) {
    effectiveToday = customToday;
  } else if (meals.isNotEmpty) {
    final latestMealDate = meals.map((m) => m.date).reduce((a, b) => a.isAfter(b) ? a : b);
    effectiveToday = DateTime(latestMealDate.year, latestMealDate.month, latestMealDate.day);
  } else {
    final now = DateTime.now();
    effectiveToday = DateTime(now.year, now.month, now.day);
  }

  final today = DateTime(effectiveToday.year, effectiveToday.month, effectiveToday.day);
  final yesterday = today.subtract(const Duration(days: 1));

  // 1. 集計対象の確定過去日範囲の決定
  final DateTime startDate;
  final DateTime endDate = yesterday;

  if (days == 7) {
    // 週計: 今週の月曜日〜昨日まで
    // ※今日が月曜日の場合は直近7日間のうち昨日以前
    final daysSinceMonday = today.weekday - DateTime.monday;
    if (daysSinceMonday > 0) {
      startDate = today.subtract(Duration(days: daysSinceMonday));
    } else {
      startDate = today.subtract(const Duration(days: 7));
    }
  } else {
    // 月計: 当月の1日〜昨日まで
    // ※今日が1日の場合は前月1日〜昨日まで
    if (today.day > 1) {
      startDate = DateTime(today.year, today.month, 1);
    } else {
      final prevMonth = DateTime(today.year, today.month - 1, 1);
      startDate = prevMonth;
    }
  }

  // 2. 確定過去日（今日を除く）の食事レコードを日別に集計
  final Map<String, double> dailyCalories = {};
  for (final m in meals) {
    final mealDate = DateTime(m.date.year, m.date.month, m.date.day);
    // startDate <= mealDate <= endDate
    if (!mealDate.isBefore(startDate) && !mealDate.isAfter(endDate)) {
      final key = '${mealDate.year}-${mealDate.month.toString().padLeft(2, '0')}-${mealDate.day.toString().padLeft(2, '0')}';
      dailyCalories[key] = (dailyCalories[key] ?? 0.0) + m.totalCalories;
    }
  }

  final recordedDays = dailyCalories.length;
  final targetDaily = user.goals.targetCalories;

  final tdee = BmrCalculator.calculateTdee(
    weight: user.currentWeight,
    height: user.height,
    age: user.age,
    gender: user.gender,
    activityLevel: user.activityLevel,
  );

  // 3. 確定日数に基づく1日平均摂取カロリー
  final double averageDailyCalories;
  if (recordedDays > 0) {
    final pastTotalCalories = dailyCalories.values.fold(0.0, (a, b) => a + b);
    averageDailyCalories = pastTotalCalories / recordedDays;
  } else {
    // 過去の確定入力がまだない場合は目標値をフォールバック
    averageDailyCalories = targetDaily;
  }

  // 4. 着地予測の計算（この平均ペースを期間日数継続した場合）
  final projectedTotalCalories = averageDailyCalories * days;
  final targetCaloriesTotal = targetDaily * days;
  final tdeeTotal = tdee * days;
  final calorieSavings = targetCaloriesTotal - projectedTotalCalories;
  final netBalance = projectedTotalCalories - tdeeTotal;
  final fatChangeKg = netBalance / 7200.0;

  return CalorieBalanceReport(
    days: days,
    recordedDays: recordedDays,
    averageDailyCalories: averageDailyCalories,
    projectedTotalCalories: projectedTotalCalories,
    targetCaloriesTotal: targetCaloriesTotal,
    tdeeTotal: tdeeTotal,
    calorieSavings: calorieSavings,
    netBalance: netBalance,
    fatChangeKg: fatChangeKg,
  );
}

/// 直近7日間のローリング集計レポートモデル
class Rolling7DaysReport {
  final int recordedDays;
  final double averageDailyCalories;
  final double targetCalories;
  final double differenceFromTarget;
  final bool isWithinTarget;
  final List<double> dailyCaloriesList;

  const Rolling7DaysReport({
    required this.recordedDays,
    required this.averageDailyCalories,
    required this.targetCalories,
    required this.differenceFromTarget,
    required this.isWithinTarget,
    required this.dailyCaloriesList,
  });
}

/// 直近7日間（今日を含まない過去7日間: today-7 〜 yesterday）のローリング集計プロバイダー
final rolling7DaysReportProvider = Provider.autoDispose<Rolling7DaysReport>((ref) {
  final meals = ref.watch(mealProvider);
  final user = ref.watch(userProvider);

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final sevenDaysAgo = today.subtract(const Duration(days: 7));

  final Map<String, double> dailyMap = {};
  for (final m in meals) {
    final d = DateTime(m.date.year, m.date.month, m.date.day);
    if (!d.isBefore(sevenDaysAgo) && !d.isAfter(yesterday)) {
      final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0.0) + m.totalCalories;
    }
  }

  final recordedDays = dailyMap.length;
  final target = user.goals.targetCalories;

  final double avg;
  if (recordedDays > 0) {
    final total = dailyMap.values.fold(0.0, (a, b) => a + b);
    avg = total / recordedDays;
  } else {
    avg = target;
  }

  final diff = avg - target;
  final isWithin = diff.abs() <= 150.0;

  return Rolling7DaysReport(
    recordedDays: recordedDays,
    averageDailyCalories: avg,
    targetCalories: target,
    differenceFromTarget: diff,
    isWithinTarget: isWithin,
    dailyCaloriesList: dailyMap.values.toList(),
  );
});

/// 直近（週）のカロリー収支プロバイダー
final weekBalanceProvider = Provider.autoDispose<CalorieBalanceReport>((ref) {
  return _calculateBalanceReport(ref, 7);
});

/// 直近（月）のカロリー収支プロバイダー
final monthBalanceProvider = Provider.autoDispose<CalorieBalanceReport>((ref) {
  return _calculateBalanceReport(ref, 30);
});
