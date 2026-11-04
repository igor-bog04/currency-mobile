/// Состояние конвертера: выбранная пара, дата и загруженные курсы.
library;

import 'package:flutter/foundation.dart';

import '../data/rate_repository.dart';
import '../domain/errors.dart';
import '../domain/models.dart';

class RatesController extends ChangeNotifier {
  RatesController(this.repository) : selectedDate = repository.today;

  final RateRepository repository;

  /// Валюты, которые показываются первыми в списке выбора.
  static const popular = ['MDL', 'EUR', 'USD', 'RON', 'UAH', 'RUB', 'GBP'];

  RatesResult? result;
  DateTime selectedDate;
  bool loading = false;
  String? error;
  String from = 'EUR';
  String to = 'MDL';

  RateSnapshot? get snapshot => result?.snapshot;

  List<Currency> get currencies {
    final all = [...?snapshot?.currencies.values];
    int rank(Currency c) => popular.contains(c.code) ? popular.indexOf(c.code) : popular.length;
    return all..sort((a, b) => rank(a) != rank(b) ? rank(a) - rank(b) : a.code.compareTo(b.code));
  }

  Future<void> load([DateTime? date]) async {
    selectedDate = dayOnly(date ?? selectedDate);
    loading = true;
    error = null;
    notifyListeners();
    try {
      result = await repository.ratesFor(selectedDate);
    } on SourceUnavailableException {
      error = 'Нет связи с сервером BNM и нет сохранённых курсов. Проверьте интернет и попробуйте снова.';
    } on Object catch (exception) {
      error = 'Не удалось загрузить курсы: $exception';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setPair({String? from, String? to}) {
    this.from = from ?? this.from;
    this.to = to ?? this.to;
    notifyListeners();
  }

  void swap() => setPair(from: to, to: from);
}
