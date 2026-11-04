/// HTTP-клиент официальных курсов BNM.
library;

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/errors.dart';
import '../domain/models.dart';
import 'bnm_parser.dart';

abstract interface class RateSource {
  /// Бросает [NoRatesForDateException] или [SourceUnavailableException].
  Future<RateSnapshot> fetch(DateTime date);
}

class BnmApi implements RateSource {
  BnmApi(this._client, {this.timeout = const Duration(seconds: 10)});

  final http.Client _client;
  final Duration timeout;

  static Uri urlFor(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return Uri.https('www.bnm.md', '/en/official_exchange_rates', {
      'get_xml': '1',
      'date': '$day.$month.${date.year}',
    });
  }

  @override
  Future<RateSnapshot> fetch(DateTime date) async {
    final http.Response response;
    try {
      response = await _client.get(urlFor(date)).timeout(timeout);
    } on TimeoutException {
      throw const SourceUnavailableException('Сервер BNM не ответил вовремя');
    } on SocketException {
      throw const SourceUnavailableException('Нет подключения к интернету');
    } on http.ClientException catch (error) {
      throw SourceUnavailableException('Ошибка сети: ${error.message}');
    }

    if (response.statusCode == 404) throw NoRatesForDateException(date);
    if (response.statusCode != 200) {
      throw SourceUnavailableException('Сервер BNM вернул код ${response.statusCode}');
    }
    return parseBnmXml(response.body, date);
  }
}
