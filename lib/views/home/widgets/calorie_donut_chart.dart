import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../models/meal_record.dart';

class CalorieDonutChart extends StatelessWidget {
  final double targetCalories;
  final double currentCalories;
  final Map<MealType, double> categoryCalories;
  final double size;
  final double strokeWidth;

  const CalorieDonutChart({
    super.key,
    required this.targetCalories,
    required this.currentCalories,
    required this.categoryCalories,
    this.size = 200.0,
    this.strokeWidth = 16.0,
  });

  static Map<MealType, Color> getCategoryColors(ThemeData theme) {
    return {
      MealType.breakfast: const Color(0xFFF59E0B), // 朝食: Amber / Orange
      MealType.lunch: theme.colorScheme.primary,    // 昼食: Emerald Green
      MealType.dinner: const Color(0xFF3B82F6),   // 夕食: Royal Blue
      MealType.snack: const Color(0xFF8B5CF6),    // 間食: Purple
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryColors = getCategoryColors(theme);
    final remainingCal = targetCalories - currentCalories;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size),
                painter: _DonutChartPainter(
                  targetCalories: targetCalories,
                  categoryCalories: categoryCalories,
                  categoryColors: categoryColors,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  strokeWidth: strokeWidth,
                ),
              ),
              // 中央表示コンテンツ
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '本日の総摂取',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currentCalories.round().toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        ' kcal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: remainingCal >= 0
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      remainingCal >= 0
                          ? '残り ${remainingCal.round()} kcal'
                          : '${(-remainingCal).round()} kcal 超過',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: remainingCal >= 0
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double targetCalories;
  final Map<MealType, double> categoryCalories;
  final Map<MealType, Color> categoryColors;
  final Color backgroundColor;
  final double strokeWidth;

  _DonutChartPainter({
    required this.targetCalories,
    required this.categoryCalories,
    required this.categoryColors,
    required this.backgroundColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. 背景トラックを描画 (円形グラデーション背景)
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi,
      false,
      bgPaint,
    );

    if (targetCalories <= 0) return;

    // 2. 食事区分ごとのセグメント描画 (朝・昼・夕・間食)
    double startAngle = -math.pi / 2; // 上部 (12時方向) からスタート

    for (final type in MealType.values) {
      final calories = categoryCalories[type] ?? 0.0;
      if (calories <= 0) continue;

      final sweepAngle = (calories / targetCalories) * (2 * math.pi);
      final color = categoryColors[type] ?? Colors.grey;

      final segmentPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.targetCalories != targetCalories ||
        oldDelegate.categoryCalories != categoryCalories ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
