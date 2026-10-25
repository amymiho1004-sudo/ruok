import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/strings.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import '../widgets/async_body.dart';
import '../widgets/busy_icon.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _api = ApiClient();
  final _url = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    LocalStore.getBaseUrl().then((value) {
      if (mounted) setState(() => _url.text = value);
    });
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _saveAndTest() async {
    setState(() => _busy = true);
    try {
      await LocalStore.setBaseUrl(_url.text);
      _url.text = await LocalStore.getBaseUrl();
      final data = await _api.health();
      if (mounted) showSnack(context, S.connected(data['service']));
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resetDefault() async {
    await LocalStore.setBaseUrl(AppConfig.defaultBaseUrl);
    if (!mounted) return;
    setState(() => _url.text = AppConfig.defaultBaseUrl);
    showSnack(context, S.resetDone);
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(S.serverSettings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(S.emulatorHint(AppConfig.defaultBaseUrl), style: TextStyle(color: muted)),
          const SizedBox(height: 8),
          Text(S.phoneHint, style: TextStyle(color: muted)),
          const SizedBox(height: 20),
          TextField(
            controller: _url,
            keyboardType: TextInputType.url,
            autocorrect: false,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _busy ? null : _saveAndTest(),
            decoration: InputDecoration(labelText: S.serverAddress, hintText: S.serverAddressHint),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _busy ? null : _saveAndTest,
            icon: BusyIcon(busy: _busy, icon: Icons.wifi_tethering_rounded),
            label: Text(S.saveAndTest),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _busy ? null : _resetDefault, child: Text(S.resetDefault)),
        ],
      ),
    );
  }
}
