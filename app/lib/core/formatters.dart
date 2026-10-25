/// Parsing / formatting helpers shared across screens.
library;

/// Server returns `1`/`0`, `true`/`false`, or `'1'` for booleans.
bool asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value.toString().toLowerCase();
  return text == '1' || text == 'true';
}

int asInt(dynamic value, int fallback) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

/// Server timestamps look like `2026-09-02T21:30:00` or `2026-09-02 21:30:00`.
DateTime? parseServerTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim().replaceFirst(' ', 'T'));
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `2026-09-02 21:30`, or `-` when missing.
String formatDateTime(String? raw) {
  final dt = parseServerTime(raw);
  if (dt == null) return raw == null || raw.isEmpty ? '-' : raw;
  return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
}

/// `just now`, `5 min ago`, `3 h ago`, `2 d ago`, or `-` when missing.
String formatRelative(String? raw, {DateTime? now}) {
  final dt = parseServerTime(raw);
  if (dt == null) return '-';
  final diff = (now ?? DateTime.now()).difference(dt);
  if (diff.isNegative || diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  return '${diff.inDays} d ago';
}

/// `HH:MM` for the server, from hour/minute.
String formatHourMinute(int hour, int minute) => '${_two(hour)}:${_two(minute)}';

/// Local ISO string without fraction, e.g. `2026-09-02T21:30:00`.
String toServerTime(DateTime dt) => dt.toIso8601String().split('.').first;
