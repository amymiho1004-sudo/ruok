import '../core/formatters.dart';
import '../core/labels.dart';

class EventItem {
  final int id;
  final String eventType;
  final bool? detected;
  final String createdAt;
  final String? valueText;
  final double? valueNumber;

  const EventItem({
    required this.id,
    required this.eventType,
    required this.createdAt,
    this.detected,
    this.valueText,
    this.valueNumber,
  });

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: (json['id'] as num).toInt(),
      eventType: (json['event_type'] ?? '').toString(),
      detected: json['detected'] == null ? null : asBool(json['detected']),
      createdAt: (json['created_at'] ?? '').toString(),
      valueText: json['value_text']?.toString(),
      valueNumber: asDouble(json['value_number']),
    );
  }

  String get typeText => eventTypeLabel(eventType);
}
