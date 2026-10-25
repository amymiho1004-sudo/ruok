/// Response of `POST /api/devices`. The token is only returned once.
class CreatedDevice {
  final int id;
  final String deviceUid;
  final String name;
  final String deviceToken;

  const CreatedDevice({
    required this.id,
    required this.deviceUid,
    required this.name,
    required this.deviceToken,
  });

  factory CreatedDevice.fromJson(Map<String, dynamic> json) {
    final device = Map<String, dynamic>.from(json['device'] as Map? ?? {});
    return CreatedDevice(
      id: (device['id'] as num?)?.toInt() ?? 0,
      deviceUid: (device['device_uid'] ?? '').toString(),
      name: (device['name'] ?? '').toString(),
      deviceToken: (json['device_token'] ?? '').toString(),
    );
  }
}
