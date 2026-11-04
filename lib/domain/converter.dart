/// Конвертация суммы между валютами через MDL.
library;

import 'models.dart';

class Conversion {
  const Conversion({
    required this.amount,
    required this.from,
    required this.to,
    required this.result,
    required this.forwardRate,
    required this.reverseRate,
  });

  final double amount;
  final String from;
  final String to;
  final double result;

  /// 1 [from] = forwardRate [to]
  final double forwardRate;

  /// 1 [to] = reverseRate [from]
  final double reverseRate;
}

/// null — если одной из валют нет в снимке.
Conversion? convert(double amount, String from, String to, RateSnapshot snapshot) {
  final forward = snapshot.crossRate(from, to);
  final reverse = snapshot.crossRate(to, from);
  if (forward == null || reverse == null) return null;
  return Conversion(
    amount: amount,
    from: from,
    to: to,
    result: amount * forward,
    forwardRate: forward,
    reverseRate: reverse,
  );
}
