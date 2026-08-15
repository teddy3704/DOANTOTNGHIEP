enum CourseActivityKind { assignment, resource }

class CourseActivity {
  const CourseActivity({
    required this.id,
    required this.instanceId,
    required this.kind,
    required this.name,
    required this.visible,
    this.description,
    this.dueAt,
    this.statusLabel,
    this.fileName,
    this.mimeType,
    this.fileSize,
  });

  final String id;
  final String instanceId;
  final CourseActivityKind kind;
  final String name;
  final bool visible;
  final String? description;
  final DateTime? dueAt;
  final String? statusLabel;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
}

class CourseSection {
  const CourseSection({
    required this.id,
    required this.courseId,
    required this.number,
    required this.name,
    required this.activities,
    this.summary,
  });

  final String id;
  final String courseId;
  final int number;
  final String name;
  final String? summary;
  final List<CourseActivity> activities;
}
