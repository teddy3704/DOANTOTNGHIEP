class LearningEvent {
  const LearningEvent({
    required this.id,
    required this.courseId,
    required this.name,
    required this.startsAt,
    required this.eventType,
  });

  final String id;
  final String courseId;
  final String name;
  final DateTime startsAt;
  final String eventType;
}
