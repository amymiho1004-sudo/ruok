import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../models/alert_item.dart';
import '../services/api_client.dart';
import '../widgets/alert_card.dart';
import '../widgets/async_body.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<AlertItem> _alerts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _alerts = await _api.alerts();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _acknowledge(AlertItem alert) async {
    try {
      await _api.acknowledgeAlert(alert.id);
      if (mounted) showSnack(context, S.acknowledged);
      await _load();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.alerts)),
      body: AsyncBody(
        loading: _loading,
        error: _error,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: _alerts.isEmpty
              ? [SizedBox(height: 100), EmptyCard(S.noAlerts)]
              : _alerts.map((a) => AlertCard(alert: a, onAcknowledge: () => _acknowledge(a))).toList(),
        ),
      ),
    );
  }
}
