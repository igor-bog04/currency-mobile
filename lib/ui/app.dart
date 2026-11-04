/// Корневой виджет: тема, локализация и нижняя навигация.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'history_controller.dart';
import 'rates_controller.dart';
import 'screens/analytics_screen.dart';
import 'screens/converter_screen.dart';
import 'theme.dart';

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key, required this.rates, required this.week, required this.month});

  final RatesController rates;
  final HistoryController week;
  final HistoryController month;

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
      home: HomeShell(rates: rates, week: week, month: month),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.rates, required this.week, required this.month});

  final RatesController rates;
  final HistoryController week;
  final HistoryController month;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _titles = ['Конвертер валют', 'Динамика за неделю', 'Динамика за месяц'];

  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab], style: const TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _tab,
          children: [
            ConverterScreen(controller: widget.rates),
            // Экраны сравнения создаются при первом открытии вкладки — тогда же грузится история.
            _tab == 1 || widget.week.history != null
                ? AnalyticsScreen(rates: widget.rates, history: widget.week, periodName: 'неделю')
                : const SizedBox.shrink(),
            _tab == 2 || widget.month.history != null
                ? AnalyticsScreen(rates: widget.rates, history: widget.month, periodName: 'месяц')
                : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.currency_exchange_rounded), label: 'Конвертер'),
          NavigationDestination(icon: Icon(Icons.date_range_rounded), label: 'Неделя'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Месяц'),
        ],
      ),
    );
  }
}
