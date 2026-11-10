import 'package:flutter/material.dart';

import '../../models/achievement.dart';
import '../../services/api_exception.dart';
import '../../services/api_service.dart';
import '../../widgets/learning_widgets.dart';

const _icons = {
  'on_time': Icons.task_alt,
  'review_streak': Icons.style,
  'plan_week': Icons.event_available,
  'minutes_300': Icons.timer,
  'goal': Icons.flag,
  'no_red': Icons.health_and_safety,
};

/// V2-N17 "Thành tích": own badges only (no leaderboard); achieved ones with the date when known,
/// the others with progress toward them.
class AchievementsScreen extends StatefulWidget {
  final ApiService api;
  const AchievementsScreen({super.key, required this.api});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  late Future<List<Achievement>> _future = widget.api.getAchievements();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thành tích')),
    body: FutureBuilder<List<Achievement>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data;
        if (snap.hasError || list == null) {
          return ListView(
            children: [
              EmptyState(
                apiErrorMessage(snap.error ?? ''),
                icon: Icons.cloud_off,
              ),
              Center(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _future = widget.api.getAchievements();
                  }),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ),
            ],
          );
        }
        final sorted = [
          ...list.where((a) => a.achieved),
          ...list.where((a) => !a.achieved),
        ];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Đã đạt ${list.where((a) => a.achieved).length}/${list.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final a in sorted) _BadgeTile(a),
          ],
        );
      },
    ),
  );
}

class _BadgeTile extends StatelessWidget {
  final Achievement a;
  const _BadgeTile(this.a);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final on = a.achievedOn;
    return Card(
      key: Key('badge-${a.key}'),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: a.achieved
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          child: Icon(
            _icons[a.key] ?? Icons.emoji_events,
            color: a.achieved ? scheme.primary : scheme.outline,
          ),
        ),
        title: Text(a.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.description),
            const SizedBox(height: 4),
            if (a.achieved)
              Text(
                on == null
                    ? 'Đã đạt'
                    : 'Đạt ngày ${on.day}/${on.month}/${on.year}',
                style: TextStyle(color: scheme.primary),
              )
            else ...[
              LinearProgressIndicator(value: a.ratio, minHeight: 6),
              const SizedBox(height: 2),
              Text('${a.progress}/${a.target}'),
            ],
          ],
        ),
        trailing: a.achieved
            ? Icon(Icons.emoji_events, color: scheme.primary)
            : null,
      ),
    );
  }
}

/// Analytics entry "Thành tích x/6"; hidden when the badges cannot load.
class AchievementsEntry extends StatefulWidget {
  final ApiService api;
  const AchievementsEntry({super.key, required this.api});

  @override
  State<AchievementsEntry> createState() => _AchievementsEntryState();
}

class _AchievementsEntryState extends State<AchievementsEntry> {
  late final Future<List<Achievement>?> _future = () async {
    try {
      return await widget.api.getAchievements();
    } catch (e) {
      debugPrint('Achievements: $e');
      return null;
    }
  }();

  @override
  Widget build(BuildContext context) => FutureBuilder<List<Achievement>?>(
    future: _future,
    builder: (context, snap) {
      final list = snap.data;
      if (list == null || list.isEmpty) return const SizedBox.shrink();
      final done = list.where((a) => a.achieved).length;
      return Card(
        key: const Key('achievements-entry'),
        child: ListTile(
          leading: const Icon(Icons.emoji_events_outlined),
          title: const Text('Thành tích'),
          subtitle: Text('Đã đạt $done/${list.length} huy hiệu'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AchievementsScreen(api: widget.api),
            ),
          ),
        ),
      );
    },
  );
}
