/// Экран сравнения: динамика курса пары за неделю или месяц.
library;

import 'package:flutter/material.dart';

import '../../domain/statistics.dart';
import '../format.dart';
import '../history_controller.dart';
import '../rates_controller.dart';
import '../theme.dart';
import '../widgets/currency_picker.dart';
import '../widgets/rate_chart.dart';
import '../widgets/status_banner.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key, required this.rates, required this.history, required this.periodName});

  final RatesController rates;
  final HistoryController history;

  /// «неделю» / «месяц» — для подписей.
  final String periodName;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.history.history == null) widget.history.load();
  }

  Future<void> _pick({required bool source}) async {
    final rates = widget.rates;
    final code = await pickCurrency(context, rates.currencies, source ? rates.from : rates.to);
    if (code != null) rates.setPair(from: source ? code : null, to: source ? null : code);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([widget.rates, widget.history]),
      builder: (context, _) {
        final controller = widget.history;
        final history = controller.history;
        final rates = widget.rates;

        if (history == null) {
          if (controller.error != null) return ErrorState(message: controller.error!, onRetry: controller.load);
          return _Loading(days: controller.days);
        }

        final points = history.pointsFor(rates.from, rates.to);
        final stats = PeriodStats.fromPoints(points);

        return RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (controller.loading) const LinearProgressIndicator(),
              _PairSelector(
                rates: rates,
                onPickSource: () => _pick(source: true),
                onPickTarget: () => _pick(source: false),
              ),
              const SizedBox(height: 12),
              if (history.offline) ...[
                StatusBanner.offline(
                  history.latestDate == null
                      ? 'Нет сети и нет сохранённых данных за этот период'
                      : 'Нет сети. Данные из кэша, актуальны на ${formatDate(history.latestDate!)}',
                  onRetry: controller.load,
                ),
                const SizedBox(height: 12),
              ],
              if (stats == null)
                _EmptyPeriod(periodName: widget.periodName, onRetry: controller.load)
              else ...[
                _SummaryCard(stats: stats, from: rates.from, to: rates.to, periodName: widget.periodName),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 16, 8),
                    child: SizedBox(
                      height: 220,
                      child: RateChart(points: points, color: _trendColor(stats.trend)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _StatsGrid(stats: stats),
                const SizedBox(height: 12),
                Text(
                  'Точек на графике: ${points.length} из ${history.requestedDays}. '
                  'Данные на ${formatDate(stats.last.date)} · источник: BNM',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Color _trendColor(Trend trend) => switch (trend) {
      Trend.up => AppColors.up,
      Trend.down => AppColors.down,
      Trend.flat => AppColors.flat,
    };

class _PairSelector extends StatelessWidget {
  const _PairSelector({required this.rates, required this.onPickSource, required this.onPickTarget});

  final RatesController rates;
  final VoidCallback onPickSource;
  final VoidCallback onPickTarget;

  @override
  Widget build(BuildContext context) {
    final currencies = rates.snapshot?.currencies;
    return Row(
      children: [
        Expanded(child: CurrencyButton(label: 'Валюта', currency: currencies?[rates.from], onTap: onPickSource)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: IconButton.filledTonal(
            tooltip: 'Поменять местами',
            onPressed: rates.swap,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
        ),
        Expanded(child: CurrencyButton(label: 'В валюте', currency: currencies?[rates.to], onTap: onPickTarget)),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.stats, required this.from, required this.to, required this.periodName});

  final PeriodStats stats;
  final String from;
  final String to;
  final String periodName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _trendColor(stats.trend);
    final (icon, label) = switch (stats.trend) {
      Trend.up => (Icons.trending_up_rounded, 'Рост'),
      Trend.down => (Icons.trending_down_rounded, 'Падение'),
      Trend.flat => (Icons.trending_flat_rounded, 'Без изменений'),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1 $from в $to', style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(formatRate(stats.last.value), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text('$label · ${formatPercent(stats.percentChange)}',
                          style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Text('за $periodName', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final changeColor = _trendColor(stats.trend);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.south_rounded,
                title: 'Минимум',
                value: formatRate(stats.min.value),
                caption: formatDate(stats.min.date),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.north_rounded,
                title: 'Максимум',
                value: formatRate(stats.max.value),
                caption: formatDate(stats.max.date),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.functions_rounded,
                title: 'Среднее',
                value: formatRate(stats.average),
                caption: 'за период',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.show_chart_rounded,
                title: 'Изменение',
                value: formatSigned(stats.absoluteChange),
                caption: formatPercent(stats.percentChange),
                valueColor: changeColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.title, required this.value, required this.caption, this.valueColor});

  final IconData icon;
  final String title;
  final String value;
  final String caption;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Text(title, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: valueColor)),
            ),
            const SizedBox(height: 2),
            Text(caption, style: TextStyle(fontSize: 12, color: valueColor ?? scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Загружаем курсы за $days дней…'),
        ],
      ),
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.periodName, required this.onRetry});

  final String periodName;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.query_stats_rounded, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text('Нет данных за $periodName для выбранной пары', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Загрузить снова')),
          ],
        ),
      ),
    );
  }
}
