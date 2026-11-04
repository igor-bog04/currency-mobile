/// Корневой виджет: тема, локализация и нижняя навигация.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'rates_controller.dart';
import 'screens/converter_screen.dart';
import 'theme.dart';

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, required this.rates});

  final RatesController rates;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Курсы BNM',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeShell(rates: rates),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.rates});

  final RatesController rates;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертер валют', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(child: ConverterScreen(controller: widget.rates)),
    );
  }
}
