import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import 'api_exception.dart';
import 'api_session.dart';
import 'offline_cache.dart';
import '../models/student_dashboard.dart';
import '../models/student_course.dart';
import '../models/student_analytics.dart';
import '../models/teacher_course.dart';
import '../models/teacher_analytics.dart';
import '../models/student_course_detail.dart';
import '../models/teacher_monitoring.dart';
import '../models/learning_notification.dart';
import '../models/student_insights.dart';
import '../models/class_insights.dart';
import '../models/learning_goal.dart';
import '../models/grade_forecast.dart';
import '../models/learning_health.dart';
import '../models/study_recommendation.dart';
import '../models/class_forecast.dart';
import '../models/peer_comparison.dart';
import '../models/flashcard_review.dart';
import '../models/portal.dart';
import '../models/study_plan.dart';
import '../models/study_session.dart';
import '../models/quiz_insights.dart';
import '../models/calendar_event.dart';
import '../models/search_hit.dart';
import '../models/weekly_report.dart';
import '../models/achievement.dart';

class ApiService {
  /// Bumped after every study plan / focus session write so dashboard cards can refresh
  /// whichever screen the change was made from (V2-N6/N10).
  final ValueNotifier<int> studyDataVersion = ValueNotifier(0);
  void _studyChanged() => studyDataVersion.value++;

