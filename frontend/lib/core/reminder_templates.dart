/// V2-N8: reminder templates for ONE student, filled with that student's real numbers.
/// A template is offered only when its fact exists, so the text never states something untrue.
library;

class ReminderFacts {
  final String name;
  final String? courseName;
  final List<String> overdueTitles;

  /// Overdue count from the server when known (the title list may be partial).
  final int? overdueTotal;
  final int? inactiveDays;
  final double? averageGrade;
  final double passPercent;

  const ReminderFacts({
    required this.name,
    this.courseName,
    this.overdueTitles = const [],
    this.overdueTotal,
    this.inactiveDays,
    this.averageGrade,
    this.passPercent = 50,
  });

  int get overdueCount => overdueTotal ?? overdueTitles.length;
}

enum TemplateKind { overdue, inactive, lowGrade, general }

class ReminderTemplate {
  final TemplateKind kind;
  final String label, title, message;
  const ReminderTemplate(this.kind, this.label, this.title, this.message);
}

/// Inactivity shorter than this is normal and gets no "lâu không truy cập" template.
const inactiveThresholdDays = 7;

String _pct(double v) {
  final r = (v * 10).round() / 10;
  final s = r == r.roundToDouble()
      ? r.toStringAsFixed(0)
      : r.toStringAsFixed(1);
  return '${s.replaceAll('.', ',')}%';
}

List<ReminderTemplate> reminderTemplates(ReminderFacts f) {
  final course = f.courseName == null ? 'khóa học' : 'khóa "${f.courseName}"';
  final out = <ReminderTemplate>[];
  if (f.overdueCount > 0) {
    final shown = f.overdueTitles.take(3).map((t) => '"$t"').join(', ');
    final rest = f.overdueCount - f.overdueTitles.take(3).length;
    final list = shown.isEmpty
        ? ''
        : ': $shown${rest > 0 ? ' và $rest bài khác' : ''}';
    out.add(
      ReminderTemplate(
        TemplateKind.overdue,
        'Quá hạn',
        'Em có ${f.overdueCount} bài quá hạn',
        'Chào ${f.name}, trong $course em đang có ${f.overdueCount} bài quá hạn$list. '
            'Em hãy hoàn thành sớm nhất có thể; nếu gặp khó khăn hãy nhắn thầy/cô nhé.',
      ),
    );
  }
  final days = f.inactiveDays;
  if (days != null && days >= inactiveThresholdDays) {
    out.add(
      ReminderTemplate(
        TemplateKind.inactive,
        'Lâu không truy cập',
        'Đã $days ngày em chưa vào khóa học',
        'Chào ${f.name}, đã $days ngày em chưa truy cập $course. '
            'Em hãy vào xem lại bài mới và các hạn nộp sắp tới nhé.',
      ),
    );
  }
  final grade = f.averageGrade;
  if (grade != null && grade < f.passPercent) {
    out.add(
      ReminderTemplate(
        TemplateKind.lowGrade,
        'Điểm thấp',
        'Điểm trung bình hiện là ${_pct(grade)}',
        'Chào ${f.name}, điểm trung bình các bài đã chấm của em trong $course hiện là ${_pct(grade)}, '
            'dưới mức qua môn ${_pct(f.passPercent)}. Em hãy ôn lại các chương còn yếu và hỏi thầy/cô '
            'những phần chưa hiểu nhé.',
      ),
    );
  }
  out.add(
    ReminderTemplate(
      TemplateKind.general,
      'Chung',
      'Nhắc nhở học tập',
      'Chào ${f.name}, thầy/cô thấy dạo gần đây em chưa theo kịp $course. '
          'Em hãy vào khóa học để cập nhật bài và nhắn cho thầy/cô nếu gặp khó khăn nhé.',
    ),
  );
  return out;
}
