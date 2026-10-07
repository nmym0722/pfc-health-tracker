import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../core/utils/bmr_calculator.dart';
import '../services/storage_service.dart';

class UserNotifier extends StateNotifier<UserProfile> {
  UserNotifier({UserProfile? initial}) : super(initial ?? _initialProfile);

  static UserProfile get _initialProfile {
    const initialWeight = 72.0;
    const targetWeight = 65.0;
    final targetDate = DateTime.now().add(const Duration(days: 90));

    final goals = BmrCalculator.calculateAdaptiveGoals(
      currentWeight: initialWeight,
      targetWeight: targetWeight,
      height: 172.0,
      age: 28,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderate,
      goalType: GoalType.weightLoss,
      targetDate: targetDate,
    );

    return UserProfile(
      id: 'user-default',
      name: 'ユーザー',
      height: 172.0,
      currentWeight: initialWeight,
      targetWeight: targetWeight,
      age: 28,
      gender: Gender.male,
      activityLevel: ActivityLevel.moderate,
      goalType: GoalType.weightLoss,
      targetDate: targetDate,
      goals: goals,
    );
  }

  /// 【仕様要件F-4】新しい体重が記録された際の目標カロリー/PFC自動再計算フック
  /// [emaWeight] が渡された場合、水分ノイズを除去した平滑化体重を計算のベースとします。
  void recalculateGoalsWithNewWeight(
    double newWeight, {
    double? emaWeight,
    double? adaptedTdee,
  }) {
    final effectiveWeight = emaWeight ?? newWeight;
    final effectiveTdee = adaptedTdee ?? state.currentAdaptedTdee;

    final updatedGoals = BmrCalculator.calculateAdaptiveGoals(
      currentWeight: effectiveWeight,
      targetWeight: state.targetWeight,
      height: state.height,
      age: state.age,
      gender: state.gender,
      activityLevel: state.activityLevel,
      goalType: state.goalType,
      targetDate: state.targetDate,
      adaptedTdee: effectiveTdee,
    );

    state = state.copyWith(
      currentWeight: newWeight,
      goals: updatedGoals,
    );
    StorageService.saveUserProfile(state);
  }

  /// 動的適応アルゴリズムにより推計された実効TDEEを適用・履歴保存する
  void updateAdaptedTdee({
    required double newAdaptedTdee,
    required double slopePerDay,
    required String statusMessage,
    DateTime? date,
  }) {
    final entry = AdaptedTdeeHistoryEntry(
      date: date ?? DateTime.now(),
      adaptedTdee: newAdaptedTdee,
      weightTrendSlopePerDay: slopePerDay,
      statusMessage: statusMessage,
    );

    final updatedHistory = [...state.tdeeHistory, entry];

    // 新しい実効TDEEをもとに目標カロリー/PFCを再計算
    final updatedGoals = BmrCalculator.calculateAdaptiveGoals(
      currentWeight: state.currentWeight,
      targetWeight: state.targetWeight,
      height: state.height,
      age: state.age,
      gender: state.gender,
      activityLevel: state.activityLevel,
      goalType: state.goalType,
      targetDate: state.targetDate,
      adaptedTdee: newAdaptedTdee,
    );

    state = state.copyWith(
      currentAdaptedTdee: newAdaptedTdee,
      tdeeHistory: updatedHistory,
      goals: updatedGoals,
    );
    StorageService.saveUserProfile(state);
  }

  /// リフィード設定の更新
  void updateRefeedSettings(RefeedSettings settings) {
    state = state.copyWith(refeedSettings: settings);
    StorageService.saveUserProfile(state);
  }

  void updateProfile(UserProfile updated) {
    final effectiveTdee = updated.currentAdaptedTdee;
    final updatedGoals = BmrCalculator.calculateAdaptiveGoals(
      currentWeight: updated.currentWeight,
      targetWeight: updated.targetWeight,
      height: updated.height,
      age: updated.age,
      gender: updated.gender,
      activityLevel: updated.activityLevel,
      goalType: updated.goalType,
      targetDate: updated.targetDate,
      adaptedTdee: effectiveTdee,
    );

    state = updated.copyWith(goals: updatedGoals);
    StorageService.saveUserProfile(state);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile>((ref) {
  return UserNotifier();
});
