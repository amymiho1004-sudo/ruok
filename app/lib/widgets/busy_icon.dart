import 'package:flutter/material.dart';

/// Button icon that turns into a small spinner while [busy].
class BusyIcon extends StatelessWidget {
  final bool busy;
  final IconData icon;
  const BusyIcon({super.key, required this.busy, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (!busy) return Icon(icon);
    return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
  }
}
