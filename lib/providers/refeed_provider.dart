import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/algorithms/refeed_manager.dart';
import '../core/utils/bmr_calculator.dart';
import '../models/user_profile.dart';
import 'meal_provider.dart';
import 'user_provider.dart';
import 'weight_provider.dart';

/// 現時点（選択日または今日）における理想ペースの計画目標体重 (kg) を算出するプロバイダー
final plannedTargetWeightProvider = Provider<double>((ref) {
  final user = ref.watch(userProvider);
  final emaPoints = ref.watch(weightEmaSeriesProvider);
  final targetDate = user.targetDate;
  final now = ref.watch(selectedDateProvider);

  // 開始日と初期体重の特定
  final startDate = user.programStartDate ??
      (emaPoints.isNotEmpty ? emaPoints.first.date : targetDate.subtract(const Duration(days: 90)));
  
  // 初期体重（最初のEMAまたは現在体重）
  final initialWeight = emaPoints.isNotEmpty ? emaPoints.first.emaWeight : user.currentWeight;
  final targetWeight = user.targetWeight;

  final totalDurationDays = targetDate.difference(startDate).inDays;
  if (totalDurationDays <= 0) return targetWeight;

  final elapsedDays = now.difference(startDate).inDays.clamp(0, totalDurationDays);
  final progressRatio = elapsedDays / totalDurationDays;

  // 線形補間による計画線上の現在目標体重
  final plannedWeight = initialWeight + (targetWeight - initialWeight) * progressRatio;
  return double.parse(plannedWeight.toStringAsFixed(2));
});

/// リフィード（ハイカーボデイ）の判定・適格性を提供するプロバイダー
final refeedEvaluationProvider = Provider<RefeedDecision>((ref) {
  final user = ref.watch(userProvider);
  final latestEma = ref.watch(latestWeightEmaProvider);
  final plannedWeight = ref.watch(plannedTargetWeightProvider);
  final selectedDate = ref.watch(selectedDateProvider);

  final currentWeight = latestEma != null ? latestEma.emaWeight : user.currentWeight;

  // 現在の実効TDEE（適応済みTDEEまたは推計TDEE）
  final currentTdee = user.currentAdaptedTdee ??
      BmrCalculator.calculateTdee(
        weight: currentWeight,
        height: user.height,
        age: user.age,
        gender: user.gender,
        activityLevel: user.activityLevel,
      );

  // 設定された計画的リフィード曜日か
  final isScheduledDay = user.refeedSettings.isScheduledRefeedEnabled &&
      (selectedDate.weekday == user.refeedSettings.scheduledDayOfWeek);

  return RefeedManager.evaluateRefeed(
    currentEmaWeight: currentWeight,
    plannedTargetWeight: plannedWeight,
    baseTargetCalories: user.goals.targetCalories,
    currentTdee: currentTdee,
    baseProteinGrams: user.goals.targetProtein,
    baseFatGrams: user.goals.targetFat,
    baseCarbsGrams: user.goals.targetCarbs,
    isScheduledRefeedDay: isScheduledDay,
  );
});

/// 当日にリフィードを一時適用するかどうかの状態管理プロバイダー
final isRefeedAppliedTodayProvider = StateProvider<bool>((ref) => false);

/// リフィード適用を考慮した、本日有効な目標マクロ（UserGoals）を提供するプロバイダー
final effectiveDailyGoalsProvider = Provider<UserGoals>((ref) {
  final user = ref.watch(userProvider);
  final isApplied = ref.watch(isRefeedAppliedTodayProvider);
  final refeedDecision = ref.watch(refeedEvaluationProvider);

  // リフィードが適格かつユーザーが適用している場合
  if (isApplied && refeedDecision.isEligible) {
    return UserGoals(
      targetCalories: refeedDecision.totalCalories,
      targetProtein: refeedDecision.targetProteinGrams,
      targetFat: refeedDecision.targetFatGrams,
      targetCarbs: refeedDecision.targetCarbsGrams,
    );
  }

  return user.goals;
});
