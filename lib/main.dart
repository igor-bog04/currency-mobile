/// Точка входа: собирает зависимости и запускает приложение.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'data/bnm_api.dart';
import 'data/rate_repository.dart';
import 'data/rate_store.dart';
import 'ui/app.dart';
import 'ui/history_controller.dart';
import 'ui/rates_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final supportDir = await getApplicationSupportDirectory();

  final repository = RateRepository(
    source: BnmApi(http.Client()),
    store: FileRateStore(Directory('${supportDir.path}${Platform.pathSeparator}rates')),
  );
  final rates = RatesController(repository)..load();

  runApp(CurrencyApp(
    rates: rates,
    week: HistoryController(repository, days: 7),
    month: HistoryController(repository, days: 30),
  ));
}
