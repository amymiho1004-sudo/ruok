import '../core/formatters.dart';

class SleepSchedule {
  final String startTime;
  final String endTime;
  final Set<int> daysOfWeek;
  final bool enabled;

  const SleepSchedule({
    this.startTime = '22:00',
    this.endTime = '07:00',
    this.daysOfWeek = const {0, 1, 2, 3, 4, 5, 6},
    this.enabled = true,
  });

  factory SleepSchedule.fromJson(Map<String, dynamic> json) {
    final days = (json['days_of_week']?.toString() ?? '0,1,2,3,4,5,6')
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
    return SleepSchedule(
      startTime: (json['start_time'] ?? '22:00').toString(),
      endTime: (json['end_time'] ?? '07:00').toString(),
      daysOfWeek: days,
      enabled: asBool(json['enabled'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'start_time': startTime,
        'end_time': endTime,
        'days_of_week': (daysOfWeek.toList()..sort()).join(','),
        'enabled': enabled,
      };
}
