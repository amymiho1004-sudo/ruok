import '../core/formatters.dart';

/// Result of `GET /api/devices/{id}/status` (also embedded as `computed`
/// in the device list).
class DeviceStatus {
  final String status;
  final String severity;
  final String reason;
  final String activeMode;
  final bool isSleepTime;
  final String? lastSeenAt;
  final String? lastMotionAt;
  final String? lastVoiceAt;
  final String? lastButtonAt;
  final int? lastSeenMinutes;
  final int? noReactionMinutes;
  final double? batteryLevel;
  final double? wifiStrength;

  const DeviceStatus({
    required this.status,
    required this.severity,
    required this.reason,
    required this.activeMode,
    required this.isSleepTime,
    this.lastSeenAt,
    this.lastMotionAt,
    this.lastVoiceAt,
    this.lastButtonAt,
    this.lastSeenMinutes,
    this.noReactionMinutes,
    this.batteryLevel,
    this.wifiStrength,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      status: (json['status'] ?? 'waiting').toString(),
      severity: (json['severity'] ?? 'info').toString(),
      reason: (json['reason'] ?? '').toString(),
      activeMode: (json['active_mode'] ?? 'home').toString(),
      isSleepTime: asBool(json['is_sleep_time']),
      lastSeenAt: json['last_seen_at']?.toString(),
      lastMotionAt: json['last_motion_at']?.toString(),
      lastVoiceAt: json['last_voice_at']?.toString(),
      lastButtonAt: json['last_button_at']?.toString(),
      lastSeenMinutes: json['last_seen_minutes'] is num ? (json['last_seen_minutes'] as num).toInt() : null,
      noReactionMinutes: json['no_reaction_minutes'] is num ? (json['no_reaction_minutes'] as num).toInt() : null,
      batteryLevel: asDouble(json['battery_level']),
      wifiStrength: asDouble(json['wifi_strength']),
    );
  }
}
