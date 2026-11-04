/// Ошибки получения курсов, которые интерфейс показывает пользователю.
library;

/// Источник недоступен: нет сети, таймаут, ошибка сервера или некорректный ответ.
class SourceUnavailableException implements Exception {
  const SourceUnavailableException(this.reason);

  final String reason;

  @override
  String toString() => 'SourceUnavailableException: $reason';
}

/// На эту дату BNM курсы не публиковал (HTTP 404 или пустой ответ).
class NoRatesForDateException implements Exception {
  const NoRatesForDateException(this.date);

  final DateTime date;

  @override
  String toString() => 'NoRatesForDateException: $date';
}
