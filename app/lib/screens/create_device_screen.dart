import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/navigation.dart';
import '../core/strings.dart';
import '../models/created_device.dart';
import '../services/api_client.dart';
import '../widgets/async_body.dart';
import '../widgets/busy_icon.dart';
import 'wifi_setup_screen.dart';

class CreateDeviceScreen extends StatefulWidget {
  const CreateDeviceScreen({super.key});

  @override
  State<CreateDeviceScreen> createState() => _CreateDeviceScreenState();
}

class _CreateDeviceScreenState extends State<CreateDeviceScreen> {
  final _api = ApiClient();
  final _name = TextEditingController(text: S.deviceNameDefault);
  final _location = TextEditingController(text: S.locationDefault);
  bool _busy = false;
  CreatedDevice? _created;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final created = await _api.createDevice(
        name: _name.text.trim().isEmpty ? 'Home Device' : _name.text.trim(),
        location: _location.text.trim().isEmpty ? S.locationDefault : _location.text.trim(),
      );
      if (mounted) setState(() => _created = created);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) showSnack(context, '$label ${S.copied}');
  }

  @override
  Widget build(BuildContext context) {
    final created = _created;
    return Scaffold(
      appBar: AppBar(title: Text(S.addDevice)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: created == null ? _form() : _result(created),
      ),
    );
  }

  List<Widget> _form() => [
        Text(S.createDeviceIntro),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: S.deviceName),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(labelText: S.location),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _busy ? null : _create,
          icon: BusyIcon(busy: _busy, icon: Icons.add_box_rounded),
          label: Text(S.createDevice),
        ),
      ];

  List<Widget> _result(CreatedDevice created) => [
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 54),
        const SizedBox(height: 12),
        Text(S.deviceCreated,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        _CopyCard(label: 'device_uid', value: created.deviceUid, onCopy: () => _copy('device_uid', created.deviceUid)),
        _CopyCard(
            label: 'device_token', value: created.deviceToken, onCopy: () => _copy('device_token', created.deviceToken)),
        const SizedBox(height: 12),
        Card(child: Padding(padding: EdgeInsets.all(18), child: Text(S.tokenOnce))),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push(WifiSetupScreen(deviceUid: created.deviceUid, deviceToken: created.deviceToken)),
          icon: const Icon(Icons.wifi_rounded),
          label: Text(S.wifiSetupEntryLabel),
        ),
        const SizedBox(height: 12),
        FilledButton(onPressed: () => context.pop(), child: Text(S.backToDashboard)),
      ];
}

class _CopyCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  const _CopyCard({required this.label, required this.value, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SelectableText(value, style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: onCopy, icon: Icon(Icons.copy_rounded), label: Text(S.copy)),
          ],
        ),
      ),
    );
  }
}
