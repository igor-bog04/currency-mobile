/// Линейный график курса пары за период.
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../format.dart';

class RateChart extends StatelessWidget {
  const RateChart({super.key, required this.points, required this.color});

  final List<RatePoint> points;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final start = points.first.date;
    double x(DateTime date) => date.difference(start).inHours / 24;

    final values = points.map((p) => p.value);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    // Запас по вертикали, чтобы линия не прилипала к краям; для ровной линии — фиксированный.
    final padding = maxValue == minValue ? (maxValue.abs() * 0.01 + 0.0001) : (maxValue - minValue) * 0.15;
    final lastX = x(points.last.date);
    final labelStep = math.max(1, (lastX / 4).ceil()).toDouble();

    return LineChart(
      LineChartData(
        minY: minValue - padding,
        maxY: maxValue + padding,
        minX: 0,
        maxX: math.max(lastX, 1),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: scheme.outlineVariant.withValues(alpha: 0.4), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              // Крайние значения оси не подписываем: они налезают на соседние линии сетки.
              getTitlesWidget: (value, meta) => value == meta.min || value == meta.max
                  ? const SizedBox.shrink()
                  : SideTitleWidget(
                      meta: meta,
                      child: Text(formatRate(value), style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                    ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: labelStep,
              reservedSize: 26,
              getTitlesWidget: (value, meta) => SideTitleWidget(
                meta: meta,
                child: Text(
                  formatShortDate(start.add(Duration(days: value.round()))),
                  style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipBorderRadius: BorderRadius.circular(10),
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${formatDate(start.add(Duration(days: spot.x.round())))}\n${formatRate(spot.y)}',
                  TextStyle(color: scheme.onInverseSurface, fontWeight: FontWeight.w600, fontSize: 12),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (final point in points) FlSpot(x(point.date), point.value)],
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 3,
            dotData: FlDotData(show: points.length <= 10),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
