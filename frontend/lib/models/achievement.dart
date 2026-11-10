/// V2-N17 badge from GET /dev/students/{id}/achievements.
class Achievement {
  final String key, title, description;
  final bool achieved;
  final DateTime? achievedOn;
  final int progress, target;

  const Achievement({
    required this.key,
    required this.title,
    required this.description,
    required this.achieved,
    required this.progress,
    required this.target,
    this.achievedOn,
  });

  static int _i(Object? v) => v is num ? v.toInt() : 0;

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
    key: j['key']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString() ?? '',
    achieved: j['achieved'] == true,
    achievedOn: j['achievedOn'] is String
        ? DateTime.tryParse(j['achievedOn'] as String)
        : null,
    progress: _i(j['progress']),
    target: _i(j['target']) == 0 ? 1 : _i(j['target']),
  );

  double get ratio => (progress / target).clamp(0, 1).toDouble();
}
