/// Форматирование чисел и дат для интерфейса.
library;

import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0.00', 'ru');
final _rate = NumberFormat('#,##0.0000', 'ru');
final _date = DateFormat('dd.MM.yyyy');
final _shortDate = DateFormat('dd.MM');

String formatMoney(double value) => _money.format(value);

String formatRate(double value) => _rate.format(value);

String formatSigned(double value, {int digits = 4}) {
  final text = (digits == 2 ? _money : _rate).format(value.abs());
  return value > 0 ? '+$text' : (value < 0 ? '−$text' : text);
}

String formatPercent(double value) {
  final text = '${NumberFormat('0.00', 'ru').format(value.abs())} %';
  return value > 0 ? '+$text' : (value < 0 ? '−$text' : text);
}

String formatDate(DateTime value) => _date.format(value);

String formatShortDate(DateTime value) => _shortDate.format(value);
