import 'package:flutter/services.dart';

/// Bridges to Android's WifiNetworkSpecifier API so the app can join the
/// device's setup hotspot automatically, without the user leaving the app
/// or granting location permission. Android 10+ only; returns false on
/// older versions or any failure so the caller can fall back to asking the
/// user to switch Wi-Fi manually in system settings.
class NativeWifi {
  static const _channel = MethodChannel('com.ruok.guardian/wifi');

  /// Attempts to join [ssid] with [password] and binds this app's network
  /// traffic to it. Returns true if connected within the timeout.
  static Future<bool> connect(String ssid, String password) async {
    try {
      final result = await _channel.invokeMethod<bool>('connect', {
        'ssid': ssid,
        'password': password,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Releases the network binding, letting the app's traffic return to the
  /// phone's normal default network (home Wi-Fi / cellular).
  static Future<void> release() async {
    try {
      await _channel.invokeMethod('release');
    } on PlatformException {
      // ignore
    } on MissingPluginException {
      // ignore
    }
  }
}
