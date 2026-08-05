import 'dart:math' as math;

import 'package:flutter/material.dart';

final class AnalyticsChartSeries {
  const AnalyticsChartSeries({
    required this.label,
    required this.color,
    required this.values,
  });

  final String label;
  final Color color;
  final List<double?> values;
}

final class AnalyticsTrendChart extends StatelessWidget {
  const AnalyticsTrendChart({
    required this.series,
    required this.startLabel,
    required this.endLabel,
    super.key,
  });

  final List<AnalyticsChartSeries> series;
  final String startLabel;
  final String endLabel;

  bool get _hasValues =>
      series.any((item) => item.values.any((value) => value != null));

  @override
  Widget build(BuildContext context) {
    if (!_hasValues) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            '该周期暂无记录',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _AnalyticsTrendPainter(
              series: series,
              gridColor: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(startLabel, style: Theme.of(context).textTheme.labelSmall),
            Text(endLabel, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ],
    );
  }
}

final class _AnalyticsTrendPainter extends CustomPainter {
  const _AnalyticsTrendPainter({required this.series, required this.gridColor});

  final List<AnalyticsChartSeries> series;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    final available = series
        .expand((item) => item.values)
        .whereType<double>()
        .toList(growable: false);
    if (available.isEmpty) return;

    var minimum = available.reduce(math.min);
    var maximum = available.reduce(math.max);
    if (minimum == maximum) {
      minimum -= 0.5;
      maximum += 0.5;
    }
    final range = maximum - minimum;
    final chartRect = Rect.fromLTWH(4, 8, size.width - 8, size.height - 16);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final ratio in [0.0, 0.5, 1.0]) {
      final y = chartRect.top + chartRect.height * ratio;
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    for (final item in series) {
      final linePaint = Paint()
        ..color = item.color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final pointPaint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;
      final count = item.values.length;
      final path = Path();
      var drawing = false;
      for (var index = 0; index < count; index++) {
        final value = item.values[index];
        if (value == null) {
          drawing = false;
          continue;
        }
        final x = count <= 1
            ? chartRect.center.dx
            : chartRect.left + chartRect.width * index / (count - 1);
        final normalized = (value - minimum) / range;
        final y = chartRect.bottom - chartRect.height * normalized;
        final point = Offset(x, y);
        if (drawing) {
          path.lineTo(point.dx, point.dy);
        } else {
          path.moveTo(point.dx, point.dy);
          drawing = true;
        }
        canvas.drawCircle(point, 2.8, pointPaint);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyticsTrendPainter oldDelegate) {
    return oldDelegate.series != series || oldDelegate.gridColor != gridColor;
  }
}
