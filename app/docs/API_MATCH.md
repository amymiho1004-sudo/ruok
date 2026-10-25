# Server API mapping

This Flutter app is matched to the Python server API paths below.

```text
GET  /api/health
POST /api/auth/register
POST /api/auth/login
GET  /api/devices
POST /api/devices
GET  /api/devices/{device_id}/status
GET  /api/devices/{device_id}/events
GET  /api/devices/{device_id}/sleep-schedule
POST /api/devices/{device_id}/sleep-schedule
GET  /api/devices/{device_id}/presence-modes
POST /api/devices/{device_id}/presence-mode
GET  /api/devices/{device_id}/alert-rules
POST /api/devices/{device_id}/alert-rules
GET  /api/alerts
POST /api/alerts/{alert_id}/acknowledge
```
