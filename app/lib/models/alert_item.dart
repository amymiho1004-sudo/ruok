import '../core/labels.dart';

class AlertItem {
  final int id;
  final int deviceId;
  final String? deviceName;
  final String title;
  final String message;
  final String severity;
  final String status;
  final String createdAt;

  const AlertItem({
    required this.id,
    required this.deviceId,
    required this.title,
    required this.message,
    required this.severity,
    required this.status,
    required this.createdAt,
    this.deviceName,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    return AlertItem(
      id: (json['id'] as num).toInt(),
      deviceId: (json['device_id'] as num).toInt(),
      deviceName: json['device_name']?.toString(),
      title: (json['title'] ?? 'Status check needed').toString(),
      message: (json['message'] ?? '').toString(),
      severity: (json['severity'] ?? 'info').toString(),
      status: (json['status'] ?? 'pending').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }

  bool get isUrgent => severity == 'urgent';
  bool get isAcknowledged => status == 'acknowledged' || status == 'resolved';
  String get statusText => alertStatusLabel(status);
  String get deviceLabel => deviceName ?? 'Device $deviceId';
}
