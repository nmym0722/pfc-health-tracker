import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/weight_log.dart';
import '../services/storage_service.dart';
import 'user_provider.dart';

class WeightNotifier extends StateNotifier<List<WeightLog>> {
  final Ref ref;

  WeightNotifier(this.ref, {List<WeightLog>? initial}) : super(initial ?? _initialLogs);

  static List<WeightLog> get _initialLogs => const [];

  /// 【仕様F-4要件】体重ログ追加時に動的目標カロリー/PFC再計算フックを実行
  void addWeightLog(double weight, {DateTime? date, double? bodyFat}) {
    final entryDate = date ?? DateTime.now();
    final newLog = WeightLog(
      id: 'w-${entryDate.millisecondsSinceEpoch}',
      date: entryDate,
      weight: weight,
      bodyFat: bodyFat,
    );

    final updated = [...state, newLog];
    // 日付昇順（古い順）にソートしてグラフ等の順序を整える
    updated.sort((a, b) => a.date.compareTo(b.date));
    state = updated;

    _syncLatestWeightToGoals();
  }

  /// 既存の体重ログを編集・更新
  void updateWeightLog(String id, {required double weight, DateTime? date, double? bodyFat}) {
    state = [
      for (final log in state)
        if (log.id == id)
          log.copyWith(
            weight: weight,
            date: date ?? log.date,
            bodyFat: bodyFat,
          )
        else
          log,
    ]..sort((a, b) => a.date.compareTo(b.date));

    _syncLatestWeightToGoals();
  }

  /// 体重ログの削除
  void deleteWeightLog(String id) {
    state = state.where((l) => l.id != id).toList();
    _syncLatestWeightToGoals();
  }

  /// 最新の体重ログをユーザープロフィールの現在体重および動的目標に反映
  void _syncLatestWeightToGoals() {
    StorageService.saveWeightLogs(state);
    if (state.isEmpty) return;
    final latest = state.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
    ref.read(userProvider.notifier).recalculateGoalsWithNewWeight(latest.weight);
  }

  /// 全体重ログの消去
  void clearAll() {
    state = [];
    StorageService.saveWeightLogs(state);
  }
}

final weightProvider = StateNotifierProvider<WeightNotifier, List<WeightLog>>((ref) {
  return WeightNotifier(ref);
});
