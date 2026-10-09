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

    // 週初めでカレンダー週の確定日数が1日以下の場合、直近7日ローリングの平均で補正
    final effectiveRecordedDays = (_selectedDays == 7 && report.recordedDays < 2 && rollingReport.recordedDays >= 2)
        ? rollingReport.recordedDays
        : report.recordedDays;
    final effectiveAvgCalories = (_selectedDays == 7 && report.recordedDays < 2 && rollingReport.recordedDays >= 2)
        ? rollingReport.averageDailyCalories
        : report.averageDailyCalories;
    final effectiveCanCheat = (_selectedDays == 7 && report.recordedDays < 2 && rollingReport.recordedDays >= 2)
        ? (user.goals.targetCalories - rollingReport.averageDailyCalories >= 150.0)
        : report.canHaveCheatMeal;

    final absSavings = report.calorieSavings.abs().round();
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
                          ? '代謝適応: 初期ウォームアップ期間中（水分急変を考慮してマスク中）'
                          : user.currentAdaptedTdee != null
                              ? '動的適応中: 実効TDEE ${effectiveTdee.toInt()} kcal/日 (${tdeeDiff >= 0 ? '+' : ''}${tdeeDiff.toInt()} kcal/日 補正)'
                              : adaptiveResult.isReliable
                                  ? '代謝適応の準備完了: 推定実効TDEE ${adaptiveResult.adaptedTdee.toInt()} kcal/日'
                                  : '代謝適応: データ蓄積中（有効記録日数: ${adaptiveResult.completedIntakeDays}日）',
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
                          SnackBar(content: Text('実効TDEE（${adaptiveResult.adaptedTdee.toInt()} kcal/日）を目標に適用しました！')),
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

            // チートデイ判定 / ペース診断バナー
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: effectiveRecordedDays == 0
                    ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.6)
                    : effectiveRecordedDays == 1
                        ? theme.colorScheme.surfaceContainerHighest
                        : effectiveCanCheat
                            ? theme.colorScheme.primaryContainer
                            : report.calorieSavings < 0
                                ? theme.colorScheme.errorContainer.withOpacity(0.6)
                                : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    effectiveRecordedDays == 0
                        ? Icons.info_outline
                        : effectiveRecordedDays == 1
                            ? Icons.hourglass_top_outlined
                            : effectiveCanCheat
                                ? Icons.stars
                                : report.calorieSavings < 0
                                    ? Icons.warning_amber_rounded
                                    : Icons.info_outline,
                    color: effectiveRecordedDays == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : effectiveRecordedDays == 1
                            ? theme.colorScheme.primary
                            : effectiveCanCheat
                                ? theme.colorScheme.onPrimaryContainer
                                : report.calorieSavings < 0
                                    ? theme.colorScheme.onErrorContainer
                                    : theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          effectiveRecordedDays == 0
                              ? '食事記録を入力するとペース分析が始まります'
                              : effectiveRecordedDays == 1
                                  ? 'データ蓄積中 (確定1日分: 平均 ${effectiveAvgCalories.round()} kcal)'
                                  : effectiveCanCheat
                                      ? 'チートデイOK！ (直近平均: ${effectiveAvgCalories.round()} kcal)'
                                      : report.calorieSavings < 0
                                          ? '目標カロリー超過中 ($absSavings kcal オーバー)'
                                          : '目標通り推移中 (直近平均: ${effectiveAvgCalories.round()} kcal)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: effectiveRecordedDays == 0
                                ? theme.colorScheme.onSurface
                                : effectiveRecordedDays == 1
                                    ? theme.colorScheme.onSurface
                                    : effectiveCanCheat
                                        ? theme.colorScheme.onPrimaryContainer
                                        : report.calorieSavings < 0
                                            ? theme.colorScheme.onErrorContainer
                                            : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          effectiveRecordedDays == 0
                              ? '日々の食事を記録していくと、ここに着地予測やチートデイ診断が表示されます。'
                              : effectiveRecordedDays == 1
                                  ? '2日以上記録すると、週全体の着地予測とチートデイ診断が精度高く算出されます。'
                                  : effectiveCanCheat
                                      ? '目標よりカロリーを抑えられています。今週末にご褒美ミールを楽しめます！'
                                      : report.calorieSavings < 0
                                          ? '少しずつプラスになっています。数日間の食事を意識して調整しましょう。'
                                          : '順調なペースです。チートデイを設けるにはあと少し貯金を作ると安心です。',
                          style: TextStyle(
                            fontSize: 11,
                            color: effectiveRecordedDays == 0
                                ? theme.colorScheme.onSurfaceVariant
                                : effectiveRecordedDays == 1
                                    ? theme.colorScheme.onSurfaceVariant
                                    : effectiveCanCheat
                                        ? theme.colorScheme.onPrimaryContainer.withOpacity(0.85)
                                        : report.calorieSavings < 0
                                            ? theme.colorScheme.onErrorContainer.withOpacity(0.85)
                                            : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

            // 詳細メトリクスグリッド (1日平均 / 純収支 / 体脂肪換算)
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
                      title: '1日平均摂取',
                      value: '${report.averageDailyCalories.round()} kcal',
                      subtitle: '確定${report.recordedDays}日 / 目標${(report.targetCaloriesTotal / report.days).round()}',
                    ),
                  ),
                  Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
                  Expanded(
                    child: _buildMetricColumn(
                      theme,
                      title: '${_selectedDays == 7 ? '今週' : '月末'}予測純収支',
                      value: '${report.netBalance > 0 ? '+' : ''}${report.netBalance.round()} kcal',
                      subtitle: '対消費: ${report.tdeeTotal.round()}',
                      valueColor: report.netBalance <= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
                  Expanded(
                    child: _buildMetricColumn(
                      theme,
                      title: '${_selectedDays == 7 ? '今週' : '月末'}体脂肪予測',
                      value: '${report.fatChangeKg > 0 ? '+' : ''}${report.fatChangeKg.toStringAsFixed(2)} kg',
                      subtitle: '7,200kcal/kg',
                      valueColor: report.fatChangeKg <= 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ローリング7日間平均カロリー サマリーカード
            _buildRolling7DaySummary(
              theme,
              user.goals.targetCalories,
              rollingReport.averageDailyCalories,
              rollingReport.recordedDays,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRolling7DaySummary(
    ThemeData theme,
    double targetCalories,
    double rollingAverage,
    int recordedDays,
  ) {
    final diff = rollingAverage - targetCalories;
    final isWithinTarget = diff.abs() <= 150.0;
    final isUnder = diff < -150.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWithinTarget
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : isUnder
                ? theme.colorScheme.secondaryContainer.withOpacity(0.3)
                : theme.colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isWithinTarget
              ? theme.colorScheme.primary.withOpacity(0.3)
              : isUnder
                  ? theme.colorScheme.secondary.withOpacity(0.3)
                  : theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 4,
                  runSpacing: 2,
                  children: [
                    Text(
                      '直近7日ローリング平均: ${rollingAverage.round()} kcal/日',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    Text(
                      '目標比: ${diff >= 0 ? '+' : ''}${diff.round()} kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: isWithinTarget
                            ? theme.colorScheme.primary
                            : isUnder
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  recordedDays < 2
                      ? '記録を蓄積することで、1日の過食に惑わされない7日間の平滑化平均を評価できます。'
                      : isWithinTarget
                          ? '1日の食べ過ぎで焦る必要はありません。7日平均は目標ペース内に綺麗に収まっています。'
                          : isUnder
                              ? '目標より控えめなペースです。代謝低下を防ぐため、十分なエネルギー摂取を意識しましょう。'
                              : '7日平均が目標をやや上回っています。次の数食で脂質を少し調整すると安定します。',
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
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
