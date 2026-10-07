import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../core/algorithms/weight_ema.dart';
import '../../../models/weight_log.dart';
import '../../../providers/weight_provider.dart';

class WeightLineChart extends StatelessWidget {
  final List<WeightLog> logs;
  final List<WeightEmaPoint>? emaPoints;
  final double targetWeight;
  final double? initialWeight;
  final DateTime? startDate;
  final DateTime? targetDate;
  final double height;

  const WeightLineChart({
    super.key,
    required this.logs,
    this.emaPoints,
    required this.targetWeight,
    this.initialWeight,
    this.startDate,
    this.targetDate,
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

    // EMA系列が渡されていない場合は自律計算
    final effectiveEmaPoints = emaPoints ?? calculateEmaFromLogs(sortedLogs);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '体重トレンド & 計画ペース',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 凡例 (M3 Chip/Legend)
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildLegendItem(
                  theme,
                  color: theme.colorScheme.primary,
                  label: '7日EMAトレンド',
                  isSolid: true,
                  strokeWidth: 3,
                ),
                _buildLegendItem(
                  theme,
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  label: '生測定値',
                  isDot: true,
                ),
                if (startDate != null && targetDate != null)
                  _buildLegendItem(
                    theme,
                    color: theme.colorScheme.outline,
                    label: '計画ペース線',
                    isDashed: true,
                  ),
                _buildLegendItem(
                  theme,
                  color: theme.colorScheme.error,
                  label: '目標 (${targetWeight}kg)',
                  isDashed: true,
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
                  emaPoints: effectiveEmaPoints,
                  targetWeight: targetWeight,
                  initialWeight: initialWeight ?? sortedLogs.first.weight,
                  startDate: startDate ?? sortedLogs.first.date,
                  targetDate: targetDate ?? sortedLogs.last.date.add(const Duration(days: 30)),
                  theme: theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(
    ThemeData theme, {
    required Color color,
    required String label,
    bool isSolid = false,
    bool isDashed = false,
    bool isDot = false,
    double strokeWidth = 2,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDot)
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          )
        else if (isDashed)
          Row(
            children: [
              Container(width: 4, height: strokeWidth, color: color),
              const SizedBox(width: 2),
              Container(width: 4, height: strokeWidth, color: color),
            ],
          )
        else
          Container(
            width: 12,
            height: strokeWidth,
            color: color,
          ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _WeightChartPainter extends CustomPainter {
  final List<WeightLog> logs;
  final List<WeightEmaPoint> emaPoints;
  final double targetWeight;
  final double initialWeight;
  final DateTime startDate;
  final DateTime targetDate;
  final ThemeData theme;

  _WeightChartPainter({
    required this.logs,
    required this.emaPoints,
    required this.targetWeight,
    required this.initialWeight,
    required this.startDate,
    required this.targetDate,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;

    const paddingLeft = 40.0;
    const paddingBottom = 30.0;
    const paddingTop = 24.0;
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
    for (final p in emaPoints) {
      if (p.emaWeight < minW) minW = p.emaWeight;
      if (p.emaWeight > maxW) maxW = p.emaWeight;
    }

    // 上下にマージンを持たせる
    minW = (minW - 1.5).floorToDouble();
    maxW = (maxW + 1.5).ceilToDouble();
    if (maxW == minW) maxW = minW + 4.0;

    final rangeW = maxW - minW;

    double getY(double weight) {
      final ratio = (weight - minW) / rangeW;
      return paddingTop + drawHeight * (1.0 - ratio.clamp(0.0, 1.0));
    }

    double getX(int index, int totalCount) {
      if (totalCount <= 1) return paddingLeft + drawWidth / 2;
      final ratio = index / (totalCount - 1);
      return paddingLeft + ratio * drawWidth;
    }

    // 1. グリッド線 & Y軸目盛り描画
    final gridPaint = Paint()
      ..color = theme.colorScheme.outlineVariant.withOpacity(0.4)
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
      ..strokeWidth = 1.8
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

    // 3. 理想の計画ペース線（薄いグレーの破線）
    final totalDuration = targetDate.difference(startDate).inDays;
    if (totalDuration > 0 && logs.isNotEmpty) {
      final planPaint = Paint()
        ..color = theme.colorScheme.outline.withOpacity(0.7)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final firstLogDate = logs.first.date;
      final lastLogDate = logs.last.date;

      final startElapsed = firstLogDate.difference(startDate).inDays.clamp(0, totalDuration);
      final endElapsed = lastLogDate.difference(startDate).inDays.clamp(0, totalDuration);

      final startPlanWeight = initialWeight + (targetWeight - initialWeight) * (startElapsed / totalDuration);
      final endPlanWeight = initialWeight + (targetWeight - initialWeight) * (endElapsed / totalDuration);

      final planP1 = Offset(getX(0, logs.length), getY(startPlanWeight));
      final planP2 = Offset(getX(logs.length - 1, logs.length), getY(endPlanWeight));

      // 破線で描画
      final totalDist = (planP2 - planP1).distance;
      if (totalDist > 0) {
        final direction = (planP2 - planP1) / totalDist;
        double curDist = 0.0;
        while (curDist < totalDist) {
          final pA = planP1 + direction * curDist;
          final pB = planP1 + direction * math.min(curDist + 4.0, totalDist);
          canvas.drawLine(pA, pB, planPaint);
          curDist += 8.0;
        }
      }
    }

    // 4. 生測定値のプロット（薄い点線 & プロット点）
    final rawPoints = <Offset>[];
    for (int i = 0; i < logs.length; i++) {
      final x = getX(i, logs.length);
      final y = getY(logs[i].weight);
      rawPoints.add(Offset(x, y));
    }

    if (rawPoints.length > 1) {
      final rawLinePaint = Paint()
        ..color = theme.colorScheme.primary.withOpacity(0.3)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;

      final rawPath = Path()..moveTo(rawPoints.first.dx, rawPoints.first.dy);
      for (int i = 1; i < rawPoints.length; i++) {
        rawPath.lineTo(rawPoints[i].dx, rawPoints[i].dy);
      }
      canvas.drawPath(rawPath, rawLinePaint);
    }

    // 生測定ドット
    for (int i = 0; i < logs.length; i++) {
      final pt = rawPoints[i];
      final isCheat = logs[i].isCheatDay;
      final rawDotPaint = Paint()
        ..color = isCheat
            ? theme.colorScheme.tertiary
            : theme.colorScheme.primary.withOpacity(0.45);

      canvas.drawCircle(pt, isCheat ? 4.5 : 3.5, rawDotPaint);
    }

    // 5. 7日EMAトレンド曲線の描画（実線 & グラデーション塗り）
    final emaPointsToDraw = <Offset>[];
    for (int i = 0; i < emaPoints.length; i++) {
      final x = getX(i, emaPoints.length);
      final y = getY(emaPoints[i].emaWeight);
      emaPointsToDraw.add(Offset(x, y));
    }

    if (emaPointsToDraw.isNotEmpty) {
      // グラデーション塗りつぶし
      if (emaPointsToDraw.length > 1) {
        final fillPath = Path()..moveTo(emaPointsToDraw.first.dx, emaPointsToDraw.first.dy);
        for (int i = 1; i < emaPointsToDraw.length; i++) {
          fillPath.lineTo(emaPointsToDraw[i].dx, emaPointsToDraw[i].dy);
        }
        fillPath.lineTo(emaPointsToDraw.last.dx, size.height - paddingBottom);
        fillPath.lineTo(emaPointsToDraw.first.dx, size.height - paddingBottom);
        fillPath.close();

        final fillGradient = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withOpacity(0.22),
            theme.colorScheme.primary.withOpacity(0.0),
          ],
        );

        final fillPaint = Paint()
          ..shader = fillGradient.createShader(
            Rect.fromLTWH(paddingLeft, paddingTop, drawWidth, drawHeight),
          );

        canvas.drawPath(fillPath, fillPaint);
      }

      // 太い実線描画
      final emaLinePaint = Paint()
        ..color = theme.colorScheme.primary
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (emaPointsToDraw.length == 1) {
        canvas.drawCircle(emaPointsToDraw.first, 5.0, Paint()..color = theme.colorScheme.primary);
      } else {
        final emaPath = Path()..moveTo(emaPointsToDraw.first.dx, emaPointsToDraw.first.dy);
        for (int i = 1; i < emaPointsToDraw.length; i++) {
          emaPath.lineTo(emaPointsToDraw[i].dx, emaPointsToDraw[i].dy);
        }
        canvas.drawPath(emaPath, emaLinePaint);
      }

      // 最新EMAポイントの強調ドット & ラベル
      final lastEmaPt = emaPointsToDraw.last;
      canvas.drawCircle(lastEmaPt, 5.5, Paint()..color = theme.colorScheme.primary);
      canvas.drawCircle(lastEmaPt, 2.5, Paint()..color = Colors.white);

      final latestEmaVal = emaPoints.last.emaWeight.toStringAsFixed(1);
      final labelSpan = TextSpan(
        text: 'EMA: ${latestEmaVal}kg',
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
        Offset(lastEmaPt.dx - labelPainter.width / 2, lastEmaPt.dy - 22),
      );
    }

    // 6. X軸日付ラベル描画
    final dateFormat = DateFormat('M/d');
    for (int i = 0; i < logs.length; i++) {
      if (logs.length <= 7 || i % (logs.length ~/ 5) == 0 || i == logs.length - 1) {
        final x = getX(i, logs.length);
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
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) {
    return oldDelegate.logs != logs ||
        oldDelegate.emaPoints != emaPoints ||
        oldDelegate.targetWeight != targetWeight;
  }
}

