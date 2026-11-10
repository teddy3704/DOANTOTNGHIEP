import 'package:flutter/material.dart';

import '../../core/reminder_schedule.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../services/reminder_service.dart';
import '../../widgets/learning_widgets.dart';

String _hm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String _when(DateTime d) => '${_hm(d)} · ${d.day}/${d.month}';

/// V2-N7 "Cài đặt nhắc": every change is saved and the phone reminders are rescheduled at once.
class ReminderSettingsScreen extends StatefulWidget {
  final ApiService api;
  final ReminderService reminders;
  const ReminderSettingsScreen({
    super.key,
    required this.api,
    required this.reminders,
  });

  @override
  State<ReminderSettingsScreen> createState() => _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen>
    with WidgetsBindingObserver {
  ReminderPrefs? _prefs;
  ReminderStatus? _status;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Back from the system settings: show the permission as it is now.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _prefs != null && !_saving) {
      _refreshStatus();
    }
  }

  Future<void> _refreshStatus() async {
    try {
      final status = await widget.reminders.reschedule(
        widget.api,
        prefs: _prefs,
        askPermission: false,
      );
      if (!mounted) return;
      setState(() => _status = status);
      // Allowed in the system settings: the earlier "not allowed" message is no longer true.
      if (status.permitted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    } catch (_) {}
  }

  Future<void> _openSettings() async {
    try {
      await widget.reminders.openSettings();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy mở Cài đặt > Ứng dụng > Thông báo')),
      );
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final prefs = await widget.reminders.loadPrefs(widget.api);
      if (!mounted) return;
      setState(() => _prefs = prefs);
      final status = await widget.reminders.reschedule(
        widget.api,
        prefs: prefs,
        askPermission: false,
      );
      if (mounted) setState(() => _status = status);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _update(ReminderPrefs next) async {
    final before = _prefs;
    setState(() {
      _prefs = next;
      _saving = true;
    });
    try {
      final status = await widget.reminders.save(widget.api, next);
      if (!mounted) return;
      setState(() {
        _prefs = status.prefs;
        _status = status;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = before);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(ReminderPrefs p) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: p.dailyMinute ~/ 60,
        minute: p.dailyMinute % 60,
      ),
    );
    if (picked != null) {
      await _update(p.copyWith(dailyMinute: picked.hour * 60 + picked.minute));
    }
  }

  Future<void> _sendTest() async {
    try {
      final sent = await widget.reminders.sendTest();
      if (!mounted) return;
      if (!sent) {
        await _refreshStatus();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ứng dụng chưa được phép gửi thông báo'),
            action: SnackBarAction(
              label: 'Mở cài đặt',
              onPressed: _openSettings,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã gửi thông báo thử')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không gửi được thông báo trên máy này')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Cài đặt nhắc')),
    body: _body(),
  );

  Widget _body() {
    final p = _prefs;
    if (p == null) {
      if (_error == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return ListView(
        children: [
          EmptyState(apiErrorMessage(_error!), icon: Icons.cloud_off),
          Center(
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ),
        ],
      );
    }
    final on = p.pushEnabled && !_saving;
    final status = _status;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SwitchListTile(
          key: const Key('pref-push'),
          title: const Text('Thông báo trên điện thoại'),
          value: p.pushEnabled,
          onChanged: _saving
              ? null
              : (v) => _update(p.copyWith(pushEnabled: v)),
        ),
        const Divider(),
        SwitchListTile(
          key: const Key('pref-assign'),
          title: const Text('Nhắc hạn nộp bài tập'),
          value: p.assignmentReminder,
          onChanged: on
              ? (v) => _update(p.copyWith(assignmentReminder: v))
              : null,
        ),
        SwitchListTile(
          key: const Key('pref-quiz'),
          title: const Text('Nhắc hạn bài kiểm tra'),
          value: p.quizReminder,
          onChanged: on ? (v) => _update(p.copyWith(quizReminder: v)) : null,
        ),
        ListTile(
          title: const Text('Nhắc trước hạn'),
          trailing: DropdownButton<int>(
            key: const Key('pref-hours'),
            value: ReminderPrefs.hourOptions.contains(p.reminderBeforeHours)
                ? p.reminderBeforeHours
                : null,
            hint: Text('${p.reminderBeforeHours} giờ'),
            items: [
              for (final h in ReminderPrefs.hourOptions)
                DropdownMenuItem(value: h, child: Text('$h giờ')),
            ],
            onChanged: on
                ? (h) => h == null
                      ? null
                      : _update(p.copyWith(reminderBeforeHours: h))
                : null,
          ),
        ),
        const Divider(),
        SwitchListTile(
          key: const Key('pref-learning'),
          title: const Text('Nhắc ôn thẻ và kế hoạch hằng ngày'),
          value: p.learningReminder,
          onChanged: on
              ? (v) => _update(p.copyWith(learningReminder: v))
              : null,
        ),
        ListTile(
          key: const Key('pref-daily-time'),
          enabled: on && p.learningReminder,
          title: const Text('Giờ nhắc hằng ngày'),
          trailing: Text(
            _hm(DateTime(0, 1, 1, p.dailyMinute ~/ 60, p.dailyMinute % 60)),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          onTap: () => _pickTime(p),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: OutlinedButton.icon(
            key: const Key('pref-test'),
            onPressed: _sendTest,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Gửi thử thông báo'),
          ),
        ),
        if (status != null) _Upcoming(status, onOpenSettings: _openSettings),
      ],
    );
  }
}

class _Upcoming extends StatelessWidget {
  final ReminderStatus status;
  final VoidCallback onOpenSettings;
  const _Upcoming(this.status, {required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final deadlines = status.plan.deadlines;
    final daily = status.plan.daily;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sắp nhắc', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (!status.permitted) ...[
            const Text(
              'Ứng dụng chưa được phép gửi thông báo. Bật lại trong Cài đặt '
              '> Thông báo của ứng dụng.',
              key: Key('reminder-no-permission'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('reminder-open-settings'),
              onPressed: onOpenSettings,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Mở cài đặt thông báo'),
            ),
          ] else if (!status.prefs.pushEnabled)
            const Text('Đã tắt thông báo')
          else ...[
            if (status.plan.upcomingDeadlines == 0)
              const Text(
                'Không có hạn nộp sắp tới',
                key: Key('reminder-no-deadline'),
              ),
            for (final r in deadlines.take(5))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.alarm),
                title: Text(r.title),
                subtitle: Text(_when(r.when)),
              ),
            if (deadlines.length > 5)
              Text('và ${deadlines.length - 5} nhắc hạn khác'),
            if (daily.isNotEmpty)
              ListTile(
                key: const Key('reminder-daily'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: const Icon(Icons.today),
                title: Text(daily.first.body),
                subtitle: Text(
                  '${_when(daily.first.when)}'
                  '${daily.length > 1 ? ' · ${daily.length} ngày tới' : ''}',
                ),
              ),
          ],
        ],
      ),
    );
  }
}
