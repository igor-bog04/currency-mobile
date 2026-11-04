import 'dart:io';

import 'package:currency_mobile/data/bnm_api.dart';
import 'package:currency_mobile/data/bnm_parser.dart';
import 'package:currency_mobile/domain/errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'fixtures.dart';

void main() {
  final day = DateTime(2026, 11, 4);

  group('parseBnmXml', () {
    test('reads currencies, divides Value by Nominal and adds MDL', () {
      final snapshot = parseBnmXml(bnmXml, day);

      expect(snapshot.date, DateTime(2026, 11, 4));
      expect(snapshot.currencies.keys, containsAll(['MDL', 'EUR', 'USD', 'RUB']));
      expect(snapshot.currencies['EUR']!.rateToMdl, 20.196);
      expect(snapshot.currencies['RUB']!.rateToMdl, closeTo(0.225, 1e-9));
      expect(snapshot.currencies['MDL']!.rateToMdl, 1);
    });

    test('empty body means no rates for date', () {
      expect(() => parseBnmXml('  ', day), throwsA(isA<NoRatesForDateException>()));
    });

    test('ValCurs without Valute means no rates for date', () {
      expect(() => parseBnmXml('<ValCurs Date="04.11.2026"/>', day), throwsA(isA<NoRatesForDateException>()));
    });

    test('malformed XML means source unavailable', () {
      expect(() => parseBnmXml('<ValCurs><Valute>', day), throwsA(isA<SourceUnavailableException>()));
    });

    test('unexpected root element means source unavailable', () {
      expect(() => parseBnmXml('<html><body>Maintenance</body></html>', day),
          throwsA(isA<SourceUnavailableException>()));
    });

    test('skips entries with missing or non-numeric values', () {
      const xml = '<ValCurs Date="04.11.2026">'
          '<Valute><CharCode>EUR</CharCode><Nominal>1</Nominal><Name>Euro</Name><Value>20.19</Value></Valute>'
          '<Valute><CharCode>XXX</CharCode><Nominal>1</Nominal><Name>Broken</Name><Value>n/a</Value></Valute>'
          '<Valute><CharCode>YYY</CharCode><Name>No nominal</Name><Value>1</Value></Valute>'
          '</ValCurs>';

      expect(parseBnmXml(xml, day).currencies.keys, unorderedEquals(['MDL', 'EUR']));
    });
  });

  group('BnmApi', () {
    test('requests the documented URL with DD.MM.YYYY date', () async {
      Uri? requested;
      final api = BnmApi(MockClient((request) async {
        requested = request.url;
        return http.Response(bnmXml, 200);
      }));

      await api.fetch(DateTime(2026, 3, 7));

      expect(requested.toString(), 'https://www.bnm.md/en/official_exchange_rates?get_xml=1&date=07.03.2026');
    });

    test('HTTP 404 means no rates for date', () {
      final api = BnmApi(MockClient((_) async => http.Response('Not found', 404)));
      expect(api.fetch(day), throwsA(isA<NoRatesForDateException>()));
    });

    test('HTTP 500 means source unavailable', () {
      final api = BnmApi(MockClient((_) async => http.Response('Error', 500)));
      expect(api.fetch(day), throwsA(isA<SourceUnavailableException>()));
    });

    test('no network means source unavailable', () {
      final api = BnmApi(MockClient((_) async => throw const SocketException('offline')));
      expect(api.fetch(day), throwsA(isA<SourceUnavailableException>()));
    });

    test('timeout means source unavailable', () {
      final api = BnmApi(
        MockClient((_) => Future.delayed(const Duration(seconds: 1), () => http.Response(bnmXml, 200))),
        timeout: const Duration(milliseconds: 10),
      );
      expect(api.fetch(day), throwsA(isA<SourceUnavailableException>()));
    });
  });
}
