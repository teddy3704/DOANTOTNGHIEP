/// One V2-N13 search hit.
class SearchHit {
  final String type, title;
  final String? subtitle, moodlePath;
  final int? courseId, userId, courseModuleId;
  const SearchHit({
    required this.type,
    required this.title,
    this.subtitle,
    this.courseId,
    this.userId,
    this.moodlePath,
    this.courseModuleId,
  });

  static int? _i(Object? v) => v is num ? v.toInt() : null;

  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
    type: j['type']?.toString() ?? '',
    title: j['title']?.toString() ?? '',
    subtitle: j['subtitle'] as String?,
    courseId: _i(j['courseId']),
    userId: _i(j['userId']),
    moodlePath: j['moodlePath'] as String?,
    courseModuleId: _i(j['courseModuleId']),
  );
}
