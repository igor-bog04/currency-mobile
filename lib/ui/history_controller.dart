/// Загрузка истории курсов за период для экранов сравнения.
library;

import 'package:flutter/foundation.dart';

import '../data/rate_repository.dart';

class HistoryController extends ChangeNotifier {
  HistoryController(this.repository, {required this.days});

  final RateRepository repository;
  final int days;

  HistoryResult? history;
  bool loading = false;
  String? error;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      history = await repository.history(days);
    } on Object catch (exception) {
      error = 'Не удалось загрузить историю курсов: $exception';
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