  Future<List<LearningNotification>> getNotifications({
    bool teacher = false,
  }) => _list(
    '/dev/${teacher ? 'teachers/${_teacherId(null)}' : 'students/${_studentId(null)}'}/notifications',
    LearningNotification.fromJson,
  );
  Future<void> markNotificationRead(int id) =>
      _postJson('/dev/students/${_studentId(null)}/notifications/$id/read');

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _getJson(path);
    final data = response is Map<String, dynamic> ? response['data'] : response;
    if (data is! List) throw const FormatException('Expected list');
    return data.map((v) => parse(v as Map<String, dynamic>)).toList();
  }

  Future<List<StudentTask>> getAllStudentTasks({int? studentId}) => _list(
    '/dev/students/${_studentId(studentId)}/tasks',
    StudentTask.fromJson,
  );
  Future<List<StudentLearningItem>> getContinueLearning({
    int? studentId,
    int? courseId,
  }) => _list(
    '/dev/students/${_studentId(studentId)}/continue-learning${courseId == null ? '' : '?courseId=$courseId'}',
    StudentLearningItem.fromJson,
  );
  Future<List<MonitoredStudent>> getTeacherStudents(
    int courseId, {
    int? teacherId,
  }) => _list(
    '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/students',
    MonitoredStudent.fromJson,
  );
  Future<MonitoredStudent> getMonitoredStudent(
    int courseId,
    int userId, {
    int? teacherId,
  }) async => MonitoredStudent.fromJson(
    await _getJson(
          '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/students/$userId',
        )
        as Map<String, dynamic>,
  );
  Future<List<MonitoredActivity>> getTeacherActivities(
    int courseId,
    String type, {
    int? teacherId,
  }) => _list(
    '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/${type == 'assignment' ? 'assignments' : 'quizzes'}',
    MonitoredActivity.fromJson,
  );
  Future<List<ActivityStudent>> getActivityStudents(
    int courseId,
    MonitoredActivity activity, {
    int? teacherId,
  }) => _list(
    '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/${activity.type == 'assignment' ? 'assignments' : 'quizzes'}/${activity.id}/students',
    ActivityStudent.fromJson,
  );
  final http.Client _client;
  final String baseUrl;
  final bool localDevelopment;
  final ApiSession session;
  final Duration requestTimeout;

  /// Portal reads: the first uncached call may chain several Portal requests on the server
  /// (e.g. an advisor student's history over all semesters measured > 20 s on 10/11/2026).
  final Duration portalTimeout;

  /// V2-N11 offline viewing: last successful bodies of the summary screens.
  final OfflineStore offlineStore;

  /// Time of the cached data being shown while offline; null when online.
  final ValueNotifier<DateTime?> offlineSince = ValueNotifier(null);

  ApiService({
    http.Client? client,
    this.baseUrl = ApiConstants.baseUrl,
    bool localDevelopment = ApiConstants.localDevelopment,
    ApiSession? session,
    this.requestTimeout = const Duration(seconds: 20),
    this.portalTimeout = const Duration(seconds: 60),
    OfflineStore? offlineStore,
  }) : localDevelopment = kDebugMode && localDevelopment,
       _client = client ?? http.Client(),
       session = session ?? ApiSession(),
       offlineStore = offlineStore ?? SharedPrefsOfflineStore();

  int _studentId(int? explicitId) => explicitId ?? session.userIdFor('STUDENT');
  int _teacherId(int? explicitId) => explicitId ?? session.userIdFor('TEACHER');

  void dispose() => _client.close();
  void signOut() {
    session.clear();
    clearPortalCache();
    _clearOffline();
  }

  /// Bumped on every sign-out / role change. A request started under an older identity may still
  /// answer later; its body is then neither cached nor allowed to switch the app to offline mode.
  int _identity = 0;

  /// Role change / sign-out: no cached data may leak between identities.
  void _clearOffline() {
    _identity++;
    offlineSince.value = null;
    offlineStore.clear().catchError((Object e) {
      debugPrint('Offline cache clear: $e');
    });
  }

  static const offlineWriteMessage =
      'Đang ngoại tuyến nên chưa lưu được thay đổi. Hãy thử lại khi có mạng.';

  /// Cache key: API environment + path (the path holds the role and the user id). Never the token.
  String _offlineKey(Uri base, String path) => '$base$path';

  Future<dynamic> _offlineFallback(String key, int identity) async {
    ({String body, DateTime at})? hit;
    try {
      // A slow or unavailable store must never keep a screen spinning.
      hit = await offlineStore.get(key).timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Offline cache read: $e');
    }
    if (hit == null || identity != _identity) return null;
    offlineSince.value = hit.at;
    return jsonDecode(hit.body);
  }

  static String? _errorCode(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final code = body is Map ? body['code'] : null;
      return code is String ? code : null;
    } catch (_) {
      return null;
    }
  }

  // V3-P8: short client-side cache for Portal reads; cleared on sign-out and role change.
  static const portalCacheTtl = Duration(minutes: 5);
  final Map<String, (DateTime, Object)> _portalCache = {};

  void clearPortalCache() => _portalCache.clear();

  Future<Map<String, dynamic>> _portalGet(
    String path, {
    bool refresh = false,
  }) async {
    final hit = _portalCache[path];
    if (!refresh &&
        hit != null &&
        DateTime.now().difference(hit.$1) < portalCacheTtl) {
      return hit.$2 as Map<String, dynamic>;
    }
    final data = await _getJson(path);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected Portal object');
    }
    _portalCache[path] = (DateTime.now(), data);
    return data;
  }

  static const loginFailedMessage = 'Mã số hoặc mật khẩu không đúng';

  /// Sign-in with the student code (MSSV) or username and a password. The server decides the role;
  /// the password is sent once over the request and never stored.
  /// REAL-DATA-2: the server's data profile from the public /health ("real" or "demo"); null when
  /// unreachable. On "real" the sign-in screen hides the passwordless demo mode (the server refuses it).
  Future<String?> serverDataProfile() async {
    try {
      final base = ApiConstants.validateBaseUrl(
        baseUrl,
        localDevelopment: localDevelopment,
      );
      final r = await _client
          .get(
            Uri.parse('$base/health'),
            headers: const {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes));
      return j is Map && j['dataProfile'] is String
          ? j['dataProfile'] as String
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<String> login(String login, String password) async {
    session.clear();
    clearPortalCache();
    _clearOffline();
    final base = ApiConstants.validateBaseUrl(
      baseUrl,
      localDevelopment: localDevelopment,
    );
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$base/auth/login'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json; charset=utf-8',
            },
            body: jsonEncode({'login': login.trim(), 'password': password}),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException {
      throw const ApiException(
        'Không thể kết nối máy chủ. Kiểm tra mạng và địa chỉ API.',
      );
    }
    switch (response.statusCode) {
      case 200:
        break;
      case 401:
        throw const ApiException(loginFailedMessage, statusCode: 401);
      case 429:
        final seconds =
            int.tryParse(response.headers['retry-after'] ?? '') ?? 900;
        final minutes = (seconds / 60).ceil();
        throw ApiException(
          'Đăng nhập sai nhiều lần. Vui lòng thử lại sau $minutes phút.',
          statusCode: 429,
          code: 'LOGIN_LOCKED',
        );
      case 400:
        throw const ApiException(
          'Mã số 1–64 ký tự, mật khẩu 1–128 ký tự.',
          statusCode: 400,
        );
      default:
        throw ApiException.http(response.statusCode);
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! Map<String, dynamic> ||
        (data['role'] != 'STUDENT' && data['role'] != 'TEACHER')) {
      throw const FormatException('Phản hồi đăng nhập không hợp lệ.');
    }
    session.accept(data, requestedRole: data['role'] as String);
    return data['role'] as String;
  }

  Future<void> demoLogin(String role) async {
    if (!localDevelopment) {
      throw const ApiException('Đăng nhập thử nghiệm chưa được bật.');
    }
    session.clear();
    clearPortalCache();
    _clearOffline();
    final data = await _requestJson(
      'POST',
      '/auth/demo-login',
      body: {'role': role.toUpperCase()},
      authenticated: false,
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Phản hồi đăng nhập không hợp lệ.');
    }
    session.accept(data, requestedRole: role);
  }

  Future<dynamic> _getJson(String path, {bool allowEmpty = false}) =>
      _requestJson('GET', path, allowEmpty: allowEmpty);

  Future<dynamic> _postJson(String path, {Map<String, dynamic>? body}) =>
      _requestJson('POST', path, body: body);

  Future<dynamic> _requestJson(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool allowEmpty = false,
    bool authenticated = true,
    bool rawText = false,
  }) async {
    final base = ApiConstants.validateBaseUrl(
      baseUrl,
      localDevelopment: localDevelopment,
    );
    final token = session.token;
    if (authenticated && token == null) {
      throw const ApiException(
        'Vui lòng đăng nhập trước khi truy cập.',
        statusCode: 401,
      );
    }
    final request = http.Request(method, Uri.parse('$base$path'));
    request.headers.addAll({
      'Accept': rawText ? 'text/csv, */*' : 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
      if (authenticated) 'Authorization': 'Bearer $token',
    });
    if (body != null) request.body = jsonEncode(body);
    if (method != 'GET' && offlineSince.value != null) {
      throw const ApiException(offlineWriteMessage);
    }
    final cacheable = method == 'GET' && !rawText && isOfflineCacheable(path);
    final key = _offlineKey(base, path);
    final identity = _identity;
    try {
      final response = await (() async {
        final stream = await _client.send(request);
        return http.Response.fromStream(stream);
      })().timeout(path.contains('/portal/') ? portalTimeout : requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 401) session.clear();
        throw ApiException.http(
          response.statusCode,
          code: _errorCode(response),
        );
      }
      final decoded = utf8.decode(response.bodyBytes);
      final current = identity == _identity;
      if (current) offlineSince.value = null;
      if (cacheable && current && decoded.trim().isNotEmpty) {
        offlineStore.put(key, decoded, DateTime.now()).catchError((Object e) {
          debugPrint('Offline cache write: $e');
        });
      }
      if (rawText) return decoded;
      if (decoded.trim().isEmpty && (allowEmpty || method != 'GET')) {
        return null;
      }
      return jsonDecode(decoded);
    } on TimeoutException {
      if (cacheable) {
        final cached = await _offlineFallback(key, identity);
        if (cached != null) return cached;
      }
      throw const ApiException('Máy chủ phản hồi quá lâu. Vui lòng thử lại.');
    } on http.ClientException {
      if (cacheable) {
        final cached = await _offlineFallback(key, identity);
        if (cached != null) return cached;
      }
      if (method != 'GET') throw const ApiException(offlineWriteMessage);
      throw const ApiException(
        'Không thể kết nối máy chủ. Kiểm tra mạng và địa chỉ API.',
      );
    }
  }

  // STUDENT APIs
  Future<StudentDashboard> getStudentDashboard({int? studentId}) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/dashboard',
    );
    if (data is Map<String, dynamic>) {
      // If wrapped in custom API response object e.g. { "data": ... }
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return StudentDashboard.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StudentDashboard.fromJson(data);
    }
    throw Exception('Dữ liệu bảng điều khiển sinh viên không hợp lệ');
  }

  Future<List<StudentCourse>> getStudentCourses({int? studentId}) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses',
    );
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'] as List;
    } else {
      throw Exception('Dữ liệu danh sách khóa học không hợp lệ');
    }

    return list
        .map((item) => StudentCourse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StudentAnalytics> getStudentCourseAnalytics({
    int? studentId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses/$courseId/analytics',
    );
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return StudentAnalytics.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StudentAnalytics.fromJson(data);
    }
    throw Exception('Dữ liệu phân tích khóa học không hợp lệ');
  }

  Future<List<LearningGoal>> getStudentGoals({int? studentId}) => _list(
    '/dev/students/${_studentId(studentId)}/goals',
    LearningGoal.fromJson,
  );

  Future<LearningGoal> createStudentGoal(
    Map<String, dynamic> request, {
    int? studentId,
  }) async {
    final data = await _postJson(
      '/dev/students/${_studentId(studentId)}/goals',
      body: request,
    );
    if (data is Map<String, dynamic>) {
      return LearningGoal.fromJson(data);
    }
    throw Exception('Dữ liệu không hợp lệ');
  }

  Future<LearningGoal> cancelStudentGoal(int goalId, {int? studentId}) async {
    final data = await _postJson(
      '/dev/students/${_studentId(studentId)}/goals/$goalId/cancel',
    );
    if (data is Map<String, dynamic>) {
      return LearningGoal.fromJson(data);
    }
    throw Exception('Dữ liệu không hợp lệ');
  }

  // TEACHER APIs
  Future<StudentInsights> getGlobalStudentInsights({
    int? studentId,
    int days = 56,
  }) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/insights?days=$days',
    );
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return StudentInsights.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StudentInsights.fromJson(data);
    }
    throw Exception('Dữ liệu phân tích học tập không hợp lệ');
  }

  Future<List<TeacherCourse>> getTeacherCourses({int? teacherId}) async {
    final data = await _getJson(
      '/dev/teachers/${_teacherId(teacherId)}/courses',
    );
    List<dynamic> list;
    if (data is List) {
      list = data;
    } else if (data is Map<String, dynamic> && data['data'] is List) {
      list = data['data'] as List;
    } else {
      throw Exception('Dữ liệu danh sách khóa học giảng viên không hợp lệ');
    }

    return list
        .map((item) => TeacherCourse.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<TeacherAnalytics> getTeacherCourseAnalytics({
    int? teacherId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/analytics',
    );
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return TeacherAnalytics.fromJson(data['data'] as Map<String, dynamic>);
      }
      return TeacherAnalytics.fromJson(data);
    }
    throw Exception('Dữ liệu phân tích khóa học giảng viên không hợp lệ');
  }

  /// Sends one in-app reminder to each student; returns how many were sent.
  Future<int> sendReminders({
    int? teacherId,
    required int courseId,
    required List<int> studentIds,
    required String title,
    required String message,
    String? sourceType,
    int? sourceId,
  }) async {
    final data = await _postJson(
      '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/reminders',
      body: {
        'student_ids': studentIds,
        'title': title,
        'message': message,
        if (sourceType != null && sourceId != null) ...{
          'source_type': sourceType,
          'source_id': sourceId,
        },
      },
    );
    return data is Map && data['sent'] is num
        ? (data['sent'] as num).toInt()
        : studentIds.length;
  }

  /// V2-N16 quiz analysis of one teacher course.
  Future<List<QuizInsight>> getQuizInsights({
    int? teacherId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/quiz-insights',
    );
    if (data is! Map<String, dynamic> || data['quizzes'] is! List) {
      throw const FormatException('Expected quiz insights');
    }
    return [
      for (final q in data['quizzes'] as List)
        if (q is Map<String, dynamic>) QuizInsight.fromJson(q),
    ];
  }

  Future<ClassForecast> getClassForecast({
    int? teacherId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/grade-forecast',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected class forecast object');
    }
    return ClassForecast.fromJson(data);
  }

  Future<ClassInsights> getClassInsights({
    int? teacherId,
    required int courseId,
    int weeks = 8,
  }) async {
    final data = await _getJson(
      '/dev/teachers/${_teacherId(teacherId)}/courses/$courseId/class-insights?weeks=$weeks',
    );
    if (data is Map<String, dynamic>) {
      if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
        return ClassInsights.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ClassInsights.fromJson(data);
    }
    throw Exception('Dữ liệu thông tin lớp học không hợp lệ');
  }

  Future<List<T>> _studentList<T>(
    int? studentId,
    int courseId,
    String endpoint,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses/$courseId/$endpoint',
    );
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data is! List) throw const FormatException('Expected a list');
    return data.map((item) => parse(item as Map<String, dynamic>)).toList();
  }

  Future<List<StudentLearningItem>> getStudentLearningItems({
    int? studentId,
    required int courseId,
  }) => _studentList(
    studentId,
    courseId,
    'learning-items',
    StudentLearningItem.fromJson,
  );

  Future<List<StudentTask>> getStudentTasks({
    int? studentId,
    required int courseId,
  }) => _studentList(studentId, courseId, 'tasks', StudentTask.fromJson);

  Future<List<StudentGrade>> getStudentGrades({
    int? studentId,
    required int courseId,
  }) => _studentList(studentId, courseId, 'grades', StudentGrade.fromJson);

  Future<GradeForecast> getGradeForecast({
    int? studentId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses/$courseId/grade-forecast',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected grade forecast object');
    }
    return GradeForecast.fromJson(data);
  }

  Future<List<WeakChapter>> getStudyRecommendations({
    int? studentId,
    int? courseId,
    int limit = 3,
  }) async {
    final path = courseId == null
        ? '/dev/students/${_studentId(studentId)}/study-recommendations?limit=$limit'
        : '/dev/students/${_studentId(studentId)}/courses/$courseId/study-recommendations';
    final data = await _getJson(path);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected study recommendations object');
    }
    return WeakChapter.listFrom(data);
  }

  Future<PeerComparison> getPeerComparison({
    int? studentId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses/$courseId/peer-comparison',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected peer comparison object');
    }
    return PeerComparison.fromJson(data);
  }

  Future<LearningHealthOverview> getLearningHealth({int? studentId}) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/learning-health',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected learning health object');
    }
    return LearningHealthOverview.fromJson(data);
  }

  Future<CourseHealth> getCourseLearningHealth({
    int? studentId,
    required int courseId,
  }) async {
    final data = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses/$courseId/learning-health',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected course learning health object');
    }
    return CourseHealth.fromJson(data);
  }

  Future<List<StudentGradeCategory>> getStudentGradeCategories({
    int? studentId,
    required int courseId,
  }) => _studentList(
    studentId,
    courseId,
    'grade-categories',
    StudentGradeCategory.fromJson,
  );

  Future<StudentAttendance?> getStudentAttendance({
    int? studentId,
    required int courseId,
  }) async {
    final response = await _getJson(
      '/dev/students/${_studentId(studentId)}/courses/$courseId/attendance',
      allowEmpty: true,
    );
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data == null) return null;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected attendance object');
    }
    return StudentAttendance.fromJson(data);
  }

  // PHASE C: Learning Reflection (Student)
  Future<List<Map<String, dynamic>>> getReflections({
    int? studentId,
    int? courseId,
  }) async {
    final query = courseId == null ? '' : '?courseId=$courseId';
    final response = await _getJson(
      '/dev/students/${_studentId(studentId)}/reflections$query',
    );
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data is! List) {
      throw const FormatException('Expected a list of reflections');
    }
    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid reflection item');
      }
      return item;
    }).toList();
  }

  Future<void> addReflection(
    String content,
    int level, {
    int? studentId,
    int? courseId,
  }) async {
    final payload = <String, dynamic>{
      'content': content,
      'understandingLevel': level,
    };
    if (courseId != null) payload['courseId'] = courseId;
    await _postJson(
      '/dev/students/${_studentId(studentId)}/reflections',
      body: payload,
    );
  }

  // Teacher notes share the same UTF-8, auth and timeout handling as every API.
  Future<List<Map<String, dynamic>>> getTeacherNotes(
    int studentId, {
    int? teacherId,
    int? courseId,
  }) => _list(
    '/teachers/${_teacherId(teacherId)}/notes?studentId=$studentId${courseId == null ? '' : '&courseId=$courseId'}',
    (item) => item,
  );

  /// V2-N8: every note of this teacher in one course, newest first (for the support export).
  Future<List<Map<String, dynamic>>> getCourseNotes(
    int courseId, {
    int? teacherId,
  }) => _list(
    '/teachers/${_teacherId(teacherId)}/notes?courseId=$courseId',
    (item) => item,
  );

  Future<void> addTeacherNote(
    int studentId,
    String note, {
    int? teacherId,
    int? courseId,
    String status = 'active',
  }) async {
    await _postJson(
      '/teachers/${_teacherId(teacherId)}/notes',
      body: {
        'studentId': studentId,
        'note': note,
        'status': status,
        'courseId': ?courseId,
      },
    );
  }

  Future<void> updateTeacherNoteStatus(
    int noteId,
    String status, {
    int? teacherId,
  }) async {
    await _requestJson(
      'PUT',
      '/teachers/${_teacherId(teacherId)}/notes/$noteId/status',
      body: {'status': status},
    );
  }

  // PHASE D: Flashcards
  String _flashcardPath(int courseId, int? studentId) =>
      '/dev/students/${_studentId(studentId)}/courses/$courseId/flashcards';

  Future<List<Map<String, dynamic>>> getFlashcards(
    int courseId, {
    int? studentId,
  }) async {
    final response = await _getJson(_flashcardPath(courseId, studentId));
    final data =
        response is Map<String, dynamic> && response.containsKey('data')
        ? response['data']
        : response;
    if (data is! List) {
      throw const FormatException('Expected a list of flashcards');
    }
    return data.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid flashcard item');
      }
      return item;
    }).toList();
  }

  Future<void> addFlashcard(
    int courseId,
    String frontText,
    String backText, {
    int? studentId,
  }) async {
    await _postJson(
      _flashcardPath(courseId, studentId),
      body: {'frontText': frontText, 'backText': backText},
    );
  }

  Future<void> updateFlashcard(
    int courseId,
    int id,
    String frontText,
    String backText, {
    int? studentId,
  }) async {
    await _requestJson(
      'PUT',
      '${_flashcardPath(courseId, studentId)}/$id',
      body: {'frontText': frontText, 'backText': backText},
    );
  }

  Future<void> deleteFlashcard(int courseId, int id, {int? studentId}) async {
    await _requestJson('DELETE', '${_flashcardPath(courseId, studentId)}/$id');
  }

  // V2-N5: spaced repetition (SM-2)
  Future<DueFlashcards> getDueFlashcards({
    int? courseId,
    int? studentId,
  }) async {
    final base = '/dev/students/${_studentId(studentId)}/flashcards/due';
    final data = await _getJson(
      courseId == null ? base : '$base?courseId=$courseId',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected due flashcards object');
    }
    return DueFlashcards.fromJson(data);
  }

  Future<ReviewResult> reviewFlashcard(
    int courseId,
    int id,
    ReviewRating rating, {
    int? studentId,
  }) async {
    final data = await _postJson(
      '${_flashcardPath(courseId, studentId)}/$id/review',
      body: {'rating': rating.value},
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected review result object');
    }
    return ReviewResult.fromJson(data);
  }

  // V2-N6: weekly study plan
  String get _planPath => '/dev/students/${_studentId(null)}/study-plan';

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<StudyPlanWeek> getStudyPlan({DateTime? from, DateTime? to}) async {
    final q = [
      if (from != null) 'from=${_day(from)}',
      if (to != null) 'to=${_day(to)}',
    ];
    final data = await _getJson(
      q.isEmpty ? _planPath : '$_planPath?${q.join('&')}',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected study plan object');
    }
    return StudyPlanWeek.fromJson(data);
  }

  Future<StudyPlanWeek> generateStudyPlan(int dailyMinutes) async {
    final data = await _postJson(
      '$_planPath/generate',
      body: {'dailyMinutes': dailyMinutes},
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected study plan object');
    }
    _studyChanged();
    return StudyPlanWeek.fromJson(data);
  }

  Future<PlanItem> setPlanItemStatus(int id, PlanStatus status) async {
    final data = await _requestJson(
      'PUT',
      '$_planPath/items/$id/status',
      body: {'status': status.name},
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected plan item');
    }
    _studyChanged();
    return PlanItem.fromJson(data);
  }

  // V2-N10: focus sessions
  String get _sessionPath => '/dev/students/${_studentId(null)}/study-sessions';

  Future<Map<String, dynamic>> recordStudySession({
    required DateTime startedAt,
    required DateTime endedAt,
    required int focusMinutes,
    int? courseId,
    int? planItemId,
    bool markPlanItemDone = false,
  }) async {
    final data = await _postJson(
      _sessionPath,
      body: {
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt.toUtc().toIso8601String(),
        'focusMinutes': focusMinutes,
        'courseId': ?courseId,
        'planItemId': ?planItemId,
        if (markPlanItemDone) 'markPlanItemDone': true,
      },
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected study session');
    }
    _studyChanged();
    return data;
  }

  Future<StudySummary> getStudySummary({DateTime? from, DateTime? to}) async {
    final q = [
      if (from != null) 'from=${_day(from)}',
      if (to != null) 'to=${_day(to)}',
    ];
    final data = await _getJson(
      q.isEmpty
          ? '$_sessionPath/summary'
          : '$_sessionPath/summary?${q.join('&')}',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected study summary');
    }
    return StudySummary.fromJson(data);
  }

  // V2-N12: combined calendar (deadlines, plan items, attendance sessions)
  Future<List<CalendarEvent>> getCalendar({
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _getJson(
      '/dev/students/${_studentId(null)}/calendar?from=${_day(from)}&to=${_day(to)}',
    );
    if (data is! Map<String, dynamic> || data['events'] is! List) {
      throw const FormatException('Expected calendar');
    }
    return [
      for (final e in data['events'] as List)
        if (e is Map<String, dynamic>) CalendarEvent.fromJson(e),
    ];
  }

  // V2-N13 quick search (accent-insensitive on the server, own data only)
  Future<List<SearchHit>> search(String q, {bool teacher = false}) async {
    final base = teacher
        ? '/dev/teachers/${_teacherId(null)}/search'
        : '/dev/students/${_studentId(null)}/search';
    final data = await _getJson('$base?q=${Uri.encodeQueryComponent(q)}');
    if (data is! Map<String, dynamic> || data['results'] is! List) {
      throw const FormatException('Expected search results');
    }
    return [
      for (final r in data['results'] as List)
        if (r is Map<String, dynamic>) SearchHit.fromJson(r),
    ];
  }

  // V2-N14 "Tuần của bạn"
  Future<WeeklyReport> getWeeklyReport({DateTime? week}) async {
    final data = await _getJson(
      '/dev/students/${_studentId(null)}/weekly-report${week == null ? '' : '?week=${_day(week)}'}',
    );
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected weekly report');
    }
    return WeeklyReport.fromJson(data);
  }

  // V2-N17 achievements (own badges only)
  Future<List<Achievement>> getAchievements() async {
    final data = await _getJson(
      '/dev/students/${_studentId(null)}/achievements',
    );
    if (data is! Map<String, dynamic> || data['badges'] is! List) {
      throw const FormatException('Expected achievements');
    }
    return [
      for (final b in data['badges'] as List)
        if (b is Map<String, dynamic>) Achievement.fromJson(b),
    ];
  }

  // V2-N7: reminder settings (server part; the daily time stays on the device)
  String get _prefsPath =>
      '/dev/students/${_studentId(null)}/notification-preferences';

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final data = await _getJson(_prefsPath);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected notification preferences');
    }
    return data;
  }

  Future<Map<String, dynamic>> putNotificationPreferences(
    Map<String, dynamic> body,
  ) async {
    final data = await _requestJson('PUT', _prefsPath, body: body);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Expected notification preferences');
    }
    return data;
  }

  // V3: DLU training portal (via backend only; identity is decided by the server)
  String get _studentPortal => '/dev/students/${_studentId(null)}/portal';
  String get _teacherPortal => '/dev/teachers/${_teacherId(null)}/portal';

  Future<PortalSummary> getPortalSummary({bool refresh = false}) async =>
      PortalSummary.fromJson(
        await _portalGet('$_studentPortal/summary', refresh: refresh),
      );

  Future<Transcript> getTranscript({bool refresh = false}) async =>
      Transcript.fromJson(
        await _portalGet('$_studentPortal/transcript', refresh: refresh),
      );

  Future<ProgramProgress> getProgramProgress({bool refresh = false}) async =>
      ProgramProgress.fromJson(
        await _portalGet('$_studentPortal/program', refresh: refresh),
      );

  Future<GpaSimulation> getGpaSimulation({bool refresh = false}) async =>
      GpaSimulation.fromJson(
        await _portalGet('$_studentPortal/gpa-simulation', refresh: refresh),
      );

  Future<ConductHistory> getConduct({bool refresh = false}) async =>
      ConductHistory.fromJson(
        await _portalGet('$_studentPortal/conduct', refresh: refresh),
      );

  Future<DecisionList> getDecisions({bool refresh = false}) async =>
      DecisionList.fromJson(
        await _portalGet('$_studentPortal/decisions', refresh: refresh),
      );

  Future<PortalSources> getPortalSources({
    bool teacher = false,
    bool refresh = true,
  }) async => PortalSources.fromJson(
    await _portalGet(
      '${teacher ? _teacherPortal : _studentPortal}/sources',
      refresh: refresh,
    ),
  );

  Future<AdvisorClasses> getAdvisorClasses({bool refresh = false}) async =>
      AdvisorClasses.fromJson(
        await _portalGet('$_teacherPortal/advisor/classes', refresh: refresh),
      );

  String _advisorQuery(AdvisorTerm? term, bool? mask) {
    final q = <String>[
      if (term != null) 'yearStudy=${term.yearStudy}&termId=${term.termId}',
      if (mask != null) 'mask=$mask',
    ];
    return q.isEmpty ? '' : '?${q.join('&')}';
  }

  Future<AdvisorOverview> getAdvisorOverview(
    String classId, {
    AdvisorTerm? term,
    bool? mask,
    bool refresh = false,
  }) async => AdvisorOverview.fromJson(
    await _portalGet(
      '$_teacherPortal/advisor/classes/${Uri.encodeComponent(classId)}${_advisorQuery(term, mask)}',
      refresh: refresh,
    ),
  );

  Future<AdvisorStudentDetail> getAdvisorStudent(
    String classId,
    int no, {
    AdvisorTerm? term,
    bool? mask,
  }) async => AdvisorStudentDetail.fromJson(
    await _portalGet(
      '$_teacherPortal/advisor/classes/${Uri.encodeComponent(classId)}/students/$no${_advisorQuery(term, mask)}',
    ),
  );

  /// CSV of the advisor class; the server refuses it unless confirmed and unmasked.
  Future<String> exportAdvisorCsv(String classId, {AdvisorTerm? term}) async {
    final query = _advisorQuery(term, false);
    final data = await _requestJson(
      'GET',
      '$_teacherPortal/advisor/classes/${Uri.encodeComponent(classId)}/export$query&confirm=true',
      rawText: true,
    );
    return data as String;
  }
}
