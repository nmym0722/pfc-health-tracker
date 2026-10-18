import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/algorithms/weight_ema.dart';
import '../models/weight_log.dart';
import '../services/storage_service.dart';
import 'user_provider.dart';

class WeightNotifier extends StateNotifier<List<WeightLog>> {
  final Ref ref;

  WeightNotifier(this.ref, {List<WeightLog>? initial}) : super(initial ?? _initialLogs);

  static List<WeightLog> get _initialLogs => const [];

  /// 【仕様F-4要件】体重ログ追加時に動的目標カロリー/PFC再計算フックを実行
  void addWeightLog(
    double weight, {
    DateTime? date,
    double? bodyFat,
    bool isCheatDay = false,
    bool isExcludedFromAdaptation = false,
  }) {
    final entryDate = date ?? DateTime.now();
    final newLog = WeightLog(
      id: 'w-${entryDate.millisecondsSinceEpoch}',
      date: entryDate,
      weight: weight,
      bodyFat: bodyFat,
      isCheatDay: isCheatDay,
      isExcludedFromAdaptation: isExcludedFromAdaptation,
    );

    final updated = [...state, newLog];
    // 日付昇順（古い順）にソートしてグラフ等の順序を整える
    updated.sort((a, b) => a.date.compareTo(b.date));
    state = updated;

    _syncLatestWeightToGoals();
  }

  /// 既存の体重ログを編集・更新
  void updateWeightLog(
    String id, {
    required double weight,
    DateTime? date,
    double? bodyFat,
    bool? isCheatDay,
    bool? isExcludedFromAdaptation,
  }) {
    state = [
      for (final log in state)
        if (log.id == id)
          log.copyWith(
            weight: weight,
            date: date ?? log.date,
            bodyFat: bodyFat,
            isCheatDay: isCheatDay ?? log.isCheatDay,
            isExcludedFromAdaptation: isExcludedFromAdaptation ?? log.isExcludedFromAdaptation,
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
    
    // 自身のstateから直接EMAを算出して循環依存を回避
    final emaSeries = calculateEmaFromLogs(state);
    final latestEma = emaSeries.isNotEmpty ? emaSeries.last.emaWeight : latest.weight;

    ref.read(userProvider.notifier).recalculateGoalsWithNewWeight(
      latest.weight,
      emaWeight: latestEma,
    );
  }

  /// 全体重ログの消去
  void clearAll() {
    state = [];
    StorageService.saveWeightLogs(state);
  }

  /// バックアップからの一括復元
  void replaceAll(List<WeightLog> logs) {
    final sorted = [...logs]..sort((a, b) => a.date.compareTo(b.date));
    state = sorted;
    _syncLatestWeightToGoals();
  }
}

final weightProvider = StateNotifierProvider<WeightNotifier, List<WeightLog>>((ref) {
  return WeightNotifier(ref);
});

/// 生体重ログのリストから不等間隔7日EMA平滑化トレンド系列を算出する純粋ヘルパー関数
List<WeightEmaPoint> calculateEmaFromLogs(List<WeightLog> logs) {
  if (logs.isEmpty) return const [];

  // 日付昇順でソート
  final sortedLogs = List<WeightLog>.from(logs)
    ..sort((a, b) => a.date.compareTo(b.date));

  // チートデイ（外食）の翌日・翌々日判定を行って WeightPoint に変換
  final points = <WeightPoint>[];
  for (int i = 0; i < sortedLogs.length; i++) {
    final curr = sortedLogs[i];
    if (curr.isExcludedFromAdaptation) continue;

    // 過去2日以内にチートデイが存在するか判定
    bool isPostCheat = false;
    for (int j = 0; j < i; j++) {
      final prev = sortedLogs[j];
      if (prev.isCheatDay) {
        final diffDays = curr.date.difference(prev.date).inHours / 24.0;
        if (diffDays > 0.0 && diffDays <= 2.5) {
          isPostCheat = true;
          break;
        }
      }
    }

    points.add(WeightPoint(
      date: curr.date,
      weight: curr.weight,
      isPostCheatDay: isPostCheat,
    ));
  }

  return WeightEmaCalculator.calculateEmaSeries(points);
}

/// 生体重ログから不等間隔7日EMA平滑化トレンド系列を算出するプロバイダー
final weightEmaSeriesProvider = Provider<List<WeightEmaPoint>>((ref) {
  final logs = ref.watch(weightProvider);
  return calculateEmaFromLogs(logs);
});

/// 最新のEMA平滑化体重データ点を提供するプロバイダー
final latestWeightEmaProvider = Provider<WeightEmaPoint?>((ref) {
  final emaSeries = ref.watch(weightEmaSeriesProvider);
  if (emaSeries.isEmpty) return null;
  return emaSeries.last;
});
