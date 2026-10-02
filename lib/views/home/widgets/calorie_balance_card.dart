import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/meal_provider.dart';

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
    final report = _selectedDays == 7
        ? ref.watch(weekBalanceProvider)
        : ref.watch(monthBalanceProvider);

    final absSavings = report.calorieSavings.abs().round();
    final progress = (report.totalCalories / (report.targetCaloriesTotal > 0 ? report.targetCaloriesTotal : 1))
        .clamp(0.0, 1.5);

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
                      'カロリー収支 & ペース分析',
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
            const SizedBox(height: 14),

            // チートデイ判定 / ペース診断バナー
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: report.recordedDays == 0
                    ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.6)
                    : report.canHaveCheatMeal
                        ? theme.colorScheme.primaryContainer
                        : report.calorieSavings < 0
                            ? theme.colorScheme.errorContainer.withOpacity(0.6)
                            : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    report.recordedDays == 0
                        ? Icons.info_outline
                        : report.canHaveCheatMeal
                            ? Icons.stars
                            : report.calorieSavings < 0
                                ? Icons.warning_amber_rounded
                                : Icons.info_outline,
                    color: report.recordedDays == 0
                        ? theme.colorScheme.onSurfaceVariant
                        : report.canHaveCheatMeal
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
                          report.recordedDays == 0
                              ? '食事記録を入力するとペース分析が始まります'
                              : report.canHaveCheatMeal
                                  ? 'チートデイOK！ (貯金: +$absSavings kcal)'
                                  : report.calorieSavings < 0
                                      ? '目標カロリー超過中 ($absSavings kcal オーバー)'
                                      : '目標通り推移中 (貯金: +$absSavings kcal)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: report.recordedDays == 0
                                ? theme.colorScheme.onSurface
                                : report.canHaveCheatMeal
                                    ? theme.colorScheme.onPrimaryContainer
                                    : report.calorieSavings < 0
                                        ? theme.colorScheme.onErrorContainer
                                        : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.recordedDays == 0
                              ? '日々の食事を記録していくと、ここに着地予測やチートデイ診断が表示されます。'
                              : report.canHaveCheatMeal
                                  ? '目標よりカロリーを抑えられています。今週末にご褒美ミールを楽しめます！'
                                  : report.calorieSavings < 0
                                      ? '少しずつプラスになっています。数日間の食事を意識して調整しましょう。'
                                      : '順調なペースです。チートデイを設けるにはあと少し貯金を作ると安心です。',
                          style: TextStyle(
                            fontSize: 11,
                            color: report.recordedDays == 0
                                ? theme.colorScheme.onSurfaceVariant
                                : report.canHaveCheatMeal
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
                    Text(
                      '${_selectedDays == 7 ? '週間' : '月間'}予測摂取 (確定${report.recordedDays}日ベース)',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${report.projectedTotalCalories.round()} / ${report.targetCaloriesTotal.round()} kcal',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
                  _buildMetricColumn(
                    theme,
                    title: '1日平均摂取',
                    value: '${report.averageDailyCalories.round()} kcal',
                    subtitle: '確定${report.recordedDays}日 / 目標${(report.targetCaloriesTotal / report.days).round()}',
                  ),
                  Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
                  _buildMetricColumn(
                    theme,
                    title: '${_selectedDays == 7 ? '今週' : '月末'}予測純収支',
                    value: '${report.netBalance > 0 ? '+' : ''}${report.netBalance.round()} kcal',
                    subtitle: '対消費: ${report.tdeeTotal.round()}',
                    valueColor: report.netBalance <= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                  Container(width: 1, height: 36, color: theme.colorScheme.outlineVariant),
                  _buildMetricColumn(
                    theme,
                    title: '${_selectedDays == 7 ? '今週' : '月末'}体脂肪予測',
                    value: '${report.fatChangeKg > 0 ? '+' : ''}${report.fatChangeKg.toStringAsFixed(2)} kg',
                    subtitle: '7,200kcal/kg',
                    valueColor: report.fatChangeKg <= 0
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                  ),
                ],
              ),
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
