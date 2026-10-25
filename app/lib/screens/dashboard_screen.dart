import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/labels.dart';
import '../core/navigation.dart';
import '../core/strings.dart';
import '../models/alert_item.dart';
import '../models/device.dart';
import '../services/api_client.dart';
import '../services/local_store.dart';
import '../widgets/alert_card.dart';
import '../widgets/async_body.dart';
import '../widgets/info_row.dart';
import '../widgets/status_badge.dart';
import 'alerts_screen.dart';
import 'auth_screen.dart';
import 'create_device_screen.dart';
import 'device_detail_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiClient();
  bool _loading = true;
  String? _error;
  List<Device> _devices = const [];
  List<AlertItem> _alerts = const [];
  ({String? name, String? email}) _user = (name: null, email: null);

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
      final results = await Future.wait([LocalStore.getUser(), _api.devices(), _api.alerts()]);
      _user = results[0] as ({String? name, String? email});
      _devices = results[1] as List<Device>;
      _alerts = results[2] as List<AlertItem>;
    } on ApiException catch (e) {
      if (e.isUnauthorized) return _logout();
      _error = e.message;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await LocalStore.clearSession();
    if (mounted) context.resetTo(const AuthScreen());
  }

  Future<void> _openAndReload(Widget page) async {
    await context.push(page);
    if (mounted) _load();
  }

  int get _pendingAlerts => _alerts.where((a) => !a.isAcknowledged).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.dashboard),
        actions: [
          IconButton(tooltip: S.refresh, icon: Icon(Icons.refresh_rounded), onPressed: _load),
          PopupMenuButton<String>(
            onSelected: (value) => switch (value) {
              'settings' => _openAndReload(const SettingsScreen()),
              'logout' => _logout(),
              _ => null,
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'settings', child: Text(S.serverSettings)),
              PopupMenuItem(value: 'logout', child: Text(S.logout)),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAndReload(const CreateDeviceScreen()),
        icon: const Icon(Icons.add_rounded),
        label: Text(S.addDevice),
      ),
      body: AsyncBody(
        loading: _loading,
        error: _error,
        loadingMessage: S.loadingStatus,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 90),
          children: [
            _userCard(),
            if (_devices.isEmpty)
              EmptyCard(S.noDevices)
            else
              ..._devices.map((d) => _DeviceCard(device: d, onTap: () => _openAndReload(DeviceDetailScreen(device: d)))),
            SectionTitle(S.recentAlerts),
            if (_alerts.isEmpty)
              EmptyCard(S.noRecentAlerts)
            else
              ..._alerts.take(5).map((a) => AlertCard(alert: a)),
          ],
        ),
      ),
    );
  }

  Widget _userCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person_rounded)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_user.name?.isNotEmpty == true ? _user.name! : S.guardian,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(_user.email ?? ''),
                ],
              ),
            ),
            Badge.count(
              count: _pendingAlerts,
              isLabelVisible: _pendingAlerts > 0,
              child: IconButton(
                tooltip: S.alerts,
                icon: const Icon(Icons.notifications_rounded),
                onPressed: () => _openAndReload(const AlertsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;
  const _DeviceCard({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final computed = device.computed;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
                        Text(device.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        Text('${device.deviceUid} · ${device.locationText}', style: TextStyle(color: muted)),
                      ],
                    ),
                  ),
                  StatusBadge(status: device.statusKey, label: device.statusText),
                ],
              ),
              const SizedBox(height: 14),
              Text(computed?.reason ?? S.checkingStatus),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(Icons.home_rounded, modeLabel(computed?.activeMode ?? 'home')),
                  _chip(Icons.sensors_rounded,
                      '${S.motion} ${formatRelative(computed?.lastMotionAt ?? device.lastMotionAt)}'),
                  _chip(Icons.mic_rounded, '${S.voice} ${formatRelative(computed?.lastVoiceAt ?? device.lastVoiceAt)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text) => Chip(
        avatar: Icon(icon, size: 16),
        label: Text(text),
        visualDensity: VisualDensity.compact,
      );
}
