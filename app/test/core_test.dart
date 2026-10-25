import 'package:flutter_test/flutter_test.dart';
import 'package:ruok_guardian_app/core/formatters.dart';
import 'package:ruok_guardian_app/core/labels.dart';
import 'package:ruok_guardian_app/models/device.dart';
import 'package:ruok_guardian_app/models/sleep_schedule.dart';
import 'package:ruok_guardian_app/services/local_store.dart';

void main() {
  group('formatters', () {
    test('asBool accepts server 0/1, bool and string', () {
      expect(asBool(1), isTrue);
      expect(asBool(0), isFalse);
      expect(asBool(true), isTrue);
      expect(asBool('1'), isTrue);
      expect(asBool(null, fallback: true), isTrue);
    });

    test('formatDateTime handles both server time formats', () {
      expect(formatDateTime('2026-09-02T21:30:00'), '2026-09-02 21:30');
      expect(formatDateTime('2026-09-02 21:30:00'), '2026-09-02 21:30');
      expect(formatDateTime(null), '-');
    });

    test('formatRelative buckets by minutes/hours/days', () {
      final now = DateTime(2026, 9, 2, 12, 0);
      expect(formatRelative('2026-09-02T11:55:00', now: now), '5 min ago');
      expect(formatRelative('2026-09-02T09:00:00', now: now), '3 h ago');
      expect(formatRelative('2026-08-30T12:00:00', now: now), '3 d ago');
      expect(formatRelative(null, now: now), '-');
    });
  });

  group('labels', () {
    test('known statuses map to labels, unknown passes through', () {
      expect(statusLabel('urgent'), 'Urgent');
      expect(statusLabel('something_new'), 'something_new');
      expect(modeLabel('vacation'), 'Vacation');
      expect(alertStatusLabel('acknowledged'), 'Acknowledged');
    });
  });

  group('models', () {
    test('Device prefers computed status over stored column', () {
      final device = Device.fromJson({
        'id': 1,
        'device_uid': 'RUOK-ABC123',
        'name': 'Test',
        'status': 'online',
        'computed': {'status': 'warning', 'reason': 'x'},
      });
      expect(device.statusKey, 'warning');
      expect(device.statusText, 'Warning');
      expect(device.locationText, 'Home');
    });

    test('SleepSchedule round-trips days_of_week', () {
      final schedule =
          SleepSchedule.fromJson({'start_time': '23:00', 'end_time': '06:30', 'days_of_week': '0,2,4', 'enabled': 1});
      expect(schedule.daysOfWeek, {0, 2, 4});
      expect(schedule.toJson()['days_of_week'], '0,2,4');
      expect(schedule.enabled, isTrue);
    });
  });

  test('normalizeBaseUrl trims slashes and adds scheme', () {
    expect(LocalStore.normalizeBaseUrl(' 192.168.1.25:8787/ '), 'http://192.168.1.25:8787');
    expect(LocalStore.normalizeBaseUrl('http://10.0.2.2:8787//'), 'http://10.0.2.2:8787');
  });
}
