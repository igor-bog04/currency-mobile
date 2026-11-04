/// Плашки состояния: офлайн, курс за другую дату, ошибка.
library;

import 'package:flutter/material.dart';

import '../theme.dart';

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.icon, required this.text, required this.color, this.action});

  factory StatusBanner.offline(String text, {VoidCallback? onRetry}) => StatusBanner(
        icon: Icons.cloud_off_rounded,
        text: text,
        color: AppColors.warning,
        action: onRetry == null ? null : TextButton(onPressed: onRetry, child: const Text('Обновить')),
      );

  factory StatusBanner.info(String text) =>
      StatusBanner(icon: Icons.info_outline_rounded, text: text, color: AppColors.accent);

  final IconData icon;
  final String text;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500))),
          ?action,
        ],
      ),
    );
  }
}

/// Полноэкранное сообщение об ошибке с кнопкой повтора.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry, this.icon = Icons.wifi_off_rounded});

  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(icon, size: 36, color: scheme.primary),
            ),
            const SizedBox(height: 20),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
