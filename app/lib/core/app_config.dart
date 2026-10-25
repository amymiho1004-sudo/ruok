/// Build-time configuration.
///
/// Override the default server URL at build time:
///   flutter run --dart-define=RUOK_BASE_URL=http://192.168.1.25:8787
class AppConfig {
  AppConfig._();

  /// Android emulator -> host PC. For a real phone, change it in Settings
  /// (or via `--dart-define`) to your PC's LAN IP.
  static const defaultBaseUrl = String.fromEnvironment(
    'RUOK_BASE_URL',
    defaultValue: 'http://10.0.2.2:8787',
  );

  static const requestTimeout = Duration(seconds: 12);
}
