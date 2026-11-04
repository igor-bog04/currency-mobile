/// Локальное хранилище снимков курсов: переживает перезапуск приложения.
library;

import 'dart:convert';
import 'dart:io';

import '../domain/models.dart';

abstract interface class RateStore {
  Future<RateSnapshot?> read(DateTime date);

  Future<void> write(RateSnapshot snapshot);

  /// Самый свежий сохранённый снимок — для работы без сети.
  Future<RateSnapshot?> latest();
}

/// Один JSON-файл на дату: rates_ГГГГ-ММ-ДД.json. Запись атомарная через временный файл.
class FileRateStore implements RateStore {
  FileRateStore(this.directory);

  final Directory directory;

  File _file(DateTime date) => File('${directory.path}${Platform.pathSeparator}rates_${dateKey(date)}.json');

  @override
  Future<RateSnapshot?> read(DateTime date) => _load(_file(date));

  @override
  Future<void> write(RateSnapshot snapshot) async {
    await directory.create(recursive: true);
    final target = _file(snapshot.date);
    final temp = File('${target.path}.tmp');
    await temp.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
    await temp.rename(target.path);
  }

  @override
  Future<RateSnapshot?> latest() async {
    if (!await directory.exists()) return null;
    final names = await directory
        .list()
        .where((entry) => entry is File)
        .map((entry) => entry.uri.pathSegments.last)
        .where((name) => RegExp(r'^rates_\d{4}-\d{2}-\d{2}\.json$').hasMatch(name))
        .toList();
    names.sort();
    for (final name in names.reversed) {
      final snapshot = await _load(File('${directory.path}${Platform.pathSeparator}$name'));
      if (snapshot != null) return snapshot;
    }
    return null;
  }

  Future<RateSnapshot?> _load(File file) async {
    try {
      if (!await file.exists()) return null;
      return RateSnapshot.fromJson(jsonDecode(await file.readAsString()) as Map<String, dynamic>);
    } on Object {
      return null; // повреждённый файл кэша не должен ронять приложение
    }
  }
}

class InMemoryRateStore implements RateStore {
  final _items = <String, RateSnapshot>{};

  @override
  Future<RateSnapshot?> read(DateTime date) async => _items[dateKey(date)];

  @override
  Future<void> write(RateSnapshot snapshot) async => _items[dateKey(snapshot.date)] = snapshot;

  @override
  Future<RateSnapshot?> latest() async {
    if (_items.isEmpty) return null;
    final keys = _items.keys.toList()..sort();
    return _items[keys.last];
  }
}
