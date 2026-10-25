import 'package:flutter/material.dart';

MaterialColor statusColor(String status) => switch (status) {
      'normal' || 'sleeping' => Colors.green,
      'warning' => Colors.orange,
      'urgent' || 'offline' => Colors.red,
      'away' || 'vacation' || 'pause' || 'maintenance' => Colors.blueGrey,
      _ => Colors.grey,
    };

class StatusBadge extends StatelessWidget {
  final String status;
  final String label;
  const StatusBadge({super.key, required this.status, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Text(label, style: TextStyle(color: color.shade700, fontWeight: FontWeight.w700)),
    );
  }
}
