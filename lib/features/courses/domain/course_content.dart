enum CourseActivityKind {
  assignment,
  resource,
  quiz,
  folder,
  forum,
  attendance,
}

extension CourseActivityKindLabel on CourseActivityKind {
  String get label => switch (this) {
    CourseActivityKind.assignment => 'Bài tập',
    CourseActivityKind.resource => 'Tài liệu',
    CourseActivityKind.quiz => 'Bài kiểm tra',
    CourseActivityKind.folder => 'Thư mục tài liệu',
    CourseActivityKind.forum => 'Diễn đàn',
    CourseActivityKind.attendance => 'Điểm danh',
  };
}

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
