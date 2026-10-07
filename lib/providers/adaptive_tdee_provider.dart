import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/algorithms/guardrails.dart';
import '../core/algorithms/tdee_adaptation.dart';
import '../core/utils/bmr_calculator.dart';
import 'meal_provider.dart';
import 'user_provider.dart';
import 'weight_provider.dart';

/// 過去14〜21日間の日次摂取ログを生成するプロバイダー
final dailyIntakeLogsProvider = Provider<List<DailyIntakeLog>>((ref) {
  final meals = ref.watch(mealProvider);
  if (meals.isEmpty) return const [];

  final Map<String, double> calorieMap = {};
  final Map<String, bool> completionMap = {};
  final Map<String, DateTime> dateMap = {};

  for (final meal in meals) {
    final d = DateTime(meal.date.year, meal.date.month, meal.date.day);
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    
    calorieMap[key] = (calorieMap[key] ?? 0.0) + meal.totalCalories;
    dateMap[key] = d;

    // レコード内に未完了フラグがあればその日は未完了と判定
    if (completionMap.containsKey(key)) {
      completionMap[key] = completionMap[key]! && meal.isDayCompleted;
    } else {
      completionMap[key] = meal.isDayCompleted;
    }
  }

  final now = DateTime.now();
  final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

  // 今日のデータはまだ日中であれば未完了として扱う（確定した過去日を主に対象）
  final logs = <DailyIntakeLog>[];
  for (final entry in calorieMap.entries) {
    final key = entry.key;
    final isToday = (key == todayKey);
    final isCompleted = isToday ? false : (completionMap[key] ?? true);

    logs.add(DailyIntakeLog(
      date: dateMap[key]!,
      caloriesConsumed: entry.value,
      isCompleted: isCompleted,
    ));
  }

  logs.sort((a, b) => a.date.compareTo(b.date));
  return logs;
});

/// 動的TDEE適応の計算結果を提供するプロバイダー
final adaptiveTdeeResultProvider = Provider<TdeeAdaptationResult>((ref) {
  final user = ref.watch(userProvider);
  final intakeLogs = ref.watch(dailyIntakeLogsProvider);
  final emaPoints = ref.watch(weightEmaSeriesProvider);

  // 現在の基準TDEE（適応済み値があれば優先、なければ推計TDEE）
  final currentTdee = user.currentAdaptedTdee ??
      BmrCalculator.calculateTdee(
        weight: user.currentWeight,
        height: user.height,
        age: user.age,
        gender: user.gender,
        activityLevel: user.activityLevel,
      );

  return TdeeAdaptationCalculator.calculateAdaptedTdee(
    currentTdee: currentTdee,
    intakeLogs: intakeLogs,
    emaPoints: emaPoints,
    windowDays: 14,
  );
});

/// ガードレール総合評価を提供するプロバイダー
final guardrailEvaluationProvider = Provider<GuardrailEvaluation>((ref) {
  final user = ref.watch(userProvider);
  final emaPoints = ref.watch(weightEmaSeriesProvider);
  final now = DateTime.now();

  // プログラム開始日（設定がなければ targetDateの90日前、または最初の体重測定日）
  final startDate = user.programStartDate ??
      (emaPoints.isNotEmpty
          ? emaPoints.first.date
          : now.subtract(const Duration(days: 90)));

  final bmr = BmrCalculator.calculateBmr(
    weight: user.currentWeight,
    height: user.height,
    age: user.age,
    gender: user.gender,
  );

  return SafetyGuardrails.evaluate(
    startDate: startDate,
    evaluationDate: now,
    rawCalculatedTargetCalories: user.goals.targetCalories,
    bmr: bmr,
    recentEmaPoints: emaPoints,
  );
});

/// 動的適応TDEEを確定反映するアクションプロバイダー
final applyAdaptedTdeeProvider = Provider<void Function()>((ref) {
  return () {
    final result = ref.read(adaptiveTdeeResultProvider);
    if (!result.isReliable) return;

    ref.read(userProvider.notifier).updateAdaptedTdee(
      newAdaptedTdee: result.adaptedTdee,
      slopePerDay: result.weightTrendSlopePerDay,
      statusMessage: result.statusMessage,
    );
  };
});
