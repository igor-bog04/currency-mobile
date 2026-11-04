/// Выбор валюты: кнопка с кодом и нижняя панель со списком и поиском.
library;

import 'package:flutter/material.dart';

import '../../domain/models.dart';

class CurrencyButton extends StatelessWidget {
  const CurrencyButton({super.key, required this.label, required this.currency, required this.onTap});

  final String label;
  final Currency? currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(currency?.code ?? '—', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                    Text(
                      currency?.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

Future<String?> pickCurrency(BuildContext context, List<Currency> currencies, String selected) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.8,
      child: _CurrencyList(currencies: currencies, selected: selected),
    ),
  );
}

class _CurrencyList extends StatefulWidget {
  const _CurrencyList({required this.currencies, required this.selected});

  final List<Currency> currencies;
  final String selected;

  @override
  State<_CurrencyList> createState() => _CurrencyListState();
}

class _CurrencyListState extends State<_CurrencyList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _query.toLowerCase();
    final items = widget.currencies
        .where((c) => c.code.toLowerCase().contains(query) || c.name.toLowerCase().contains(query))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: false,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Код или название'),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final currency = items[index];
              final selected = currency.code == widget.selected;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: scheme.primary.withValues(alpha: selected ? 1 : 0.12),
                  child: Text(
                    currency.code.substring(0, 2),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: selected ? scheme.onPrimary : scheme.primary,
                    ),
                  ),
                ),
                title: Text(currency.code, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(currency.name),
                trailing: selected ? Icon(Icons.check_rounded, color: scheme.primary) : null,
                onTap: () => Navigator.pop(context, currency.code),
              );
            },
          ),
        ),
      ],
    );
  }
}
