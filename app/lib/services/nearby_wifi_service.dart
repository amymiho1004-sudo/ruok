import 'package:wifi_scan/wifi_scan.dart';

/// Lists nearby broadcasting Wi-Fi network names (SSID only — scan results
/// never include passwords). Requires location permission and location
/// services on Android, since WiFi scan results can reveal physical
/// location; this is a separate, more sensitive capability than the
/// permission-free hotspot auto-connect ([NativeWifi]).
class NearbyWifiService {
  /// Returns true if scanning is possible (permission granted, location on).
  static Future<bool> isAvailable() async {
    final canStart = await WiFiScan.instance.canStartScan(askPermissions: true);
    return canStart == CanStartScan.yes;
  }

  /// Scans and returns nearby SSIDs, strongest signal first, deduplicated.
  /// Returns an empty list if scanning isn't permitted/available.
  static Future<List<String>> scan() async {
    final canStart = await WiFiScan.instance.canStartScan(askPermissions: true);
    if (canStart == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      await Future.delayed(const Duration(seconds: 2));
    }

    final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
    if (canGet != CanGetScannedResults.yes) return const [];

    final results = await WiFiScan.instance.getScannedResults();
    final sorted = [...results]..sort((a, b) => b.level.compareTo(a.level));

    final seen = <String>{};
    final ssids = <String>[];
    for (final ap in sorted) {
      if (ap.ssid.isEmpty) continue;
      if (seen.add(ap.ssid)) ssids.add(ap.ssid);
    }
    return ssids;
  }
}
