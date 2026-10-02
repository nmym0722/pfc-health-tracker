import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../models/weight_log.dart';

class WeightLineChart extends StatelessWidget {
  final List<WeightLog> logs;
  final double targetWeight;
  final double height;

  const WeightLineChart({
    super.key,
    required this.logs,
    required this.targetWeight,
    this.height = 240.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (logs.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'データがありません',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // 日付昇順にソート
    final sortedLogs = List<WeightLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '体重推移グラフ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 3,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '体重推移',
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 12,
                      height: 2,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '目標 (${targetWeight}kg)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(
                painter: _WeightChartPainter(
                  logs: sortedLogs,
                  targetWeight: targetWeight,
                  theme: theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final double targetWeight;
  final ThemeData theme;

  _WeightChartPainter({
    required this.logs,
    required this.targetWeight,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    const paddingLeft = 40.0;
    const paddingBottom = 30.0;
    const paddingTop = 20.0;
    const paddingRight = 20.0;

    final drawWidth = size.width - paddingLeft - paddingRight;
    final drawHeight = size.height - paddingTop - paddingBottom;

    // Y軸（体重）の最小・最大スケール計算
    double minW = targetWeight;
    double maxW = targetWeight;

    for (final l in logs) {
      if (l.weight < minW) minW = l.weight;
      if (l.weight > maxW) maxW = l.weight;
    }

    // 上下にマージンを持たせる
    minW = (minW - 1.5).floorToDouble();
    maxW = (maxW + 1.5).ceilToDouble();
    if (maxW == minW) maxW = minW + 4.0;

    final rangeW = maxW - minW;

    double getY(double weight) {
      final ratio = (weight - minW) / rangeW;
      return paddingTop + drawHeight * (1.0 - ratio);
    }

    double getX(int index) {
      if (logs.length == 1) return paddingLeft + drawWidth / 2;
      final ratio = index / (logs.length - 1);
      return paddingLeft + ratio * drawWidth;
    }

    // 1. グリッド線 & Y軸目盛り描画
    final gridPaint = Paint()
      ..color = theme.colorScheme.outlineVariant.withOpacity(0.5)
      ..strokeWidth = 1.0;

    final textStyle = TextStyle(
      color: theme.colorScheme.onSurfaceVariant,
      fontSize: 10,
    );

    const steps = 4;
    for (int i = 0; i <= steps; i++) {
      final w = minW + (rangeW * i / steps);
      final y = getY(w);

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      final textSpan = TextSpan(
        text: '${w.toStringAsFixed(1)}k',
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // 2. 目標体重ライン (赤の破線) 描画
    final targetY = getY(targetWeight);
    final targetPaint = Paint()
      ..color = theme.colorScheme.error
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = paddingLeft;
    final endX = size.width - paddingRight;

    while (startX < endX) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(math.min(startX + dashWidth, endX), targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 3. X軸日付ラベル & ポイント座標計算
    final points = <Offset>[];
    final dateFormat = DateFormat('M/d');

    for (int i = 0; i < logs.length; i++) {
      final x = getX(i);
      final y = getY(logs[i].weight);
      points.add(Offset(x, y));

      // X軸の日付ラベル描画 (データ数が多い場合は間引く)
      if (logs.length <= 7 || i % (logs.length ~/ 5) == 0 || i == logs.length - 1) {
        final dateStr = dateFormat.format(logs[i].date);
        final dateSpan = TextSpan(text: dateStr, style: textStyle);
        final datePainter = TextPainter(
          text: dateSpan,
          textDirection: TextDirection.ltr,
        )..layout();
        datePainter.paint(
          canvas,
          Offset(x - datePainter.width / 2, size.height - paddingBottom + 6),
        );
      }
    }

    // 4. 折れ線下のエリアグラデーション描画
    if (points.length > 1) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      path.lineTo(points.last.dx, size.height - paddingBottom);
      path.lineTo(points.first.dx, size.height - paddingBottom);
      path.close();

      final fillGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          theme.colorScheme.primary.withOpacity(0.25),
          theme.colorScheme.primary.withOpacity(0.0),
        ],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromLTWH(paddingLeft, paddingTop, drawWidth, drawHeight),
        );

      canvas.drawPath(path, fillPaint);
    }

    // 5. 折れ線本体の描画
    final linePaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (points.length == 1) {
      canvas.drawCircle(points.first, 5.0, Paint()..color = theme.colorScheme.primary);
    } else {
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // 6. 各データポイント（円ドット & 体重数値ラベル）
    final dotPaint = Paint()..color = theme.colorScheme.primary;
    final dotInnerPaint = Paint()..color = Colors.white;

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 5.0, dotPaint);
      canvas.drawCircle(pt, 2.5, dotInnerPaint);

      // 最新のポイントには体重数値をバルーン表示
      if (i == points.length - 1) {
        final weightStr = '${logs[i].weight}kg';
        final labelSpan = TextSpan(
          text: weightStr,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        );
        final labelPainter = TextPainter(
          text: labelSpan,
          textDirection: TextDirection.ltr,
        )..layout();

        labelPainter.paint(
          canvas,
          Offset(pt.dx - labelPainter.width / 2, pt.dy - 20),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.logs != logs || oldDelegate.targetWeight != targetWeight;
  }
}
