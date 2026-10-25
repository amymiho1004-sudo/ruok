import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../core/strings.dart';
import '../models/alert_item.dart';
import '../models/alert_rules.dart';
import '../models/created_device.dart';
import '../models/device.dart';
import '../models/device_status.dart';
import '../models/event_item.dart';
import '../models/presence_mode.dart';
import '../models/sleep_schedule.dart';
import 'local_store.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

/// Thin typed wrapper over the Python server REST API.
/// Paths are documented in `docs/API_MATCH.md`.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ---------------------------------------------------------------- transport

  Future<Uri> _uri(String path, [Map<String, String>? query]) async {
    final base = await LocalStore.getBaseUrl();
    final uri = Uri.parse('$base${path.startsWith('/') ? path : '/$path'}');
    return (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({required bool auth}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await LocalStore.getToken();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool auth = true,
    Map<String, String>? query,
  }) async {
    final uri = await _uri(path, query);
    final headers = await _headers(auth: auth);

    http.Response response;
    try {
      final future = switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'POST' => _client.post(uri, headers: headers, body: jsonEncode(body ?? const {})),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError('Unsupported method: $method'),
      };
      response = await future.timeout(AppConfig.requestTimeout);
    } on TimeoutException {
      throw ApiException(S.errNoResponse);
    } on SocketException catch (e) {
      throw ApiException('${S.errCannotConnect}\n${e.message}');
    } on http.ClientException catch (e) {
      throw ApiException('${S.errCannotConnect}\n${e.message}');
    }

    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data is Map ? data['detail'] : null;
      throw ApiException(
        detail?.toString() ?? 'Request failed: HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return data;
  }

  static dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    if (text.trim().isEmpty) return const <String, dynamic>{};
    try {
      return jsonDecode(text);
    } catch (_) {
      return {'raw': text};
    }
  }

  Future<Map<String, dynamic>> _get(String path, {bool auth = true, Map<String, String>? query}) async =>
      Map<String, dynamic>.from(await _send('GET', path, auth: auth, query: query) as Map);

  Future<Map<String, dynamic>> _post(String path, {Map<String, dynamic>? body, bool auth = true}) async =>
      Map<String, dynamic>.from(await _send('POST', path, body: body, auth: auth) as Map);

  static List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) fromJson) =>
      (raw as List? ?? const []).whereType<Map>().map((e) => fromJson(Map<String, dynamic>.from(e))).toList();

  // ------------------------------------------------------------------ health

  Future<Map<String, dynamic>> health() => _get('/api/health', auth: false);

  // -------------------------------------------------------------------- auth

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) =>
      _post('/api/auth/register', auth: false, body: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });

  Future<Map<String, dynamic>> login({required String email, required String password}) =>
      _post('/api/auth/login', auth: false, body: {'email': email, 'password': password});

  // ----------------------------------------------------------------- devices

  Future<List<Device>> devices() async => _list((await _get('/api/devices'))['devices'], Device.fromJson);

  Future<CreatedDevice> createDevice({required String name, String? location}) async =>
      CreatedDevice.fromJson(await _post('/api/devices', body: {
        'name': name,
        'location': location ?? 'Home',
        'family_name': 'My Family',
      }));

  Future<void> deleteDevice(int deviceId) => _send('DELETE', '/api/devices/$deviceId');

  Future<DeviceStatus> deviceStatus(int deviceId) async =>
      DeviceStatus.fromJson(await _get('/api/devices/$deviceId/status'));

  Future<List<EventItem>> deviceEvents(int deviceId, {int limit = 50}) async => _list(
        (await _get('/api/devices/$deviceId/events', query: {'limit': '$limit'}))['events'],
        EventItem.fromJson,
      );

  // ---------------------------------------------------------- sleep schedule

  Future<SleepSchedule?> sleepSchedule(int deviceId) async {
    final raw = (await _get('/api/devices/$deviceId/sleep-schedule'))['sleep_schedule'];
    return raw is Map ? SleepSchedule.fromJson(Map<String, dynamic>.from(raw)) : null;
  }

  Future<void> saveSleepSchedule(int deviceId, SleepSchedule schedule) =>
      _post('/api/devices/$deviceId/sleep-schedule', body: schedule.toJson());

  // ----------------------------------------------------------- presence mode

  Future<List<PresenceMode>> presenceModes(int deviceId) async =>
      _list((await _get('/api/devices/$deviceId/presence-modes'))['presence_modes'], PresenceMode.fromJson);

  Future<void> setPresenceMode({
    required int deviceId,
    required String modeType,
    required String startAt,
    String? endAt,
    String? note,
  }) =>
      _post('/api/devices/$deviceId/presence-mode', body: {
        'mode_type': modeType,
        'start_at': startAt,
        'end_at': endAt,
        'note': note,
        'enabled': true,
      });

  // ------------------------------------------------------------- alert rules

  Future<AlertRules?> alertRules(int deviceId) async {
    final raw = (await _get('/api/devices/$deviceId/alert-rules'))['alert_rules'];
    return raw is Map ? AlertRules.fromJson(Map<String, dynamic>.from(raw)) : null;
  }

  Future<void> saveAlertRules(int deviceId, AlertRules rules) =>
      _post('/api/devices/$deviceId/alert-rules', body: rules.toJson());

  // ------------------------------------------------------------------ alerts

  Future<List<AlertItem>> alerts() async => _list((await _get('/api/alerts'))['alerts'], AlertItem.fromJson);

  Future<void> acknowledgeAlert(int alertId) => _post('/api/alerts/$alertId/acknowledge');
}
