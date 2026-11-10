double? _d(Object? v) => v is num ? v.toDouble() : null;
int _i(Object? v) => v is num ? v.toInt() : 0;

/// Pass-forecast bands; thresholds are documented in docs/FEATURES_V2.md.
enum PassBand {
  notFeasible('NOT_FEASIBLE', 'Không còn khả thi'),
  highRisk('HIGH_RISK', 'Nguy cơ cao'),
  effort('EFFORT', 'Cần cố gắng'),
  safe('SAFE', 'An toàn'),
  surePass('SURE_PASS', 'Đã chắc qua'),
  noData('NO_DATA', 'Chưa có bài tính điểm');

  final String code, label;
  const PassBand(this.code, this.label);

  static PassBand parse(Object? v) =>
      PassBand.values.firstWhere((b) => b.code == v, orElse: () => noData);

  /// One line explaining the band with the student's own number.
  String explain(double? need) => switch (this) {
    PassBand.surePass => 'Đã đủ điểm qua môn kể cả khi các bài còn lại được 0',
    PassBand.notFeasible => 'Kể cả 100% các bài còn lại vẫn chưa đủ qua môn',
    PassBand.noData => 'Khóa học chưa có bài tính điểm',
    _ =>
      need == null
          ? label
          : 'Cần trung bình ${need.toStringAsFixed(1).replaceAll('.', ',')}% ở các bài còn lại',
  };
}

class StudentPassForecast {
  final int userId;
  final String name;
  final String? studentCode;
  final PassBand band;
  final double? current, need, bestCase, worstCase;
  final int gradedCount, remainingCount;

  const StudentPassForecast({
    required this.userId,
    required this.name,
    required this.band,
    this.studentCode,
    this.current,
    this.need,
    this.bestCase,
    this.worstCase,
    this.gradedCount = 0,
    this.remainingCount = 0,
  });

  factory StudentPassForecast.fromJson(Map<String, dynamic> j) =>
      StudentPassForecast(
        userId: _i(j['userid']),
        name: j['fullname']?.toString() ?? 'Sinh viên',
        studentCode: j['student_code']?.toString(),
        band: PassBand.parse(j['band']),
        current: _d(j['current']),
        need: _d(j['need']),
        bestCase: _d(j['bestCase']),
        worstCase: _d(j['worstCase']),
        gradedCount: _i(j['gradedCount']),
        remainingCount: _i(j['remainingCount']),
      );
}

class ClassForecast {
  final double passPercent;
  final Map<PassBand, int> counts;
  final List<StudentPassForecast> students;

  const ClassForecast({
    required this.passPercent,
    required this.counts,
    required this.students,
  });

  factory ClassForecast.fromJson(Map<String, dynamic> j) {
    final raw = j['counts'] is Map ? j['counts'] as Map : const {};
    return ClassForecast(
      passPercent: _d(j['passPercent']) ?? 50,
      counts: {for (final b in PassBand.values) b: _i(raw[b.code])},
      students: (j['students'] is List ? j['students'] as List : const [])
          .whereType<Map<String, dynamic>>()
          .map(StudentPassForecast.fromJson)
          .toList(),
    );
  }
}
