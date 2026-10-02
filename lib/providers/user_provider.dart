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
  void recalculateGoalsWithNewWeight(double newWeight) {
    final updatedGoals = BmrCalculator.calculateAdaptiveGoals(
      currentWeight: newWeight,
      targetWeight: state.targetWeight,
      height: state.height,
      age: state.age,
      gender: state.gender,
      activityLevel: state.activityLevel,
      goalType: state.goalType,
      targetDate: state.targetDate,
    );

    state = state.copyWith(
      currentWeight: newWeight,
      goals: updatedGoals,
    );
    StorageService.saveUserProfile(state);
  }

  void updateProfile(UserProfile updated) {
    final updatedGoals = BmrCalculator.calculateAdaptiveGoals(
      currentWeight: updated.currentWeight,
      targetWeight: updated.targetWeight,
      height: updated.height,
      age: updated.age,
      gender: updated.gender,
      activityLevel: updated.activityLevel,
      goalType: updated.goalType,
      targetDate: updated.targetDate,
    );

    state = updated.copyWith(goals: updatedGoals);
    StorageService.saveUserProfile(state);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserProfile>((ref) {
  return UserNotifier();
});
