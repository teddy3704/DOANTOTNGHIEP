import 'package:dlu_lms_mobile/features/interventions/domain/intervention_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support_test_fixtures.dart';

void main() {
  test('parses support record and distinguishes due versus resolved', () {
    final value = TeacherIntervention.fromJson(recordJson());
    expect(value.status, InterventionStatus.followingUp);
    expect(value.baseline.progressPercent, 25);
    expect(value.isDue(DateTime(2030, 6, 2)), isFalse);
    expect(value.isDue(DateTime(2030, 6, 3, 22)), isTrue);
    expect(record(status: InterventionStatus.resolved).isDue(now), isFalse);
  });
  test(
    'rejects absent/empty/invalid identities instead of stringifying null',
    () {
      for (final key in ['id', 'courseId', 'studentId']) {
        for (final invalid in [null, '', ' ', 'null', -1, true]) {
          expect(
            () => TeacherIntervention.fromJson({...recordJson(), key: invalid}),
            throwsFormatException,
          );
        }
      }
    },
  );
  test('rejects invalid and normalized-overflow dates', () {
    for (final key in ['createdAt', 'updatedAt', 'followUpAt']) {
      for (final invalid in [
        '',
        'yesterday',
        '2030-02-30T10:00:00Z',
        '2030-13-01T09:00:00Z',
        '2030-06-01T25:00:00Z',
        '2030-06-01T09:60:00Z',
        '2030-06-01T09:00:61Z',
        '2030-06-01T09:00:00',
      ]) {
        expect(
          () => TeacherIntervention.fromJson({...recordJson(), key: invalid}),
          throwsFormatException,
        );
      }
    }
  });
  test('low positive signals need attention, healthy zero score does not', () {
    final low = AttentionStudent.fromJson({
      ...attentionJson(),
      'priority': 'low',
      'priorityScore': 5,
    });
    final healthy = AttentionStudent.fromJson({
      ...attentionJson(),
      'priority': 'low',
      'priorityScore': 0,
    });
    expect(low.needsAttention, isTrue);
    expect(healthy.needsAttention, isFalse);
    for (final invalid in [null, -1, 1.5, 101, double.infinity]) {
      expect(
        () => AttentionStudent.fromJson({
          ...attentionJson(),
          'priorityScore': invalid,
        }),
        throwsFormatException,
      );
    }
  });
  test(
    'rejects absent names and explanations instead of rendering bad data',
    () {
      for (final key in ['courseName', 'studentName']) {
        for (final invalid in [null, '', ' ', 12]) {
          expect(
            () => AttentionStudent.fromJson({...attentionJson(), key: invalid}),
            throwsFormatException,
          );
        }
      }
      for (final invalid in [
        null,
        [],
        [''],
        [12],
      ]) {
        expect(
          () => AttentionStudent.fromJson({
            ...attentionJson(),
            'reasons': invalid,
          }),
          throwsFormatException,
        );
      }
    },
  );
  test('rejects nonfinite, negative and fractional source metrics', () {
    for (final invalid in [null, double.nan, double.infinity, -1, 101]) {
      expect(
        () => LearningSnapshot.fromJson({
          ...snapshotJson(),
          'progressPercent': invalid,
        }),
        throwsFormatException,
      );
    }
    for (final field in ['pendingTasks', 'overdueTasks']) {
      for (final invalid in [null, -1, 1.5, double.infinity]) {
        expect(
          () => LearningSnapshot.fromJson({...snapshotJson(), field: invalid}),
          throwsFormatException,
        );
      }
    }
  });
  test(
    'serializes app-owned actions with no actor identity or source writes',
    () {
      final body = InterventionDraft(
        courseId: 'course-test',
        studentId: 'student-test',
        title: '  Hỗ trợ ',
        note: '  Ghi nhận ',
        actionType: InterventionAction.monitoring,
        followUpAt: now,
      ).toJson();
      expect(body['title'], 'Hỗ trợ');
      expect(body['note'], 'Ghi nhận');
      expect(body.containsKey('teacherId'), isFalse);
      expect(body.containsKey('grade'), isFalse);
      expect(
        const FollowupDraft(
          note: 'Hoàn tất',
          outcomeStatus: InterventionStatus.resolved,
        ).toJson()['nextFollowUpAt'],
        isNull,
      );
    },
  );
}
