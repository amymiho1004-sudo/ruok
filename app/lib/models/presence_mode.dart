import '../core/formatters.dart';
import '../core/labels.dart';

class PresenceMode {
  final int id;
  final String modeType;
  final String startAt;
  final String? endAt;
  final String? note;
  final bool enabled;

  const PresenceMode({
    required this.id,
    required this.modeType,
    required this.startAt,
    required this.enabled,
    this.endAt,
    this.note,
  });

  factory PresenceMode.fromJson(Map<String, dynamic> json) {
    return PresenceMode(
      id: (json['id'] as num).toInt(),
      modeType: (json['mode_type'] ?? '').toString(),
      startAt: (json['start_at'] ?? '').toString(),
      endAt: json['end_at']?.toString(),
      note: json['note']?.toString(),
      enabled: asBool(json['enabled'], fallback: true),
    );
  }

  String get modeText => modeLabel(modeType);
}
