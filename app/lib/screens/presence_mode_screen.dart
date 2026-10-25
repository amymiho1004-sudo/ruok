import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/navigation.dart';
import '../core/strings.dart';
import '../models/presence_mode.dart';
import '../services/api_client.dart';
import '../widgets/async_body.dart';

/// One-tap presets shown on the screen.
class _Preset {
  final IconData icon;
  final String title;
  final String subtitle;
  final String mode;
  final Duration? duration;
  _Preset(this.icon, this.title, this.subtitle, this.mode, this.duration);
}

List<_Preset> _buildPresets() => [
      _Preset(Icons.home_rounded, S.backHome, S.backHomeHint, 'home', null),
      _Preset(Icons.directions_walk_rounded, S.away2h, S.away2hHint, 'away', const Duration(hours: 2)),
      _Preset(Icons.directions_car_rounded, S.away8h, S.away8hHint, 'away', const Duration(hours: 8)),
      _Preset(Icons.beach_access_rounded, S.vacation3d, S.vacation3dHint, 'vacation', const Duration(days: 3)),
      _Preset(Icons.pause_circle_rounded, S.pause1h, S.pause1hHint, 'pause', const Duration(hours: 1)),
    ];

class PresenceModeScreen extends StatefulWidget {
  final int deviceId;
  const PresenceModeScreen({super.key, required this.deviceId});

  @override
  State<PresenceModeScreen> createState() => _PresenceModeScreenState();
}

class _PresenceModeScreenState extends State<PresenceModeScreen> {
  final _api = ApiClient();
  final _note = TextEditingController();
  bool _busy = false;
  bool _loading = true;
  List<PresenceMode> _history = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      _history = await _api.presenceModes(widget.deviceId);
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _apply(_Preset preset) async {
    setState(() => _busy = true);
    try {
      final start = DateTime.now();
      final end = preset.duration == null ? null : start.add(preset.duration!);
      final note = _note.text.trim();
      await _api.setPresenceMode(
        deviceId: widget.deviceId,
        modeType: preset.mode,
        startAt: toServerTime(start),
        endAt: end == null ? null : toServerTime(end),
        note: note.isEmpty ? (preset.mode == 'home' ? S.backHome : null) : note,
      );
      if (!mounted) return;
      showSnack(context, S.applied(preset.title));
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Scaffold(
      appBar: AppBar(title: Text(S.presenceTitle)),
      body: AsyncBody(
        loading: _loading,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(S.presenceIntro, style: TextStyle(color: muted)),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: S.note),
            ),
            const SizedBox(height: 16),
            ..._buildPresets().map(_presetTile),
            const SizedBox(height: 20),
            Text(S.modeHistory, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_history.isEmpty)
              EmptyCard(S.noModeHistory)
            else
              ..._history.take(10).map((m) => Card(
                    child: ListTile(
                      leading: Icon(m.enabled ? Icons.radio_button_checked : Icons.radio_button_off, size: 20),
                      title: Text(m.modeText),
                      subtitle: Text(
                        '${formatDateTime(m.startAt)} ~ ${m.endAt == null ? S.noEnd : formatDateTime(m.endAt)}'
                        '${m.note == null || m.note!.isEmpty ? '' : '\n${m.note}'}',
                      ),
                      isThreeLine: m.note != null && m.note!.isNotEmpty,
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _presetTile(_Preset preset) {
    return Card(
      child: ListTile(
        enabled: !_busy,
        leading: Icon(preset.icon),
        title: Text(preset.title),
        subtitle: Text(preset.subtitle),
        trailing: _busy
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.chevron_right_rounded),
        onTap: _busy ? null : () => _apply(preset),
      ),
    );
  }
}
