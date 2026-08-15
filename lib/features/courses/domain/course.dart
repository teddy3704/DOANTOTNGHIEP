class Course {
  const Course({
    required this.id,
    required this.shortName,
    required this.fullName,
    required this.category,
    required this.accentIndex,
    this.summary,
    this.progress,
    this.nextActivity,
  });

  final String id;
  final String shortName;
  final String fullName;
  final String category;
  final int accentIndex;
  final String? summary;
  final double? progress;
  final String? nextActivity;
}
