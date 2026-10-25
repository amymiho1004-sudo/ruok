import '../core/labels.dart';
import 'device_status.dart';

class Device {
  final int id;
  final String deviceUid;
  final String name;
  final String? location;
  final String? rawStatus;
  final String? lastSeenAt;
  final String? lastMotionAt;
  final String? lastVoiceAt;
  final DeviceStatus? computed;

  const Device({
    required this.id,
    required this.deviceUid,
    required this.name,
    this.location,
    this.rawStatus,
    this.lastSeenAt,
    this.lastMotionAt,
    this.lastVoiceAt,
    this.computed,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    final computed = json['computed'];
    return Device(
      id: (json['id'] as num).toInt(),
      deviceUid: (json['device_uid'] ?? '').toString(),
      name: (json['name'] ?? 'Home Device').toString(),
      location: json['location']?.toString(),
      rawStatus: json['status']?.toString(),
      lastSeenAt: json['last_seen_at']?.toString(),
      lastMotionAt: json['last_motion_at']?.toString(),
      lastVoiceAt: json['last_voice_at']?.toString(),
      computed: computed is Map ? DeviceStatus.fromJson(Map<String, dynamic>.from(computed)) : null,
    );
  }

  /// Server-side evaluated status wins over the stored column.
  String get statusKey => computed?.status ?? rawStatus ?? 'waiting';

  String get statusText => statusLabel(statusKey);

  String get locationText => (location == null || location!.isEmpty) ? 'Home' : location!;
}
