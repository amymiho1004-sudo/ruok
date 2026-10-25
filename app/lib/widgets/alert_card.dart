import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/strings.dart';
import '../models/alert_item.dart';

class AlertCard extends StatelessWidget {
  final AlertItem alert;

  /// When given, an acknowledge button is shown for unacknowledged alerts.
  final VoidCallback? onAcknowledge;

  const AlertCard({super.key, required this.alert, this.onAcknowledge});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconColor = alert.isUrgent ? Colors.red : Colors.orange;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(alert.isUrgent ? Icons.error_rounded : Icons.warning_rounded, color: iconColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(alert.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Chip(label: Text(alert.statusText), visualDensity: VisualDensity.compact),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.deviceLabel, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(alert.message),
            const SizedBox(height: 6),
            Text(
              '${formatDateTime(alert.createdAt)} · ${formatRelative(alert.createdAt)}',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            ),
            if (onAcknowledge != null && !alert.isAcknowledged) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onAcknowledge,
                icon: const Icon(Icons.check_rounded),
                label: Text(S.acknowledge),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
