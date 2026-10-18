import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/bmr_calculator.dart';
import '../../../providers/adaptive_tdee_provider.dart';
import '../../../providers/meal_provider.dart';
import '../../../providers/user_provider.dart';

class CalorieBalanceCard extends ConsumerStatefulWidget {
  const CalorieBalanceCard({super.key});

  @override
  ConsumerState<CalorieBalanceCard> createState() => _CalorieBalanceCardState();
}

class _CalorieBalanceCardState extends ConsumerState<CalorieBalanceCard> {
  int _selectedDays = 7; // 7 または 30

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(userProvider);
    final adaptiveResult = ref.watch(adaptiveTdeeResultProvider);
    final guardrails = ref.watch(guardrailEvaluationProvider);
    final rollingReport = ref.watch(rolling7DaysReportProvider);
    final report = _selectedDays == 7
        ? ref.watch(weekBalanceProvider)
        : ref.watch(monthBalanceProvider);

    final effectiveAvgCalories = (_selectedDays == 7 && report.recordedDays < 2 && rollingReport.recordedDays >= 2)
        ? rollingReport.averageDailyCalories
        : report.averageDailyCalories;
    final effectiveCanCheat = (_selectedDays == 7 && report.recordedDays < 2 && rollingReport.recordedDays >= 2)
        ? (user.goals.targetCalories - rollingReport.averageDailyCalories >= 150.0)
        : report.canHaveCheatMeal;

    final progress = (report.totalCalories / (report.targetCaloriesTotal > 0 ? report.targetCaloriesTotal : 1))
        .clamp(0.0, 1.5);

    // ハリス・ベネディクト標準推計TDEE
    final standardTdee = BmrCalculator.calculateTdee(
      weight: user.currentWeight,
      height: user.height,
      age: user.age,
      gender: user.gender,
      activityLevel: user.activityLevel,
    );

    // 動的適応によるTDEE補正差分
    final effectiveTdee = user.currentAdaptedTdee ?? standardTdee;
    final tdeeDiff = effectiveTdee - standardTdee;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー & 期間セレクター (週7日 / 月30日)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_outlined, color: theme.colorScheme.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'カロリー収支 & 代謝適応',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 7, label: Text('週計')),
                    ButtonSegment<int>(value: 30, label: Text('月計')),
                  ],
                  selected: {_selectedDays},
                  onSelectionChanged: (val) {
                    setState(() {
                      _selectedDays = val.first;
                    });
                  },
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 1. 動的代謝適応インフォメーションバナー（適用ボタン付き）
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
              ),
              child: Row(
                children: [
                  Icon(
                    guardrails.isWarmupActive
                        ? Icons.timer_outlined
                        : (user.currentAdaptedTdee != null
                            ? Icons.auto_awesome
                            : Icons.insights_outlined),
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      guardrails.isWarmupActive
                          ? '代謝適応: 基礎データ収集中（あと数日記録すると自動推定が始まります）'
                          : user.currentAdaptedTdee != null
                              ? '代謝適応中: 実効消費 ${effectiveTdee.toInt()} kcal/日 (${tdeeDiff >= 0 ? '+' : ''}${tdeeDiff.toInt()} kcal 補正中)'
                              : adaptiveResult.isReliable
                                  ? '代謝適応の準備完了: 推定消費 ${adaptiveResult.adaptedTdee.toInt()} kcal/日'
                                  : '代謝適応: データ収集中（有効記録: ${adaptiveResult.completedIntakeDays}日分）',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  // 推定完了時の適用アクションボタン
                  if (adaptiveResult.isReliable && user.currentAdaptedTdee == null) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        ref.read(applyAdaptedTdeeProvider)();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('実効消費エネルギー（${adaptiveResult.adaptedTdee.toInt()} kcal/日）を目標に適用しました！')),
                        );
                      },
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('適用する'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // チートデイ判定バナー（条件達成時のみポップ表示）
            if (effectiveCanCheat) ...[
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'チートデイOK！ (直近平均: ${effectiveAvgCalories.round()} kcal)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '目標よりカロリーを抑えられています。今週はご褒美ミールを楽しめます！',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onPrimaryContainer.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 16),

            // プログレスバー
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedDays == 7 ? '週間' : '月間'}予測摂取 (確定${report.recordedDays}日ベース)',
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${report.projectedTotalCalories.round()} / ${report.targetCaloriesTotal.round()} kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: progress > 1.0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 詳細メトリクスグリッド (7日平均摂取 / 純収支 / 体脂肪換算)
            Builder(
              builder: (context) {
                final diff = rollingReport.averageDailyCalories - user.goals.targetCalories;
                final isWithinTarget = diff.abs() <= 150.0;
                final isUnder = diff < -150.0;

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: _buildMetricColumn(
                              theme,
                              title: '過去7日の平均摂取',
                              value: '${rollingReport.averageDailyCalories.round()} kcal',
                              subtitle: '目標比: ${diff >= 0 ? '+' : ''}${diff.round()} kcal',
                              valueColor: isWithinTarget
                                  ? theme.colorScheme.primary
                                  : isUnder
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.error,
                            ),
                          ),
                          Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
                          Expanded(
                            child: _buildMetricColumn(
                              theme,
                              title: '${_selectedDays == 7 ? '今週' : '月末'}の予測収支',
                              value: '${report.netBalance > 0 ? '+' : ''}${report.netBalance.round()} kcal',
                              subtitle: '対消費: ${report.tdeeTotal.round()} kcal',
                              valueColor: report.netBalance <= 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                          Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
                          Expanded(
                            child: _buildMetricColumn(
                              theme,
                              title: '${_selectedDays == 7 ? '今週' : '月末'}の体脂肪予測',
                              value: '${report.fatChangeKg > 0 ? '+' : ''}${report.fatChangeKg.toStringAsFixed(2)} kg',
                              subtitle: '(7,200kcal/kg換算)',
                              valueColor: report.fatChangeKg <= 0
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 1行ペースアドバイス
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          Icon(
                            isWithinTarget
                                ? Icons.check_circle_outline
                                : isUnder
                                    ? Icons.trending_down
                                    : Icons.trending_up,
                            color: isWithinTarget
                                ? theme.colorScheme.primary
                                : isUnder
                                    ? theme.colorScheme.secondary
                                    : theme.colorScheme.error,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rollingReport.recordedDays < 2
                                  ? '記録を続けることで、1日の過食に惑わされない7日間の平滑化トレンドを評価できます。'
                                  : isWithinTarget
                                      ? '順調です。7日間の平均摂取は目標ペース内に綺麗に収まっています。'
                                      : isUnder
                                          ? '目標より控えめなペースです。代謝低下を防ぐためしっかりエネルギーを補給しましょう。'
                                          : '7日平均が目標をやや上回っています。次の数食で脂質を少し調整すると安定します。',
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildMetricColumn(
    ThemeData theme, {
    required String title,
    required String value,
    required String subtitle,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Text(title, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
