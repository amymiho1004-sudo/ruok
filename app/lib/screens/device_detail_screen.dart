import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/labels.dart';
import '../core/navigation.dart';
import '../core/strings.dart';
import '../models/device.dart';
import '../models/device_status.dart';
import '../models/event_item.dart';
import '../services/api_client.dart';
import '../widgets/async_body.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';
import 'alert_rules_screen.dart';
import 'presence_mode_screen.dart';
import 'sleep_schedule_screen.dart';
import 'wifi_setup_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  DeviceStatus? _status;
  List<EventItem> _events = const [];

  bool _deleting = false;

  int get _deviceId => widget.device.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.deleteDevice),
        content: Text(S.deleteDeviceConfirm(widget.device.name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _delete();
  }

  Future<void> _delete() async {
    setState(() => _deleting = true);
    try {
      await _api.deleteDevice(_deviceId);
      if (mounted) {
        showSnack(context, S.deleteDeviceDone);
        context.pop();
      }
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([_api.deviceStatus(_deviceId), _api.deviceEvents(_deviceId)]);
      _status = results[0] as DeviceStatus;
      _events = results[1] as List<EventItem>;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openAndReload(Widget page) async {
    await context.push(page);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final statusKey = status?.status ?? 'waiting';
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.name),
        actions: [
          IconButton(tooltip: S.refresh, onPressed: _load, icon: Icon(Icons.refresh_rounded)),
          IconButton(
            tooltip: S.deleteDevice,
            onPressed: _deleting ? null : _confirmDelete,
            icon: _deleting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: AsyncBody(
        loading: _loading,
        error: _error,
        loadingMessage: S.loadingDevice,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.device.deviceUid, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(widget.device.locationText),
                            ],
                          ),
                        ),
                        StatusBadge(status: statusKey, label: statusLabel(statusKey)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(status?.reason ?? ''),
                    const Divider(height: 28),
                    InfoRow(S.currentMode, modeLabel(status?.activeMode ?? 'home')),
                    InfoRow(S.lastSeen, _when(status?.lastSeenAt)),
                    InfoRow(S.lastMotion, _when(status?.lastMotionAt)),
                    InfoRow(S.lastVoice, _when(status?.lastVoiceAt)),
                    InfoRow(S.noReaction,
                        status?.noReactionMinutes == null ? S.notSet : '${status!.noReactionMinutes} ${S.minutes}'),
                    InfoRow(S.battery, status?.batteryLevel == null ? S.notSet : '${status!.batteryLevel!.round()}%'),
                    InfoRow(S.wifi, status?.wifiStrength == null ? S.notSet : '${status!.wifiStrength!.round()} dBm'),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _actionTile(Icons.bedtime_rounded, S.sleepSchedule, S.sleepScheduleHint,
                        () => _openAndReload(SleepScheduleScreen(deviceId: _deviceId))),
                    _actionTile(Icons.directions_walk_rounded, S.presenceMode, S.presenceModeHint,
                        () => _openAndReload(PresenceModeScreen(deviceId: _deviceId))),
                    _actionTile(Icons.tune_rounded, S.alertRules, S.alertRulesHint,
                        () => _openAndReload(AlertRulesScreen(deviceId: _deviceId))),
                    _actionTile(Icons.wifi_rounded, S.wifiSetupEntryLabel, S.wifiSetupEntryHint,
                        () => context.push(WifiSetupScreen(deviceUid: widget.device.deviceUid))),
                  ],
                ),
              ),
            ),
            SectionTitle(S.recentEvents),
            if (_events.isEmpty)
              EmptyCard(S.noEvents)
            else
              ..._events.map((e) => Card(
                    child: ListTile(
                      leading: Icon(_eventIcon(e.eventType)),
                      title: Text(e.typeText),
                      subtitle: Text('${formatDateTime(e.createdAt)} · ${formatRelative(e.createdAt)}'),
                      trailing: e.detected == null ? null : Text(e.detected! ? S.detected : S.notDetected),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  static String _when(String? raw) => raw == null ? S.notSet : '${formatDateTime(raw)}\n${formatRelative(raw)}';

  static IconData _eventIcon(String type) => switch (type) {
        'motion_detected' => Icons.sensors_rounded,
        'voice_detected' => Icons.mic_rounded,
        'button_pressed' => Icons.touch_app_rounded,
        _ => Icons.favorite_rounded,
      };

  Widget _actionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
