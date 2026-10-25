import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/navigation.dart';
import '../core/strings.dart';
import '../models/alert_rules.dart';
import '../services/api_client.dart';
import '../widgets/async_body.dart';
import '../widgets/busy_icon.dart';

class AlertRulesScreen extends StatefulWidget {
  final int deviceId;
  const AlertRulesScreen({super.key, required this.deviceId});

  @override
  State<AlertRulesScreen> createState() => _AlertRulesScreenState();
}

class _AlertRulesScreenState extends State<AlertRulesScreen> {
  static const _defaults = AlertRules();

  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _normalWarning = TextEditingController();
  final _normalUrgent = TextEditingController();
  final _sleepWarning = TextEditingController();
  final _sleepUrgent = TextEditingController();
  final _offline = TextEditingController();
  bool _enabled = true;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _fill(_defaults);
    _load();
  }

  @override
  void dispose() {
    for (final c in [_normalWarning, _normalUrgent, _sleepWarning, _sleepUrgent, _offline]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(AlertRules rules) {
    _normalWarning.text = '${rules.normalWarningMinutes}';
    _normalUrgent.text = '${rules.normalUrgentMinutes}';
    _sleepWarning.text = '${rules.sleepWarningMinutes}';
    _sleepUrgent.text = '${rules.sleepUrgentMinutes}';
    _offline.text = '${rules.offlineMinutes}';
    _enabled = rules.enabled;
  }

  Future<void> _load() async {
    try {
      final rules = await _api.alertRules(widget.deviceId);
      if (rules != null) _fill(rules);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    int minutes(TextEditingController c, int fallback) => int.tryParse(c.text.trim()) ?? fallback;
    setState(() => _saving = true);
    try {
      await _api.saveAlertRules(
        widget.deviceId,
        AlertRules(
          normalWarningMinutes: minutes(_normalWarning, _defaults.normalWarningMinutes),
          normalUrgentMinutes: minutes(_normalUrgent, _defaults.normalUrgentMinutes),
          sleepWarningMinutes: minutes(_sleepWarning, _defaults.sleepWarningMinutes),
          sleepUrgentMinutes: minutes(_sleepUrgent, _defaults.sleepUrgentMinutes),
          offlineMinutes: minutes(_offline, _defaults.offlineMinutes),
          enabled: _enabled,
        ),
      );
      if (!mounted) return;
      showSnack(context, S.rulesSaved);
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.rulesTitle)),
      body: AsyncBody(
        loading: _loading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: Text(S.useRules),
              ),
              _MinutesField(controller: _normalWarning, label: S.normalWarning),
              _MinutesField(controller: _normalUrgent, label: S.normalUrgent),
              _MinutesField(controller: _sleepWarning, label: S.sleepWarning),
              _MinutesField(controller: _sleepUrgent, label: S.sleepUrgent),
              _MinutesField(controller: _offline, label: S.offlineThreshold),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: BusyIcon(busy: _saving, icon: Icons.save_rounded),
                label: Text(S.save),
              ),
              TextButton(
                onPressed: _saving ? null : () => setState(() => _fill(_defaults)),
                child: Text(S.resetDefaults),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinutesField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  const _MinutesField({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, suffixText: S.minutes),
        validator: (v) {
          final n = int.tryParse(v?.trim() ?? '');
          if (n == null || n <= 0) return S.minutesInvalid;
          return null;
        },
      ),
    );
  }
}
