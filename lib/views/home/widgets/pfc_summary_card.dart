import 'package:flutter/material.dart';
import '../../../models/meal_record.dart';
import 'calorie_donut_chart.dart';

class PfcSummaryCard extends StatelessWidget {
  final double targetCalories;
  final double currentCalories;
  final Map<MealType, double> categoryCalories;
  final double targetProtein;
  final double currentProtein;
  final double targetFat;
  final double currentFat;
  final double targetCarbs;
  final double currentCarbs;

  const PfcSummaryCard({
    super.key,
    required this.targetCalories,
    required this.currentCalories,
    required this.categoryCalories,
    required this.targetProtein,
    required this.currentProtein,
    required this.targetFat,
    required this.currentFat,
    required this.targetCarbs,
    required this.currentCarbs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. 円形ドーナツカロリーチャート (朝/昼/夕/間食の色分けプログレス)
            CalorieDonutChart(
              targetCalories: targetCalories,
              currentCalories: currentCalories,
              categoryCalories: categoryCalories,
              size: 190.0,
              strokeWidth: 16.0,
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 2. PFC進捗バー一覧
            Builder(
              builder: (context) {
                // 各マクロ栄養素の摂取カロリー計算 (P: 4kcal/g, F: 9kcal/g, C: 4kcal/g)
                final pCal = currentProtein * 4.0;
                final fCal = currentFat * 9.0;
                final cCal = currentCarbs * 4.0;

                // 全摂取カロリーに対するパーセンテージ
                final pPct = currentCalories > 0 ? (pCal / currentCalories * 100) : 0.0;
                final fPct = currentCalories > 0 ? (fCal / currentCalories * 100) : 0.0;
                final cPct = currentCalories > 0 ? (cCal / currentCalories * 100) : 0.0;

                return Column(
                  children: [
                    // マクロ栄養素バランス サマリー
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'マクロ栄養素バランス',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          'P ${pPct.toStringAsFixed(0)}% : F ${fPct.toStringAsFixed(0)}% : C ${cPct.toStringAsFixed(0)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PfcRow(
                      label: 'P (タンパク質)',
                      current: currentProtein,
                      target: targetProtein,
                      color: theme.colorScheme.primary,
                      unit: 'g',
                      caloriePercentage: pPct,
                    ),
                    const SizedBox(height: 12),
                    _PfcRow(
                      label: 'F (脂質)',
                      current: currentFat,
                      target: targetFat,
                      color: theme.colorScheme.secondary,
                      unit: 'g',
                      caloriePercentage: fPct,
                    ),
                    const SizedBox(height: 12),
                    _PfcRow(
                      label: 'C (炭水化物)',
                      current: currentCarbs,
                      target: targetCarbs,
                      color: theme.colorScheme.tertiary,
                      unit: 'g',
                      caloriePercentage: cPct,
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
}

class _PfcRow extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;
  final double caloriePercentage;

  const _PfcRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
    required this.caloriePercentage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOver = current > target && target > 0;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - current;
    final overAmount = current - target;

    final progressColor = isOver ? theme.colorScheme.error : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${caloriePercentage.toStringAsFixed(1)}%',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Flexible(
              child: RichText(
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  children: [
                    TextSpan(
                      text: '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(1)}$unit ',
                    ),
                    if (isOver)
                      TextSpan(
                        text: '(${overAmount.toStringAsFixed(1)}$unit 超過)',
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    else
                      TextSpan(
                        text: '(残 ${remaining > 0 ? remaining.toStringAsFixed(1) : '0'}$unit)',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isOver ? 1.0 : progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
          ),
        ),
      ],
    );
  }
}
