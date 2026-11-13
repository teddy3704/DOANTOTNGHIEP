/// V3: DLU training-portal data as returned by the backend (never the Portal directly).
library;

import '../core/data_profile.dart';

double? _d(Object? v) => v is num ? v.toDouble() : null;
int? _i(Object? v) => v is num ? v.toInt() : null;
String? _s(Object? v) => v?.toString();
List<Map<String, dynamic>> _list(Object? v) => v is List
    ? v.whereType<Map<String, dynamic>>().toList()
    : const <Map<String, dynamic>>[];
List<String> _strings(Object? v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

/// "HK02" → "HK2".
String termLabel(String? termId) {
  if (termId == null) return '';
  final m = RegExp(r'(\d+)').firstMatch(termId);
  return m == null ? termId : 'HK${int.parse(m.group(1)!)}';
}

/// "2,87" style with [digits] decimals.
String vn(num? v, [int digits = 2]) =>
    v == null ? '—' : v.toStringAsFixed(digits).replaceAll('.', ',');

class DataUntil {
  final String yearStudy;
  final String termId;
  const DataUntil(this.yearStudy, this.termId);

  static DataUntil? fromJson(Object? j) => j is Map<String, dynamic>
      ? DataUntil(_s(j['yearStudy']) ?? '', _s(j['termId']) ?? '')
      : null;

  String get label => DataProfile.isReal
      // Real export: the student's own transcript file; the term is the text they typed.
      ? '${DataProfile.transcriptSource} · đến ${termLabel(termId)} $yearStudy'
      : 'Dữ liệu Portal đến ${termLabel(termId)} năm $yearStudy';
}

// ---------------------------------------------------------------- P1
class PortalSummary {
  final double? cumulativeGpa4;
  final double? cumulativeGpa10;
  final double? cumulativeCredits;
  final String? rank;
  final String? band;
  final int? remainingCompulsoryCredits;
  final DataUntil? dataUntil;

  const PortalSummary({
    this.cumulativeGpa4,
    this.cumulativeGpa10,
    this.cumulativeCredits,
    this.rank,
    this.band,
    this.remainingCompulsoryCredits,
    this.dataUntil,
  });

  factory PortalSummary.fromJson(Map<String, dynamic> j) => PortalSummary(
    cumulativeGpa4: _d(j['cumulativeGpa4']),
    cumulativeGpa10: _d(j['cumulativeGpa10']),
    cumulativeCredits: _d(j['cumulativeCredits']),
    rank: _s(j['rank']),
    band: _s(j['band']),
    remainingCompulsoryCredits: _i(j['remainingCompulsoryCredits']),
    dataUntil: DataUntil.fromJson(j['dataUntil']),
  );
}

class TranscriptCourse {
  final String? code;
  final String name;
  final int? credits;
  final double? score10;
  final double? score4;
  final String? letter;
  final bool scored;
  final bool passed;

  const TranscriptCourse({
    required this.name,
    this.code,
    this.credits,
    this.score10,
    this.score4,
    this.letter,
    this.scored = false,
    this.passed = false,
  });

  factory TranscriptCourse.fromJson(Map<String, dynamic> j) => TranscriptCourse(
    code: _s(j['code']),
    name: _s(j['name']) ?? 'Học phần',
    credits: _i(j['credits']),
    score10: _d(j['score10']),
    score4: _d(j['score4']),
    letter: _s(j['letter']),
    scored: j['scored'] == true,
    passed: j['passed'] == true,
  );

  bool get failed => scored && !passed;
}

class TranscriptTerm {
  final String yearStudy;
  final String termId;
  final double? gpa4;
  final double? gpa10;
  final double? cumulativeGpa4;
  final double? cumulativeCredits;
  final String? rank;
  final bool hasScores;
  final List<TranscriptCourse> courses;

  const TranscriptTerm({
    required this.yearStudy,
    required this.termId,
    required this.courses,
    this.gpa4,
    this.gpa10,
    this.cumulativeGpa4,
    this.cumulativeCredits,
    this.rank,
    this.hasScores = false,
  });

  factory TranscriptTerm.fromJson(Map<String, dynamic> j) => TranscriptTerm(
    yearStudy: _s(j['yearStudy']) ?? '',
    termId: _s(j['termId']) ?? '',
    gpa4: _d(j['gpa4']),
    gpa10: _d(j['gpa10']),
    cumulativeGpa4: _d(j['cumulativeGpa4']),
    cumulativeCredits: _d(j['cumulativeCredits']),
    rank: _s(j['rank']),
    hasScores: j['hasScores'] == true,
    courses: _list(j['courses']).map(TranscriptCourse.fromJson).toList(),
  );

  String get label => '${termLabel(termId)} · $yearStudy';
  String get shortLabel =>
      '${termLabel(termId)}/${yearStudy.length >= 9 ? yearStudy.substring(7) : yearStudy}';
}

class Transcript {
  final DataUntil? dataUntil;
  final PortalSummary summary;
  final List<TranscriptTerm> terms;

  const Transcript({
    required this.summary,
    required this.terms,
    this.dataUntil,
  });

  factory Transcript.fromJson(Map<String, dynamic> j) {
    final terms = j['terms'];
    if (terms is! List) throw const FormatException('Expected terms');
    return Transcript(
      dataUntil: DataUntil.fromJson(j['dataUntil']),
      summary: PortalSummary.fromJson(
        j['summary'] is Map<String, dynamic> ? j['summary'] : const {},
      ),
      terms: _list(terms).map(TranscriptTerm.fromJson).toList(),
    );
  }

  List<TranscriptTerm> get scoredTerms =>
      terms.where((t) => t.hasScores).toList();
}

// ---------------------------------------------------------------- P2
enum ProgramStatus {
  passed('Đã đạt'),
  failed('Chưa đạt'),
  inLms('Đang học trên LMS'),
  inProgress('Đang học'),
  notTaken('Chưa học');

  final String label;
  const ProgramStatus(this.label);

  static ProgramStatus parse(Object? v) => switch (v) {
    'PASSED' => passed,
    'FAILED' => failed,
    'IN_LMS' => inLms,
    'IN_PROGRESS' => inProgress,
    _ => notTaken,
  };
}

class ProgramCourse {
  final String? code;
  final String name;
  final int? credits;
  final bool compulsory;
  final ProgramStatus status;
  final double? score10;
  final String? letter;
  final int? lmsCourseId;
  final String? lmsCourseName;
  final List<String> missing;

  const ProgramCourse({
    required this.name,
    required this.status,
    this.code,
    this.credits,
    this.compulsory = false,
    this.score10,
    this.letter,
    this.lmsCourseId,
    this.lmsCourseName,
    this.missing = const [],
  });

  factory ProgramCourse.fromJson(Map<String, dynamic> j) => ProgramCourse(
    code: _s(j['code']),
    name: _s(j['name']) ?? 'Học phần',
    credits: _i(j['credits']),
    compulsory: j['compulsory'] == true,
    status: ProgramStatus.parse(j['status']),
    score10: _d(j['score10']),
    letter: _s(j['letter']),
    lmsCourseId: _i(j['lmsCourseId']),
    lmsCourseName: _s(j['lmsCourseName']),
    missing: _strings(j['missing']),
  );
}

class ProgramSemester {
  final String name;
  final List<ProgramCourse> courses;
  const ProgramSemester(this.name, this.courses);
}

class ProgramProgress {
  final String? programId;
  final int compulsoryCredits;
  final int compulsoryPassedCredits;
  final int electivePassedCredits;
  final double? completionPercent;
  final Map<ProgramStatus, int> counts;
  final List<ProgramSemester> semesters;
  final List<ProgramCourse> eligible;
  final List<ProgramCourse> blocked;

  const ProgramProgress({
    required this.compulsoryCredits,
    required this.compulsoryPassedCredits,
    required this.electivePassedCredits,
    required this.counts,
    required this.semesters,
    required this.eligible,
    required this.blocked,
    this.programId,
    this.completionPercent,
  });

  factory ProgramProgress.fromJson(Map<String, dynamic> j) {
    final s = j['summary'] is Map<String, dynamic>
        ? j['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final counts = <ProgramStatus, int>{};
    final raw = s['statusCounts'];
    if (raw is Map) {
      raw.forEach((k, v) => counts[ProgramStatus.parse(k)] = _i(v) ?? 0);
    }
    ProgramCourse e(Map<String, dynamic> m) => ProgramCourse.fromJson({
      ...m,
      'status': m['retake'] == true ? 'FAILED' : 'NOT_TAKEN',
    });
    return ProgramProgress(
      programId: _s(j['programId']),
      compulsoryCredits: _i(s['compulsoryCredits']) ?? 0,
      compulsoryPassedCredits: _i(s['compulsoryPassedCredits']) ?? 0,
      electivePassedCredits: _i(s['electivePassedCredits']) ?? 0,
      completionPercent: _d(s['completionPercent']),
      counts: counts,
      semesters: _list(j['semesters'])
          .map(
            (m) => ProgramSemester(
              _s(m['semester']) ?? '',
              _list(m['courses']).map(ProgramCourse.fromJson).toList(),
            ),
          )
          .toList(),
      eligible: _list(j['eligible']).map(e).toList(),
      blocked: _list(j['blocked']).map(e).toList(),
    );
  }
}

// ---------------------------------------------------------------- P3
class GradeBand {
  final String name;
  final double min;
  const GradeBand(this.name, this.min);
}

class LetterGrade {
  final String letter;
  final double min10;
  final double? max10;
  final double score4;
  const LetterGrade(this.letter, this.min10, this.score4, [this.max10]);
}

class SimCourse {
  final String? code;
  final String name;
  final int credits;
  final ProgramStatus status;
  final String? lmsCourseName;
  final double? forecastPercent;
  final String? forecastLetter;

  /// Grade-improvement retake (real transcript): replaces [previousScore4] if higher, adds no credits.
  final bool improvement;
  final double? previousScore4;

  const SimCourse({
    required this.name,
    required this.credits,
    required this.status,
    this.code,
    this.lmsCourseName,
    this.forecastPercent,
    this.forecastLetter,
    this.improvement = false,
    this.previousScore4,
  });

  factory SimCourse.fromJson(Map<String, dynamic> j) => SimCourse(
    code: _s(j['code']),
    name: _s(j['name']) ?? 'Học phần',
    credits: _i(j['credits']) ?? 0,
    status: ProgramStatus.parse(j['status']),
    lmsCourseName: _s(j['lmsCourseName']),
    forecastPercent: _d(j['forecastPercent']),
    forecastLetter: _s(j['forecastLetter']),
    improvement: j['improvement'] == true,
    previousScore4: _d(j['previousScore4']),
  );
}

class GpaSimulation {
  final DataUntil? dataUntil;
  final double? gpa4;
  final int credits;
  final int remainingCredits;
  final List<GradeBand> bands;
  final List<LetterGrade> conversion;
  final List<SimCourse> courses;

  const GpaSimulation({
    required this.credits,
    required this.remainingCredits,
    required this.bands,
    required this.conversion,
    required this.courses,
    this.gpa4,
    this.dataUntil,
  });

  factory GpaSimulation.fromJson(Map<String, dynamic> j) => GpaSimulation(
    dataUntil: DataUntil.fromJson(j['dataUntil']),
    gpa4: _d(j['gpa4']),
    credits: _i(j['credits']) ?? 0,
    remainingCredits: _i(j['remainingCredits']) ?? 0,
    bands: _list(
      j['bands'],
    ).map((b) => GradeBand(_s(b['name']) ?? '', _d(b['min']) ?? 0)).toList(),
    conversion: _list(j['conversion'])
        .map(
          (g) => LetterGrade(
            _s(g['letter']) ?? '',
            _d(g['min10']) ?? 0,
            _d(g['score4']) ?? 0,
            _d(g['max10']),
          ),
        )
        .toList(),
    courses: _list(j['courses']).map(SimCourse.fromJson).toList(),
  );
}

// ---------------------------------------------------------------- P4 / P5
class ConductTerm {
  final String yearStudy;
  final String termId;
  final double? selfScore;
  final double? classScore;
  final double? departmentScore;
  final double? finalScore;
  final String? classification;

  const ConductTerm({
    required this.yearStudy,
    required this.termId,
    this.selfScore,
    this.classScore,
    this.departmentScore,
    this.finalScore,
    this.classification,
  });

  factory ConductTerm.fromJson(Map<String, dynamic> j) => ConductTerm(
    yearStudy: _s(j['yearStudy']) ?? '',
    termId: _s(j['termId']) ?? '',
    selfScore: _d(j['selfScore']),
    classScore: _d(j['classScore']),
    departmentScore: _d(j['departmentScore']),
    finalScore: _d(j['finalScore']),
    classification: _s(j['classification']),
  );

  String get label => '${termLabel(termId)} · $yearStudy';
  String get shortLabel =>
      '${termLabel(termId)}/${yearStudy.length >= 9 ? yearStudy.substring(7) : yearStudy}';
}

class ConductHistory {
  final List<ConductTerm> terms;
  final double? average;
  const ConductHistory(this.terms, this.average);

  factory ConductHistory.fromJson(Map<String, dynamic> j) => ConductHistory(
    _list(j['terms']).map(ConductTerm.fromJson).toList(),
    _d(j['average']),
  );
}

class AcademicDecision {
  final String name;
  final int? typeId;
  final DateTime? signDate;
  final String? yearStudy;
  final String? termId;
  final String? fullText;
  final bool academicWarning;

  const AcademicDecision({
    required this.name,
    this.typeId,
    this.signDate,
    this.yearStudy,
    this.termId,
    this.fullText,
    this.academicWarning = false,
  });

  factory AcademicDecision.fromJson(Map<String, dynamic> j) => AcademicDecision(
    name: _s(j['name']) ?? 'Quyết định',
    typeId: _i(j['typeId']),
    signDate: DateTime.tryParse(_s(j['signDate']) ?? ''),
    yearStudy: _s(j['yearStudy']),
    termId: _s(j['termId']),
    fullText: _s(j['fullText']),
    academicWarning: j['academicWarning'] == true,
  );
}

class DecisionList {
  final List<AcademicDecision> decisions;
  final int warningCount;
  const DecisionList(this.decisions, this.warningCount);

  factory DecisionList.fromJson(Map<String, dynamic> j) => DecisionList(
    _list(j['decisions']).map(AcademicDecision.fromJson).toList(),
    _i(j['warningCount']) ?? 0,
  );
}

// ---------------------------------------------------------------- P7
class PortalSources {
  final String lmsStatus;
  final String portalStatus;
  final DateTime? lastSuccess;
  final int cacheMinutes;
  final String provider;
  final bool demoMapping;
  final bool linked;
  final List<(String, String)> used;
  final List<(String, String)> notUsed;
  final List<(String, String)> courseMappings;
  final List<String> advisorClasses;

  const PortalSources({
    required this.lmsStatus,
    required this.portalStatus,
    required this.cacheMinutes,
    required this.provider,
    required this.used,
    required this.notUsed,
    required this.courseMappings,
    this.advisorClasses = const [],
    this.lastSuccess,
    this.demoMapping = false,
    this.linked = false,
  });

  factory PortalSources.fromJson(Map<String, dynamic> j) {
    final p = j['portal'] is Map<String, dynamic>
        ? j['portal'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final l = j['lms'] is Map<String, dynamic>
        ? j['lms'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return PortalSources(
      lmsStatus: _s(l['status']) ?? 'DOWN',
      portalStatus: _s(p['status']) ?? 'DISABLED',
      lastSuccess: DateTime.tryParse(_s(p['lastSuccess']) ?? '')?.toLocal(),
      cacheMinutes: _i(p['cacheMinutes']) ?? 0,
      provider: _s(p['provider']) ?? '',
      demoMapping: j['demoMapping'] == true,
      linked: j['linked'] == true,
      used: _list(
        j['used'],
      ).map((m) => (_s(m['source']) ?? '', _s(m['fields']) ?? '')).toList(),
      notUsed: _list(
        j['notUsed'],
      ).map((m) => (_s(m['fields']) ?? '', _s(m['reason']) ?? '')).toList(),
      courseMappings: _list(j['courseMappings'])
          .map(
            (m) => (
              _s(m['lmsCourseName']) ?? 'Khóa ${m['lmsCourseId']}',
              _s(m['portalCode']) ?? '',
            ),
          )
          .toList(),
      advisorClasses: _strings(j['advisorClasses']),
    );
  }
}

// ---------------------------------------------------------------- P6
class AdvisorTerm {
  final String yearStudy;
  final String termId;
  const AdvisorTerm(this.yearStudy, this.termId);

  static AdvisorTerm? fromJson(Object? j) => j is Map<String, dynamic>
      ? AdvisorTerm(_s(j['yearStudy']) ?? '', _s(j['termId']) ?? '')
      : null;

  String get label => '${termLabel(termId)} · $yearStudy';

  @override
  bool operator ==(Object other) =>
      other is AdvisorTerm &&
      other.yearStudy == yearStudy &&
      other.termId == termId;

  @override
  int get hashCode => Object.hash(yearStudy, termId);
}

class AdvisorClasses {
  final List<String> classes;
  final bool presentationMask;
  const AdvisorClasses(this.classes, this.presentationMask);

  factory AdvisorClasses.fromJson(Map<String, dynamic> j) =>
      AdvisorClasses(_strings(j['classes']), j['presentationMask'] == true);
}

enum AdvisorFlag {
  lowGpa('ĐTB < 2,0'),
  weakRank('Yếu/Kém'),
  lowConduct('Rèn luyện thấp'),
  noScore('Chưa có điểm');

  final String label;
  const AdvisorFlag(this.label);

  static AdvisorFlag? parse(Object? v) => switch (v) {
    'LOW_GPA' => lowGpa,
    'WEAK_RANK' => weakRank,
    'LOW_CONDUCT' => lowConduct,
    'NO_SCORE' => noScore,
    _ => null,
  };
}

class AdvisorStudent {
  final int no;
  final String name;
  final String? studentId;
  final double? gpa4;
  final double? gpa10;
  final double? cumulativeGpa4;
  final double? credits;
  final String? rank;
  final double? conduct;
  final List<AdvisorFlag> flags;

  const AdvisorStudent({
    required this.no,
    required this.name,
    required this.flags,
    this.studentId,
    this.gpa4,
    this.gpa10,
    this.cumulativeGpa4,
    this.credits,
    this.rank,
    this.conduct,
  });

  factory AdvisorStudent.fromJson(Map<String, dynamic> j) => AdvisorStudent(
    no: _i(j['no']) ?? 0,
    name: _s(j['name']) ?? 'Sinh viên',
    studentId: _s(j['studentId']),
    gpa4: _d(j['gpa4']),
    gpa10: _d(j['gpa10']),
    cumulativeGpa4: _d(j['cumulativeGpa4']),
    credits: _d(j['credits']),
    rank: _s(j['rank']),
    conduct: _d(j['conduct']),
    flags: (j['flags'] is List ? j['flags'] as List : const [])
        .map(AdvisorFlag.parse)
        .whereType<AdvisorFlag>()
        .toList(),
  );

  bool get attention => flags.isNotEmpty;
}

class HistogramBin {
  final double from;
  final double to;
  final int count;
  const HistogramBin(this.from, this.to, this.count);
}

class AdvisorOverview {
  final String classId;
  final AdvisorTerm? term;
  final List<AdvisorTerm> terms;
  final AdvisorTerm? previousTerm;
  final int size;
  final Map<String, int> ranks;
  final List<HistogramBin> histogram;
  final double? averageGpa4;
  final double? previousAverageGpa4;
  final double? trend;
  final int attentionCount;
  final bool mask;
  final List<AdvisorStudent> students;

  const AdvisorOverview({
    required this.classId,
    required this.terms,
    required this.size,
    required this.ranks,
    required this.histogram,
    required this.attentionCount,
    required this.mask,
    required this.students,
    this.term,
    this.previousTerm,
    this.averageGpa4,
    this.previousAverageGpa4,
    this.trend,
  });

  factory AdvisorOverview.fromJson(Map<String, dynamic> j) {
    final ranks = <String, int>{};
    final r = j['ranks'];
    if (r is Map) r.forEach((k, v) => ranks['$k'] = _i(v) ?? 0);
    return AdvisorOverview(
      classId: _s(j['classId']) ?? '',
      term: AdvisorTerm.fromJson(j['term']),
      terms: (j['terms'] is List ? j['terms'] as List : const [])
          .map(AdvisorTerm.fromJson)
          .whereType<AdvisorTerm>()
          .toList(),
      previousTerm: AdvisorTerm.fromJson(j['previousTerm']),
      size: _i(j['size']) ?? 0,
      ranks: ranks,
      histogram: _list(j['histogram'])
          .map(
            (h) => HistogramBin(
              _d(h['from']) ?? 0,
              _d(h['to']) ?? 0,
              _i(h['count']) ?? 0,
            ),
          )
          .toList(),
      averageGpa4: _d(j['averageGpa4']),
      previousAverageGpa4: _d(j['previousAverageGpa4']),
      trend: _d(j['trend']),
      attentionCount: _i(j['attentionCount']) ?? 0,
      mask: j['mask'] == true,
      students: _list(j['students']).map(AdvisorStudent.fromJson).toList(),
    );
  }
}

class AdvisorHistory {
  final AdvisorTerm term;
  final double? gpa4;
  final double? cumulativeGpa4;
  final double? conduct;
  const AdvisorHistory(this.term, this.gpa4, this.cumulativeGpa4, this.conduct);
}

class LmsCourseSignal {
  final String courseName;
  final String? level;
  final int? score;
  final double? progress;
  final int? overdue;
  const LmsCourseSignal(
    this.courseName,
    this.level,
    this.score,
    this.progress,
    this.overdue,
  );
}

class AdvisorStudentDetail {
  final AdvisorStudent student;
  final AdvisorTerm? term;
  final List<AdvisorHistory> history;
  final bool lmsLinked;
  final List<LmsCourseSignal> lmsCourses;

  const AdvisorStudentDetail({
    required this.student,
    required this.history,
    required this.lmsLinked,
    required this.lmsCourses,
    this.term,
  });

  factory AdvisorStudentDetail.fromJson(Map<String, dynamic> j) {
    final lms = j['lms'] is Map<String, dynamic>
        ? j['lms'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return AdvisorStudentDetail(
      student: AdvisorStudent.fromJson(j),
      term: AdvisorTerm.fromJson(j['term']),
      history: _list(j['history'])
          .map(
            (h) => AdvisorHistory(
              AdvisorTerm(_s(h['yearStudy']) ?? '', _s(h['termId']) ?? ''),
              _d(h['gpa4']),
              _d(h['cumulativeGpa4']),
              _d(h['conduct']),
            ),
          )
          .toList(),
      lmsLinked: lms['linked'] == true,
      lmsCourses: _list(lms['courses']).map((c) {
        final m = c['metrics'] is Map<String, dynamic>
            ? c['metrics'] as Map<String, dynamic>
            : const <String, dynamic>{};
        return LmsCourseSignal(
          _s(c['courseName']) ?? 'Khóa học',
          _s(c['level']),
          _i(c['score']),
          _d(m['progressPercentage'] ?? m['progress']),
          _i(m['overdueTasks'] ?? m['overdue']),
        );
      }).toList(),
    );
  }
}
