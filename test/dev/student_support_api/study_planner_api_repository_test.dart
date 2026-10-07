import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/dev/student_support_api/study_planner_api_repository.dart';
import 'package:dlu_lms_mobile/features/study_planner/domain/study_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final recommendation = <String, Object?>{
    'assignmentId': '31',
    'assignmentCode': 'DB01-A31',
    'assignmentName': 'Luyện truy vấn',
    'courseId': '11',
    'courseCode': 'DB01',
    'courseName': 'Cơ sở dữ liệu',
    'dueAt': '2026-10-09T12:00:00Z',
    'submissionStatus': 'not_submitted',
    'priority': 'high',
    'reasons': ['Còn dưới 24 giờ đến hạn'],
    'planned': false,
    'recommendedDurationMinutes': 45,
  };
  final plan = <String, Object?>{
    ...recommendation,
    'id': 'c7ff8367-8643-434d-99ac-7e41b1bf64d3',
    'title': 'Luyện truy vấn',
    'notes': '',
    'scheduledStartAt': '2026-10-09T09:00:00Z',
    'estimatedMinutes': 45,
    'status': 'handled',
    'createdAt': '2026-10-08T09:00:00Z',
    'updatedAt': '2026-10-09T09:00:00Z',
  };
  test(
    'recommendation retains backend reasons and duration, handles unknown deadline',
    () {
      final value = parseRecommendation(recommendation);
      expect(value.priority, StudyPriority.high);
      expect(value.reasons, ['Còn dưới 24 giờ đến hạn']);
      expect(value.recommendedDurationMinutes, 45);
      expect(
        parseRecommendation({...recommendation, 'dueAt': null}).dueAt,
        isNull,
      );
    },
  );
  test('plan handled is a distinct app-only state with UTC schedule', () {
    final value = parsePlanItem(plan);
    expect(value.status, StudyPlanStatus.handled);
    expect(value.scheduledStartAt.isUtc, isTrue);
    expect(
      value.scheduledEndAt.difference(value.scheduledStartAt).inMinutes,
      45,
    );
  });
  test('invalid values fail closed rather than populating plausible data', () {
    for (final bad in <Map<String, Object?>>[
      {...recommendation, 'assignmentId': null},
      {...recommendation, 'priority': 'critical'},
      {
        ...recommendation,
        'reasons': [null],
      },
      {...recommendation, 'planned': 'true'},
      {...recommendation, 'recommendedDurationMinutes': -1},
      {...recommendation, 'dueAt': 'bad'},
    ]) {
      expect(() => parseRecommendation(bad), throwsA(isA<ParsingFailure>()));
    }
    expect(
      () => parsePlanItem({...plan, 'status': 'submitted'}),
      throwsA(isA<ParsingFailure>()),
    );
  });
}
