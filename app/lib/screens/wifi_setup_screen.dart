import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/strings.dart';
import '../services/local_store.dart';
import '../services/native_wifi.dart';
import '../services/nearby_wifi_service.dart';
import '../services/wifi_setup_client.dart';
import '../widgets/async_body.dart';
import '../widgets/busy_icon.dart';
import 'qr_scan_screen.dart';

const _hotspotPassword = 'ruoksetup123';

class WifiSetupScreen extends StatefulWidget {
  /// The target device's uid, when known, used to predict its setup hotspot
  /// name (matches the device's own `RUOK-Setup-<uid suffix>` scheme) so the
  /// app can attempt to join it automatically.
  final String? deviceUid;

  /// Set only right after creating a brand new device, so its uid/token are
  /// sent to the device along with the Wi-Fi credentials and it's fully
  /// registered in one step. Left null when just reconfiguring an existing,
  /// already-registered device's Wi-Fi (its token isn't retrievable again).
  final String? deviceToken;

  const WifiSetupScreen({super.key, this.deviceUid, this.deviceToken});

  @override
  State<WifiSetupScreen> createState() => _WifiSetupScreenState();
}

class _WifiSetupScreenState extends State<WifiSetupScreen> {
  final _client = WifiSetupClient();
  final _ssid = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  bool _autoFailed = false;
  bool _connectedToDevice = false;
  String? _foundDeviceUid;
  bool? _submitResult;

  /// A brand new device (deviceToken set) has never saved a config.json, so
  /// it broadcasts the plain "RUOK-Setup" hotspot — it doesn't know its own
  /// uid yet at this point, since that's exactly what we're about to send it.
  /// Only an already-registered device (reconfiguring Wi-Fi only, no token)
  /// includes its uid suffix, since it already has that saved.
  String get _expectedHotspotSsid {
    final uid = widget.deviceUid;
    final isNewDevice = widget.deviceToken != null;
    if (isNewDevice || uid == null || uid.isEmpty) return 'RUOK-Setup';
    final suffix = uid.length >= 6 ? uid.substring(uid.length - 6) : uid;
    return 'RUOK-Setup-$suffix';
  }

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    NativeWifi.release();
    super.dispose();
  }

  Future<void> _tryAutoConnect() async {
    setState(() => _busy = true);
    // Android 13+ requires this before an app can join/scan for Wi-Fi networks,
    // even though WifiNetworkSpecifier itself needs no location permission.
    await Permission.nearbyWifiDevices.request();
    final joined = await NativeWifi.connect(_expectedHotspotSsid, _hotspotPassword);
    if (!joined) {
      if (mounted) setState(() => _autoFailed = true);
      if (mounted) setState(() => _busy = false);
      return;
    }
    await _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _busy = true);
    try {
      final deviceUid = await _client.checkStatus();
      if (mounted) {
        setState(() {
          _connectedToDevice = true;
          _foundDeviceUid = deviceUid;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _autoFailed = true);
        showSnack(context, S.wifiSetupNotFound);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.of(context).push<WifiQrResult>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (result == null) return;
    _ssid.text = result.ssid;
    _password.text = result.password;
    if (mounted) showSnack(context, result.ssid);
  }

  Future<void> _pickNearby() async {
    setState(() => _busy = true);
    final ssids = await NearbyWifiService.scan();
    if (mounted) setState(() => _busy = false);
    if (!mounted) return;

    if (ssids.isEmpty) {
      showSnack(context, S.wifiSetupNearbyUnavailable);
      return;
    }

    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(S.wifiSetupNearbyTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            for (final ssid in ssids)
              ListTile(
                leading: const Icon(Icons.wifi_rounded),
                title: Text(ssid),
                onTap: () => Navigator.of(context).pop(ssid),
              ),
          ],
        ),
      ),
    );
    if (chosen != null) _ssid.text = chosen;
  }

  Future<void> _submit() async {
    if (_ssid.text.trim().isEmpty) {
      showSnack(context, S.wifiSetupSsidRequired);
      return;
    }
    setState(() {
      _busy = true;
      _submitResult = null;
    });
    try {
      final deviceToken = widget.deviceToken;
      final serverUrl = deviceToken == null ? null : await LocalStore.getBaseUrl();
      final ok = await _client.sendWifiCredentials(
        ssid: _ssid.text.trim(),
        password: _password.text,
        serverUrl: serverUrl,
        deviceUid: deviceToken == null ? null : widget.deviceUid,
        deviceToken: deviceToken,
      );
      if (mounted) setState(() => _submitResult = ok);
      if (ok) await NativeWifi.release();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.wifiSetupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: _connectedToDevice ? _wifiForm() : _connectSteps(),
      ),
    );
  }

  List<Widget> _connectSteps() => [
        Text(S.wifiSetupStep1Title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 6),
        Text(S.wifiSetupStep1Body),
        const SizedBox(height: 20),
        Text(S.wifiSetupStep2Title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _busy ? null : _tryAutoConnect,
          icon: BusyIcon(busy: _busy, icon: Icons.bolt_rounded),
          label: Text(_busy ? S.wifiSetupAutoConnecting : S.wifiSetupAutoConnect),
        ),
        if (_autoFailed) ...[
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 8),
          Text(S.wifiSetupAutoFailed, style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(S.wifiSetupStep2Body(_hotspotPassword)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _busy ? null : _checkConnection,
            icon: BusyIcon(busy: _busy, icon: Icons.wifi_find_rounded),
            label: Text(S.wifiSetupConnected),
          ),
        ],
      ];

  List<Widget> _wifiForm() {
    final result = _submitResult;
    return [
      Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(S.wifiSetupFoundDevice(_foundDeviceUid ?? '-'))),
        ],
      ),
      const SizedBox(height: 20),
      Text(S.wifiSetupStep3Title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: _busy ? null : _scanQr,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text(S.wifiSetupScanQr),
          ),
          OutlinedButton.icon(
            onPressed: _busy ? null : _pickNearby,
            icon: const Icon(Icons.wifi_find_rounded),
            label: Text(S.wifiSetupPickNearby),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _ssid,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(labelText: S.wifiSetupSsid),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _password,
        textInputAction: TextInputAction.done,
        obscureText: true,
        decoration: InputDecoration(labelText: S.wifiSetupPassword),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _busy ? null : _submit,
        icon: BusyIcon(busy: _busy, icon: Icons.send_rounded),
        label: Text(S.wifiSetupSubmit),
      ),
      if (result != null) ...[
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(!result
                ? S.wifiSetupFailure
                : (widget.deviceToken != null ? S.wifiSetupProvisionSuccess : S.wifiSetupSuccess)),
          ),
        ),
      ],
    ];
  }
}
