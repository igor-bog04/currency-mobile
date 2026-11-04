/// Предметная модель: валюты, снимки курсов и точки истории.
library;

/// Валюта и её официальный курс к молдавскому лею: сколько MDL стоит 1 единица.
class Currency {
  const Currency({required this.code, required this.name, required this.rateToMdl});

  final String code;
  final String name;
  final double rateToMdl;

  Map<String, Object> toJson() => {'code': code, 'name': name, 'rate': rateToMdl};

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code'] as String,
        name: json['name'] as String,
        rateToMdl: (json['rate'] as num).toDouble(),
      );
}

/// Набор официальных курсов BNM на одну дату. MDL всегда присутствует с курсом 1.
class RateSnapshot {
  RateSnapshot({required this.date, required Iterable<Currency> currencies})
      : currencies = {
          mdlCode: const Currency(code: mdlCode, name: 'Moldovan Leu', rateToMdl: 1),
          for (final currency in currencies) currency.code: currency,
        };

  static const mdlCode = 'MDL';

  final DateTime date;
  final Map<String, Currency> currencies;

  /// Курс «1 [from] = x [to]» через MDL. null — если одной из валют нет в снимке.
  double? crossRate(String from, String to) {
    final source = currencies[from];
    final target = currencies[to];
    if (source == null || target == null) return null;
    return source.rateToMdl / target.rateToMdl;
  }

  Map<String, Object> toJson() => {
        'date': dateKey(date),
        'currencies': [
          for (final currency in currencies.values)
            if (currency.code != mdlCode) currency.toJson(),
        ],
      };

  factory RateSnapshot.fromJson(Map<String, dynamic> json) => RateSnapshot(
        date: DateTime.parse(json['date'] as String),
        currencies: (json['currencies'] as List)
            .map((item) => Currency.fromJson(item as Map<String, dynamic>)),
      );
}

/// Значение показателя (курса пары) на дату — точка графика.
class RatePoint {
  const RatePoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Дата без времени: все расчёты по календарным дням.
DateTime dayOnly(DateTime value) => DateTime(value.year, value.month, value.day);

/// Ключ даты в формате ГГГГ-ММ-ДД для хранения.
String dateKey(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
