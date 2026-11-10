int _i(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
double? _d(dynamic v) => v is num ? v.toDouble() : null;

/// V2-N16 automatic flags of one quiz.
enum QuizFlag {
  tooHard('TOO_HARD', 'Quá khó'),
  manySkipped('MANY_SKIPPED', 'Nhiều sinh viên bỏ'),
  tooFast('TOO_FAST', 'Làm quá nhanh');

  final String code, label;
  const QuizFlag(this.code, this.label);

  static QuizFlag? parse(Object? v) =>
      QuizFlag.values.where((f) => f.code == v).firstOrNull;
}

class QuizInsight {
  final int quizId;
  final String name;
  final DateTime? close;
  final int timeLimitSeconds;
  final String? moodlePath;
  final int? courseModuleId;
  final int rosterSize, finished, attempted, notAttempted;
  final double? notAttemptedPercent, meanPercent;
  final int? medianSeconds;
  final List<int> histogram;
  final List<QuizFlag> flags;
  final List<int> notAttemptedUserIds;

  const QuizInsight({
    required this.quizId,
    required this.name,
    required this.rosterSize,
    required this.finished,
    required this.attempted,
    required this.notAttempted,
    required this.histogram,
    this.flags = const [],
    this.notAttemptedUserIds = const [],
    this.close,
    this.timeLimitSeconds = 0,
    this.moodlePath,
    this.courseModuleId,
    this.notAttemptedPercent,
    this.meanPercent,
    this.medianSeconds,
  });

  factory QuizInsight.fromJson(Map<String, dynamic> j) {
    final hist = j['histogram'] is List ? (j['histogram'] as List) : const [];
    return QuizInsight(
      quizId: _i(j['quizId']),
      name: j['name']?.toString() ?? 'Bài kiểm tra',
      close: j['timeClose'] is num
          ? DateTime.fromMillisecondsSinceEpoch(
              (j['timeClose'] as num).toInt() * 1000,
            )
          : null,
      timeLimitSeconds: _i(j['timeLimitSeconds']),
      moodlePath: j['moodlePath'] as String?,
      courseModuleId: j['courseModuleId'] is num
          ? (j['courseModuleId'] as num).toInt()
          : null,
      rosterSize: _i(j['rosterSize']),
      finished: _i(j['finished']),
      attempted: _i(j['attempted']),
      notAttempted: _i(j['notAttempted']),
      notAttemptedPercent: _d(j['notAttemptedPercent']),
      meanPercent: _d(j['meanPercent']),
      medianSeconds: j['medianSeconds'] is num
          ? (j['medianSeconds'] as num).toInt()
          : null,
      histogram: [
        for (var k = 0; k < 5; k++) k < hist.length ? _i(hist[k]) : 0,
      ],
      flags: [
        for (final f in (j['flags'] is List ? j['flags'] as List : const []))
          ?QuizFlag.parse(f),
      ],
      notAttemptedUserIds: [
        for (final id
            in (j['notAttemptedUserIds'] is List
                ? j['notAttemptedUserIds'] as List
                : const []))
          if (id is num) id.toInt(),
      ],
    );
  }
}

/// "12 phút 30 giây" style duration for the median time.
String durationText(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  if (m == 0) return '$s giây';
  return s == 0 ? '$m phút' : '$m phút $s giây';
}
