/// REAL-DATA-1: which data the backend serves, from the login response (`dataProfile`).
///
/// `demo` (default): the supplied snapshot, with Moodle access logs and attendance sessions.
/// `real`: the real Moodle export. There "activity" only means a hand-in (submitted assignment or
/// finished quiz attempt), progress counts graded activities only and attendance is the grade of
/// the LMS attendance activity. Every label says exactly how its number is computed.
class DataProfile {
  DataProfile._();

  static String _current = 'demo';

  static String get current => _current;
  static bool get isReal => _current == 'real';

  static void set(Object? value) =>
      _current = value == 'real' ? 'real' : 'demo';

  static void reset() => _current = 'demo';

  static String get progress =>
      isReal ? 'Tiến độ (theo hoạt động có chấm điểm)' : 'Tiến độ';

  static String get averageProgress =>
      isReal ? 'Tiến độ TB (hoạt động có chấm điểm)' : 'Tiến độ TB';

  static String get progressTimeline => isReal
      ? 'Hoạt động có chấm điểm đã hoàn thành (theo tuần)'
      : 'Tiến độ hoàn thành bài tập (Theo tuần)';

  static String get attendance =>
      isReal ? 'Điểm chuyên cần (theo điểm danh trên LMS)' : 'Chuyên cần';

  static String get attendanceRate =>
      isReal ? 'Điểm chuyên cần' : 'Tỷ lệ chuyên cần';

  static String get noAttendance => isReal
      ? 'Không có dữ liệu điểm danh trên LMS'
      : 'Chưa có dữ liệu chuyên cần';

  static String get noAttendanceForCourse => isReal
      ? 'Không có dữ liệu điểm danh trên LMS cho khóa học này'
      : 'Khóa học chưa có dữ liệu chuyên cần';

  static String get activityChartTitle => isReal
      ? 'Số lượt nộp bài và làm bài kiểm tra theo ngày'
      : 'Biểu đồ hoạt động';

  static String get activityChartHelp => isReal
      ? 'Mỗi ô là một ngày. Càng đậm nghĩa là càng nhiều lượt nộp bài hoặc làm bài kiểm tra.'
      : 'Số lượng hoạt động mỗi ngày. Càng đậm nghĩa là càng nhiều hoạt động.';

  static String activityCount(int n) =>
      isReal ? '$n lượt nộp bài hoặc làm bài kiểm tra' : '$n hoạt động';

  static String get streak => isReal ? 'Chuỗi ngày nộp bài' : 'Chuỗi học';

  static String get portalNotLinked => isReal
      ? 'Chưa có dữ liệu Portal cho MSSV này'
      : 'Tài khoản chưa liên kết Portal đào tạo';

  static const transcriptSource = 'Bảng điểm: sinh viên nhập từ Portal đào tạo';

  static String get learningHealthIntro => isReal
      ? 'Đây là đúng điểm theo dõi giảng viên thấy về bạn, tính từ lần nộp bài hoặc làm bài kiểm tra gần nhất, '
            'bài quá hạn, tiến độ theo hoạt động có chấm điểm và số lượt nộp bài, làm bài kiểm tra trong 7 ngày; '
            'chỉ xét các khóa của học kỳ hiện tại; "lâu chưa nộp bài" chỉ tính khi bạn có bài đã quá hạn. '
            'Xanh: dưới 30 · Vàng: 30–59 · Đỏ: từ 60.'
      : 'Đây là đúng điểm theo dõi giảng viên thấy về bạn, tính từ truy cập, '
            'bài quá hạn, tiến độ và hoạt động 7 ngày gần nhất. '
            'Xanh: dưới 30 · Vàng: 30–59 · Đỏ: từ 60.';

  /// Real export: tasks and warnings cover the current term only (courses from 15/07/2026).
  static String get tasksTitle =>
      isReal ? 'Việc cần làm · Học kỳ hiện tại' : 'Việc cần làm';

  static String get todayPriority =>
      isReal ? 'Ưu tiên hôm nay · Học kỳ hiện tại' : 'Ưu tiên hôm nay';

  /// Days with at least one event in the selected range (real: a hand-in).
  static String get activeDays => isReal ? 'Ngày có nộp bài' : 'Ngày HĐ';

  /// Teacher-side texts written for the access log, relabelled on real data (hand-ins only).
  /// Mirrors the backend TeacherAnonymizer table; longest phrases first.
  static const _teacherRelabel = [
    (
      'Không truy cập từ 14 ngày (hoặc chưa từng vào)',
      'Không nộp bài hoặc làm bài kiểm tra từ 14 ngày (hoặc chưa từng nộp), khi có bài quá hạn',
    ),
    (
      'Không truy cập khóa học 7–13 ngày',
      'Không nộp bài hoặc làm bài kiểm tra 7–13 ngày, khi có bài quá hạn',
    ),
    ('Không truy cập ≥7 ngày', 'Không nộp bài hoặc làm bài kiểm tra ≥7 ngày'),
    (
      'Chưa ghi nhận lượt truy cập nào',
      'Chưa ghi nhận lượt nộp bài hoặc làm bài kiểm tra nào',
    ),
    ('sinh viên có truy cập', 'sinh viên có nộp bài hoặc làm bài kiểm tra'),
    ('lần truy cập cuối', 'lần nộp bài hoặc làm bài kiểm tra cuối'),
    (
      'số lượt hoạt động trong 7 ngày',
      'số lượt nộp bài, làm bài kiểm tra trong 7 ngày',
    ),
    ('ngày em chưa vào khóa học', 'ngày em chưa nộp bài hoặc làm bài kiểm tra'),
    ('em chưa truy cập', 'em chưa nộp bài hoặc làm bài kiểm tra ở'),
    ('Lâu không truy cập', 'Lâu chưa nộp bài'),
    ('Chưa truy cập', 'Chưa nộp bài'),
    (
      'Không có hoạt động nào trong 7 ngày qua',
      'Không nộp bài hoặc làm bài kiểm tra nào trong 7 ngày qua, khi có bài quá hạn',
    ),
    ('SV có hoạt động', 'SV có nộp bài/làm bài kiểm tra'),
    ('Tiến độ <60%', 'Tiến độ (theo hoạt động có chấm điểm) <60%'),
  ];

  static String tt(String text) {
    if (!isReal) return text;
    var out = text;
    for (final (from, to) in _teacherRelabel) {
      out = out.replaceAll(from, to);
    }
    return out;
  }
}
