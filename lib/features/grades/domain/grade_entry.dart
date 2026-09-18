class GradeEntry {
  const GradeEntry({
    required this.id,
    required this.courseId,
    required this.itemName,
    this.minimum,
    required this.maximum,
    required this.hidden,
    this.finalGrade,
    this.feedback,
  });

  final String id;
  final String courseId;
  final String itemName;
  final double? minimum;
  final double maximum;
  final bool hidden;
  final double? finalGrade;
  final String? feedback;

  double? get fraction {
    final value = finalGrade;
    final lowerBound = minimum;
    if (value == null || lowerBound == null) return null;
    final span = maximum - lowerBound;
    if (span <= 0) return null;
    return ((value - lowerBound) / span).clamp(0, 1);
  }
}
