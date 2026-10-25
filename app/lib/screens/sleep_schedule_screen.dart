import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../core/labels.dart';
import '../core/navigation.dart';
import '../core/strings.dart';
import '../models/sleep_schedule.dart';
import '../services/api_client.dart';
import '../widgets/async_body.dart';
import '../widgets/busy_icon.dart';

class SleepScheduleScreen extends StatefulWidget {
  final int deviceId;
  const SleepScheduleScreen({super.key, required this.deviceId});

  @override
  State<SleepScheduleScreen> createState() => _SleepScheduleScreenState();
}

class _SleepScheduleScreenState extends State<SleepScheduleScreen> {
  final _api = ApiClient();
  bool _loading = true;
  bool _saving = false;
  SleepSchedule _schedule = const SleepSchedule();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final loaded = await _api.sleepSchedule(widget.deviceId);
      if (loaded != null) _schedule = loaded;
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.saveSleepSchedule(widget.deviceId, _schedule);
      if (!mounted) return;
      showSnack(context, S.sleepSaved);
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _update({String? startTime, String? endTime, Set<int>? days, bool? enabled}) {
    setState(() {
      _schedule = SleepSchedule(
        startTime: startTime ?? _schedule.startTime,
        endTime: endTime ?? _schedule.endTime,
        daysOfWeek: days ?? _schedule.daysOfWeek,
        enabled: enabled ?? _schedule.enabled,
      );
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final current = _parse(start ? _schedule.startTime : _schedule.endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: start ? S.bedtime : S.wakeTime,
    );
    if (picked == null) return;
    final text = formatHourMinute(picked.hour, picked.minute);
    start ? _update(startTime: text) : _update(endTime: text);
  }

  static TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 22,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.sleepTitle)),
      body: AsyncBody(
        loading: _loading,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              value: _schedule.enabled,
              onChanged: (v) => _update(enabled: v),
              title: Text(S.useSleep),
              subtitle: Text(S.useSleepHint),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _timeTile(S.bedtime, _schedule.startTime, () => _pickTime(start: true))),
                const SizedBox(width: 12),
                Expanded(child: _timeTile(S.wakeTime, _schedule.endTime, () => _pickTime(start: false))),
              ],
            ),
            const SizedBox(height: 20),
            Text(S.repeatDays, style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: List.generate(weekdayLabels.length, (i) {
                return FilterChip(
                  label: Text(weekdayLabels[i]),
                  selected: _schedule.daysOfWeek.contains(i),
                  onSelected: (selected) {
                    final days = Set<int>.from(_schedule.daysOfWeek);
                    selected ? days.add(i) : days.remove(i);
                    _update(days: days);
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: BusyIcon(busy: _saving, icon: Icons.save_rounded),
              label: Text(S.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeTile(String label, String value, VoidCallback onTap) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
