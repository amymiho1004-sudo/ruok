import '../core/formatters.dart';

class AlertRules {
  final int normalWarningMinutes;
  final int normalUrgentMinutes;
  final int sleepWarningMinutes;
  final int sleepUrgentMinutes;
  final int offlineMinutes;
  final bool enabled;

  const AlertRules({
    this.normalWarningMinutes = 180,
    this.normalUrgentMinutes = 360,
    this.sleepWarningMinutes = 720,
    this.sleepUrgentMinutes = 840,
    this.offlineMinutes = 30,
    this.enabled = true,
  });

  factory AlertRules.fromJson(Map<String, dynamic> json) {
    const d = AlertRules();
    return AlertRules(
      normalWarningMinutes: asInt(json['normal_warning_minutes'], d.normalWarningMinutes),
      normalUrgentMinutes: asInt(json['normal_urgent_minutes'], d.normalUrgentMinutes),
      sleepWarningMinutes: asInt(json['sleep_warning_minutes'], d.sleepWarningMinutes),
      sleepUrgentMinutes: asInt(json['sleep_urgent_minutes'], d.sleepUrgentMinutes),
      offlineMinutes: asInt(json['offline_minutes'], d.offlineMinutes),
      enabled: asBool(json['enabled'], fallback: true),
    );
  }

  Map<String, dynamic> toJson() => {
        'normal_warning_minutes': normalWarningMinutes,
        'normal_urgent_minutes': normalUrgentMinutes,
        'sleep_warning_minutes': sleepWarningMinutes,
        'sleep_urgent_minutes': sleepUrgentMinutes,
        'offline_minutes': offlineMinutes,
        'enabled': enabled,
      };
}
