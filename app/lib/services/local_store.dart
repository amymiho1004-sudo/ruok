import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_config.dart';

/// Persisted user session + server address.
class LocalStore {
  LocalStore._();

  static const _baseUrlKey = 'server_base_url';
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';

  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String> getBaseUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_baseUrlKey) ?? AppConfig.defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String value) async {
    final prefs = await _prefs;
    await prefs.setString(_baseUrlKey, normalizeBaseUrl(value));
  }

  /// Trims whitespace and trailing slashes; adds `http://` when no scheme given.
  static String normalizeBaseUrl(String value) {
    var url = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (url.isNotEmpty && !url.contains('://')) url = 'http://$url';
    return url;
  }

  static Future<String?> getToken() async => (await _prefs).getString(_tokenKey);

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> saveSession({
    required String token,
    required String name,
    required String email,
  }) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userEmailKey, email);
  }

  static Future<({String? name, String? email})> getUser() async {
    final prefs = await _prefs;
    return (name: prefs.getString(_userNameKey), email: prefs.getString(_userEmailKey));
  }

  static Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}
