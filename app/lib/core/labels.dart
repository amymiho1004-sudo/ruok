/// Display labels for server enum values.
library;

String statusLabel(String status) => switch (status) {
      'normal' => 'Normal',
      'sleeping' => 'Sleeping',
      'warning' => 'Warning',
      'urgent' => 'Urgent',
      'offline' => 'Offline',
      'away' => 'Away',
      'vacation' => 'Vacation',
      'pause' => 'Paused',
      'maintenance' => 'Maintenance',
      'waiting' => 'Waiting',
      'monitoring_disabled' => 'Alerts off',
      _ => status,
    };

String modeLabel(String mode) => switch (mode) {
      'home' => 'Home',
      'sleep' => 'Sleep',
      'away' => 'Away',
      'vacation' => 'Vacation',
      'pause' => 'Paused',
      'maintenance' => 'Maintenance',
      _ => mode,
    };

String alertStatusLabel(String status) => switch (status) {
      'pending' => 'Pending',
      'sent' => 'Sent',
      'acknowledged' => 'Acknowledged',
      'resolved' => 'Resolved',
      _ => status,
    };

String eventTypeLabel(String type) => switch (type) {
      'motion_detected' => 'Motion detected',
      'voice_detected' => 'Voice detected',
      'heartbeat' => 'Heartbeat',
      'button_pressed' => 'Button pressed',
      _ => type,
    };

/// Index 0 = Monday, matching the server's `days_of_week` (Python weekday).
const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
