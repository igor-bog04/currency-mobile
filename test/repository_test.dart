import 'dart:io';

import 'package:currency_mobile/data/bnm_api.dart';
import 'package:currency_mobile/data/rate_repository.dart';
import 'package:currency_mobile/data/rate_store.dart';
import 'package:currency_mobile/domain/converter.dart';
import 'package:currency_mobile/domain/errors.dart';
import 'package:currency_mobile/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures.dart';

/// Источник с заданными ответами по датам; дата без ответа — 404.
class FakeSource implements RateSource {
  FakeSource(this.rates, {this.offline = false});

  final Map<String, RateSnapshot> rates;
  bool offline;
  final requested = <String>[];

  @override
  Future<RateSnapshot> fetch(DateTime date) async {
    requested.add(dateKey(date));
    if (offline) throw const SourceUnavailableException('offline');
    final snapshot = rates[dateKey(date)];
    if (snapshot == null) throw NoRatesForDateException(date);
    return snapshot;
  }
}

void main() {
  final today = DateTime(2026, 11, 4, 15, 30);
  RateRepository repo(FakeSource source, RateStore store) =>
      RateRepository(source: source, store: store, clock: () => today);

  group('ratesFor', () {
    test('returns rates for the requested date and caches them', () async {
      final store = InMemoryRateStore();
      final result = await repo(FakeSource({'2026-11-04': snapshot(DateTime(2026, 11, 4))}), store)
          .ratesFor(DateTime(2026, 11, 4));

      expect(result.offline, isFalse);
      expect(result.isFallbackDate, isFalse);
      expect(await store.read(DateTime(2026, 11, 4)), isNotNull);
    });

    test('steps back to the latest published date', () async {
      final source = FakeSource({'2026-11-04': snapshot(DateTime(2026, 11, 4))});
      final result = await repo(source, InMemoryRateStore()).ratesFor(DateTime(2026, 11, 6));

      expect(result.snapshot.date, DateTime(2026, 11, 4));
      expect(result.isFallbackDate, isTrue);
      expect(source.requested, ['2026-11-06', '2026-11-05', '2026-11-04']);
    });

    test('offline: falls back to the latest cached snapshot', () async {
      final store = InMemoryRateStore();
      await store.write(snapshot(DateTime(2026, 11, 1)));
      await store.write(snapshot(DateTime(2026, 11, 2)));

      final result = await repo(FakeSource({}, offline: true), store).ratesFor(DateTime(2026, 11, 4));

      expect(result.offline, isTrue);
      expect(result.snapshot.date, DateTime(2026, 11, 2));
    });

    test('offline without cache: throws a handled error', () {
      expect(repo(FakeSource({}, offline: true), InMemoryRateStore()).ratesFor(DateTime(2026, 11, 4)),
          throwsA(isA<SourceUnavailableException>()));
    });

    test('past dates are served from cache without a request', () async {
      final store = InMemoryRateStore();
      await store.write(snapshot(DateTime(2026, 11, 1)));
      final source = FakeSource({});

      await repo(source, store).ratesFor(DateTime(2026, 11, 1));

      expect(source.requested, isEmpty);
    });
  });

  group('history', () {
    test('collects one snapshot per published day and builds pair points', () async {
      final source = FakeSource({
        for (var day = 29; day <= 31; day++) '2026-10-$day': snapshot(DateTime(2026, 10, day), eur: 20.0 + day / 100),
        for (var day = 1; day <= 4; day++) '2026-11-0$day': snapshot(DateTime(2026, 11, day), eur: 21.0 + day / 100),
      });

      final history = await repo(source, InMemoryRateStore()).history(7);
      final points = history.pointsFor('EUR', 'MDL');

      expect(history.snapshots, hasLength(7));
      expect(history.offline, isFalse);
      expect(points.first.date, DateTime(2026, 10, 29));
      expect(points.last.value, 21.04);
    });

    test('offline: uses cached days only and reports it', () async {
      final store = InMemoryRateStore();
      await store.write(snapshot(DateTime(2026, 11, 2)));
      await store.write(snapshot(DateTime(2026, 11, 3)));

      final history = await repo(FakeSource({}, offline: true), store).history(7);

      expect(history.offline, isTrue);
      expect(history.snapshots.map((s) => s.date), [DateTime(2026, 11, 2), DateTime(2026, 11, 3)]);
      expect(history.missingDays, 5);
    });

    test('no data at all: empty history, no exception', () async {
      final history = await repo(FakeSource({}, offline: true), InMemoryRateStore()).history(30);

      expect(history.snapshots, isEmpty);
      expect(history.pointsFor('EUR', 'USD'), isEmpty);
      expect(history.latestDate, isNull);
    });
  });

  group('FileRateStore', () {
    test('survives a new instance (app restart) and ignores corrupt files', () async {
      final dir = await Directory.systemTemp.createTemp('rates_test');
      addTearDown(() => dir.delete(recursive: true));
      await FileRateStore(dir).write(snapshot(DateTime(2026, 11, 3), eur: 20.5));
      await File('${dir.path}/rates_2026-11-04.json').writeAsString('{broken');

      final restored = FileRateStore(dir);

      expect((await restored.read(DateTime(2026, 11, 3)))!.currencies['EUR']!.rateToMdl, 20.5);
      expect(await restored.read(DateTime(2026, 11, 4)), isNull);
      expect((await restored.latest())!.date, DateTime(2026, 11, 3));
    });
  });

  group('convert', () {
    test('cross rate through MDL in both directions', () {
      final conversion = convert(100, 'EUR', 'USD', snapshot(DateTime(2026, 11, 4), eur: 20, usd: 16))!;

      expect(conversion.result, 125);
      expect(conversion.forwardRate, 1.25);
      expect(conversion.reverseRate, 0.8);
    });

    test('same currency gives rate 1', () {
      final conversion = convert(42, 'USD', 'USD', snapshot(DateTime(2026, 11, 4)))!;

      expect(conversion.result, 42);
      expect(conversion.forwardRate, 1);
    });

    test('unknown currency returns null', () {
      expect(convert(1, 'EUR', 'XXX', snapshot(DateTime(2026, 11, 4))), isNull);
    });
  });
}
