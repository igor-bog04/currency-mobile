import 'package:currency_mobile/domain/models.dart';

/// Фрагмент реального ответа BNM за 04.11.2026 (RUB с номиналом 10 — для проверки Value / Nominal).
const bnmXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<ValCurs Date="04.11.2026" name="Official exchange rate">
  <Valute ID="47"><NumCode>978</NumCode><CharCode>EUR</CharCode><Nominal>1</Nominal><Name>Euro</Name><Value>20.1960</Value></Valute>
  <Valute ID="44"><NumCode>840</NumCode><CharCode>USD</CharCode><Nominal>1</Nominal><Name>US Dollar</Name><Value>18.0650</Value></Valute>
  <Valute ID="36"><NumCode>643</NumCode><CharCode>RUB</CharCode><Nominal>10</Nominal><Name>Russian Ruble</Name><Value>2.2500</Value></Valute>
</ValCurs>
''';

RateSnapshot snapshot(DateTime date, {double eur = 20.0, double usd = 18.0}) => RateSnapshot(
      date: date,
      currencies: [
        Currency(code: 'EUR', name: 'Euro', rateToMdl: eur),
        Currency(code: 'USD', name: 'US Dollar', rateToMdl: usd),
      ],
    );
