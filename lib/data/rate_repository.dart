/// Получение курсов: кэш, сеть, откат на прошлые даты и работа без сети.
library;

import '../domain/errors.dart';
import '../domain/models.dart';
import 'bnm_api.dart';
import 'rate_store.dart';

class RatesResult {
  const RatesResult({required this.snapshot, required this.requestedDate, required this.offline});

  final RateSnapshot snapshot;
  final DateTime requestedDate;

  /// true — сеть недоступна, показан последний сохранённый снимок.
  final bool offline;

  /// Курс взят за более раннюю дату, чем запрошена.
  bool get isFallbackDate => dayOnly(snapshot.date) != dayOnly(requestedDate);
}

class HistoryResult {
  const HistoryResult({required this.snapshots, required this.requestedDays, required this.offline});

  /// Снимки по возрастанию даты; дни без данных пропущены.
  final List<RateSnapshot> snapshots;
  final int requestedDays;

  /// Часть дней не удалось загрузить из-за сети — показаны только сохранённые.
  final bool offline;

  int get missingDays => requestedDays - snapshots.length;

  /// Последняя дата, на которую есть данные.
  DateTime? get latestDate => snapshots.isEmpty ? null : snapshots.last.date;

  List<RatePoint> pointsFor(String from, String to) => [
        for (final snapshot in snapshots)
          if (snapshot.crossRate(from, to) case final rate?) RatePoint(snapshot.date, rate),
      ];
}

class RateRepository {
  RateRepository({required RateSource source, required RateStore store, DateTime Function()? clock})
      : _source = source,
        _store = store,
        _clock = clock ?? DateTime.now;

  static const maxFallbackDays = 10;
  static const parallelRequests = 6;

  final RateSource _source;
  final RateStore _store;
  final DateTime Function() _clock;

  DateTime get today => dayOnly(_clock());

  /// Курсы на дату. Если на неё курсов нет — ищет назад до [maxFallbackDays] дней.
  /// Без сети — последний сохранённый снимок с пометкой offline.
  Future<RatesResult> ratesFor(DateTime date) async {
    final requested = dayOnly(date);
    try {
      for (var back = 0; back <= maxFallbackDays; back++) {
        final day = requested.subtract(Duration(days: back));
        final snapshot = await _snapshotFor(day);
        if (snapshot != null) {
          return RatesResult(snapshot: snapshot, requestedDate: requested, offline: false);
        }
      }
      throw const SourceUnavailableException('Курсы не найдены за последние 10 дней');
    } on SourceUnavailableException {
      final cached = await _store.latest();
      if (cached == null) rethrow;
      return RatesResult(snapshot: cached, requestedDate: requested, offline: true);
    }
  }

  /// История за [days] дней, заканчивая сегодняшним днём.
  Future<HistoryResult> history(int days) async {
    final end = today;
    final dates = [for (var i = days - 1; i >= 0; i--) end.subtract(Duration(days: i))];
    final snapshots = <RateSnapshot>[];
    var offline = false;

    for (var start = 0; start < dates.length; start += parallelRequests) {
      final batch = dates.skip(start).take(parallelRequests);
      final results = await Future.wait(batch.map((day) async {
        try {
          return await _snapshotFor(day);
        } on SourceUnavailableException {
          offline = true;
          return _store.read(day);
        }
      }));
      snapshots.addAll(results.whereType<RateSnapshot>());
    }

    final unique = {for (final snapshot in snapshots) dateKey(snapshot.date): snapshot};
    final sorted = unique.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    return HistoryResult(snapshots: sorted, requestedDays: days, offline: offline);
  }

  /// Прошедшие дни берутся из кэша: официальный курс за прошлую дату не меняется.
  /// Сегодняшний день всегда запрашивается заново. null — на эту дату курсов нет.
  Future<RateSnapshot?> _snapshotFor(DateTime day) async {
    if (day.isBefore(today)) {
      final cached = await _store.read(day);
      if (cached != null) return cached;
    }
    try {
      final snapshot = await _source.fetch(day);
      await _store.write(snapshot);
      return snapshot;
    } on NoRatesForDateException {
      return null;
    }
  }
}
