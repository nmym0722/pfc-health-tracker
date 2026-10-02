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
            _PfcRow(
              label: 'P (タンパク質)',
              current: currentProtein,
              target: targetProtein,
              color: theme.colorScheme.primary,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _PfcRow(
              label: 'F (脂質)',
              current: currentFat,
              target: targetFat,
              color: theme.colorScheme.secondary,
              unit: 'g',
            ),
            const SizedBox(height: 12),
            _PfcRow(
              label: 'C (炭水化物)',
              current: currentCarbs,
              target: targetCarbs,
              color: theme.colorScheme.tertiary,
              unit: 'g',
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

  const _PfcRow({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    final remaining = target - current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${current.toStringAsFixed(1)} / ${target.toStringAsFixed(1)} $unit (残り ${remaining > 0 ? remaining.toStringAsFixed(1) : '0'} $unit)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
