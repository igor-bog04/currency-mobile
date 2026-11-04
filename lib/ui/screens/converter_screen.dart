/// Экран конвертации суммы по официальному курсу BNM.
library;

import 'package:flutter/material.dart';

import '../../domain/amount_validator.dart';
import '../../domain/converter.dart';
import '../format.dart';
import '../rates_controller.dart';
import '../widgets/currency_picker.dart';
import '../widgets/status_banner.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key, required this.controller});

  final RatesController controller;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _amount = TextEditingController(text: '100');

  RatesController get _controller => widget.controller;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _controller.selectedDate,
      firstDate: DateTime(2000),
      lastDate: _controller.repository.today,
      helpText: 'Дата курса',
    );
    if (picked != null) await _controller.load(picked);
  }

  Future<void> _pick({required bool source}) async {
    final code = await pickCurrency(context, _controller.currencies, source ? _controller.from : _controller.to);
    if (code != null) _controller.setPair(from: source ? code : null, to: source ? null : code);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _amount]),
      builder: (context, _) {
        final result = _controller.result;
        if (result == null) {
          if (_controller.loading) return const Center(child: CircularProgressIndicator());
          return ErrorState(message: _controller.error ?? 'Курсы ещё не загружены', onRetry: _controller.load);
        }

        final validation = AmountValidator.validate(_amount.text);
        final conversion = validation.isValid
            ? convert(validation.value!, _controller.from, _controller.to, result.snapshot)
            : null;

        return RefreshIndicator(
          onRefresh: _controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (_controller.loading) const LinearProgressIndicator(),
              if (result.offline) ...[
                StatusBanner.offline(
                  'Нет сети. Показаны сохранённые курсы за ${formatDate(result.snapshot.date)}',
                  onRetry: _controller.load,
                ),
                const SizedBox(height: 12),
              ] else if (result.isFallbackDate) ...[
                StatusBanner.info(
                  'На ${formatDate(result.requestedDate)} курс не опубликован — '
                  'используется курс за ${formatDate(result.snapshot.date)}',
                ),
                const SizedBox(height: 12),
              ],
              _ResultCard(conversion: conversion, error: validation.error, date: result.snapshot.date),
              const SizedBox(height: 16),
              _InputCard(
                amount: _amount,
                error: validation.error,
                controller: _controller,
                onPickSource: () => _pick(source: true),
                onPickTarget: () => _pick(source: false),
                onPickDate: _pickDate,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.conversion, required this.error, required this.date});

  final Conversion? conversion;
  final String? error;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const onAccent = Colors.white;
    final muted = Colors.white.withValues(alpha: 0.75);
    final conversion = this.conversion;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [scheme.primary, Color.lerp(scheme.primary, const Color(0xFF7C3AED), 0.6)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conversion == null ? 'Результат' : '${formatMoney(conversion.amount)} ${conversion.from} =',
            style: TextStyle(color: muted, fontSize: 15),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              conversion == null ? '—' : '${formatMoney(conversion.result)} ${conversion.to}',
              style: const TextStyle(color: onAccent, fontSize: 34, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          if (conversion != null) ...[
            Text('1 ${conversion.from} = ${formatRate(conversion.forwardRate)} ${conversion.to}',
                style: const TextStyle(color: onAccent, fontWeight: FontWeight.w600)),
            Text('1 ${conversion.to} = ${formatRate(conversion.reverseRate)} ${conversion.from}',
                style: TextStyle(color: muted)),
          ] else
            Text(error ?? 'Выберите валюты', style: TextStyle(color: muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.account_balance_rounded, size: 16, color: muted),
              const SizedBox(width: 6),
              Text('Официальный курс BNM на ${formatDate(date)}', style: TextStyle(color: muted, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  const _InputCard({
    required this.amount,
    required this.error,
    required this.controller,
    required this.onPickSource,
    required this.onPickTarget,
    required this.onPickDate,
  });

  final TextEditingController amount;
  final String? error;
  final RatesController controller;
  final VoidCallback onPickSource;
  final VoidCallback onPickTarget;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final snapshot = controller.snapshot!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Сумма',
                errorText: error,
                errorMaxLines: 2,
                suffixText: controller.from,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CurrencyButton(
                    label: 'Из',
                    currency: snapshot.currencies[controller.from],
                    onTap: onPickSource,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton.filledTonal(
                    tooltip: 'Поменять местами',
                    onPressed: controller.swap,
                    icon: const Icon(Icons.swap_horiz_rounded),
                  ),
                ),
                Expanded(
                  child: CurrencyButton(
                    label: 'В',
                    currency: snapshot.currencies[controller.to],
                    onTap: onPickTarget,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: controller.loading ? null : onPickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              label: Text('Дата курса: ${formatDate(controller.selectedDate)}'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: scheme.outlineVariant),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
