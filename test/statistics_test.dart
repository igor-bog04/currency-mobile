import 'package:currency_mobile/domain/models.dart';
import 'package:currency_mobile/domain/statistics.dart';
import 'package:flutter_test/flutter_test.dart';

RatePoint point(int day, double value) => RatePoint(DateTime(2026, 11, day), value);

void main() {
  test('min, max, average, change and trend for a rising period', () {
    final stats = PeriodStats.fromPoints([point(1, 20), point(2, 19), point(3, 21), point(4, 22)])!;

    expect(stats.min.value, 19);
    expect(stats.min.date, DateTime(2026, 11, 2));
    expect(stats.max.value, 22);
    expect(stats.average, 20.5);
    expect(stats.absoluteChange, 2);
    expect(stats.percentChange, closeTo(10, 1e-9));
    expect(stats.trend, Trend.up);
  });

  test('falling period', () {
    final stats = PeriodStats.fromPoints([point(1, 20), point(2, 18)])!;

    expect(stats.absoluteChange, -2);
    expect(stats.percentChange, closeTo(-10, 1e-9));
    expect(stats.trend, Trend.down);
  });

  test('change below threshold counts as no change', () {
    final stats = PeriodStats.fromPoints([point(1, 20), point(2, 20.001)])!;

    expect(stats.trend, Trend.flat);
  });

  test('points are ordered by date regardless of input order', () {
    final stats = PeriodStats.fromPoints([point(3, 30), point(1, 10), point(2, 20)])!;

    expect(stats.first.value, 10);
    expect(stats.last.value, 30);
  });

  test('single point: no change, flat trend', () {
    final stats = PeriodStats.fromPoints([point(1, 20)])!;

    expect(stats.min.value, 20);
    expect(stats.max.value, 20);
    expect(stats.absoluteChange, 0);
    expect(stats.percentChange, 0);
    expect(stats.trend, Trend.flat);
  });

  test('empty data set returns null instead of throwing', () {
    expect(PeriodStats.fromPoints([]), isNull);
  });
}
