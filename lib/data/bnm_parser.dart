/// Разбор XML официальных курсов Национального банка Молдовы.
library;

import 'package:xml/xml.dart';

import '../domain/errors.dart';
import '../domain/models.dart';

/// Формат: `<ValCurs Date="04.11.2026"><Valute><CharCode/><Nominal/><Name/><Value/></Valute>...</ValCurs>`.
/// Курс 1 единицы валюты в MDL = Value / Nominal.
RateSnapshot parseBnmXml(String body, DateTime requestedDate) {
  if (body.trim().isEmpty) throw NoRatesForDateException(requestedDate);

  final XmlDocument document;
  try {
    document = XmlDocument.parse(body);
  } on XmlException catch (error) {
    throw SourceUnavailableException('Некорректный XML: ${error.message}');
  }

  final root = document.rootElement;
  if (root.name.local != 'ValCurs') {
    throw const SourceUnavailableException('Неожиданный формат ответа BNM');
  }

  final currencies = <Currency>[];
  for (final valute in root.findElements('Valute')) {
    final code = _text(valute, 'CharCode');
    final name = _text(valute, 'Name');
    final nominal = _number(valute, 'Nominal');
    final value = _number(valute, 'Value');
    if (code == null || name == null || nominal == null || value == null) continue;
    if (nominal <= 0 || value <= 0) continue;
    currencies.add(Currency(code: code, name: name, rateToMdl: value / nominal));
  }

  if (currencies.isEmpty) throw NoRatesForDateException(requestedDate);
  return RateSnapshot(date: _parseDate(root.getAttribute('Date')) ?? dayOnly(requestedDate), currencies: currencies);
}

String? _text(XmlElement parent, String tag) {
  final text = parent.getElement(tag)?.innerText.trim();
  return (text == null || text.isEmpty) ? null : text;
}

double? _number(XmlElement parent, String tag) {
  final text = _text(parent, tag);
  return text == null ? null : double.tryParse(text.replaceAll(',', '.'));
}

DateTime? _parseDate(String? value) {
  final match = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(value?.trim() ?? '');
  if (match == null) return null;
  return DateTime(int.parse(match.group(3)!), int.parse(match.group(2)!), int.parse(match.group(1)!));
}
