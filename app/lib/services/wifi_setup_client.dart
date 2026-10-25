import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/strings.dart';
import 'api_client.dart';

/// Talks directly to a RUOK device's local Wi-Fi setup server, reachable only
/// while the phone is manually connected to the device's own setup hotspot.
/// Unlike [ApiClient], the base URL here is the hotspot's fixed gateway IP,
/// not the guardian server configured in [LocalStore].
class WifiSetupClient {
  WifiSetupClient({http.Client? client, this.baseUrl = 'http://10.42.0.1:8788'}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  static const _timeout = Duration(seconds: 8);

  Future<Map<String, dynamic>> _get(String path) async {
    http.Response response;
    try {
      response = await _client.get(Uri.parse('$baseUrl$path')).timeout(_timeout);
    } on TimeoutException {
      throw ApiException(S.errNoResponse);
    } on SocketException catch (e) {
      throw ApiException('${S.errCannotConnect}\n${e.message}');
    } on http.ClientException catch (e) {
      throw ApiException('${S.errCannotConnect}\n${e.message}');
    }
    return _decode(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw ApiException(S.errNoResponse);
    } on SocketException catch (e) {
      throw ApiException('${S.errCannotConnect}\n${e.message}');
    } on http.ClientException catch (e) {
      throw ApiException('${S.errCannotConnect}\n${e.message}');
    }
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    if (text.trim().isEmpty) return const <String, dynamic>{};
    try {
      return Map<String, dynamic>.from(jsonDecode(text) as Map);
    } catch (_) {
      return {'raw': text};
    }
  }

  /// Confirms the phone is currently talking to a RUOK device in setup mode.
  Future<String> checkStatus() async {
    final data = await _get('/status');
    return data['device_uid']?.toString() ?? '';
  }

  /// Sends the target Wi-Fi network's credentials to the device, optionally
  /// along with a freshly created device's registration (uid/token), so a
  /// brand new device can be fully set up in one step without ever needing
  /// its token typed or pasted in by hand.
  /// Returns true if the device accepted and connected successfully.
  Future<bool> sendWifiCredentials({
    required String ssid,
    required String password,
    String? serverUrl,
    String? deviceUid,
    String? deviceToken,
  }) async {
    final data = await _post('/provision', {
      'ssid': ssid,
      'password': password,
      if (serverUrl != null) 'server_url': serverUrl,
      if (deviceUid != null) 'device_uid': deviceUid,
      if (deviceToken != null) 'device_token': deviceToken,
    });
    return data['ok'] == true;
  }
}
