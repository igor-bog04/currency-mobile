/// Статистика показателя за период для экранов сравнения.
library;

import 'models.dart';

enum Trend { up, down, flat }

class PeriodStats {
  const PeriodStats({
    required this.min,
    required this.max,
    required this.average,
    required this.first,
    required this.last,
    required this.absoluteChange,
    required this.percentChange,
    required this.trend,
  });

  /// Изменение меньше этого порога (в процентах) считается отсутствием изменений.
  static const flatThresholdPercent = 0.01;

  final RatePoint min;
  final RatePoint max;
  final double average;
  final RatePoint first;
  final RatePoint last;
  final double absoluteChange;
  final double percentChange;
  final Trend trend;

  /// null для пустого набора: статистику не из чего считать.
  static PeriodStats? fromPoints(List<RatePoint> points) {
    if (points.isEmpty) return null;
    final sorted = [...points]..sort((a, b) => a.date.compareTo(b.date));

    var min = sorted.first;
    var max = sorted.first;
    var sum = 0.0;
    for (final point in sorted) {
      if (point.value < min.value) min = point;
      if (point.value > max.value) max = point;
      sum += point.value;
    }

    final first = sorted.first;
    final last = sorted.last;
    final absoluteChange = last.value - first.value;
    final percentChange = first.value == 0 ? 0.0 : absoluteChange / first.value * 100;
    final trend = percentChange.abs() < flatThresholdPercent
        ? Trend.flat
        : (percentChange > 0 ? Trend.up : Trend.down);

    return PeriodStats(
      min: min,
      max: max,
      average: sum / sorted.length,
      first: first,
      last: last,
      absoluteChange: absoluteChange,
      percentChange: percentChange,
      trend: trend,
    );
  }
}
