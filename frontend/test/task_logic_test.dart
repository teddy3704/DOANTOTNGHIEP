import 'package:flutter_test/flutter_test.dart';
import 'package:lms_mobile_app/models/student_course_detail.dart';
import 'package:lms_mobile_app/screens/student/student_task_center_screen.dart';

void main() {
  group('StudentTask logic', () {
    final now = DateTime(2026, 10, 10, 12, 0, 0); // Mock current time

    test('isDone correctly identifies completed tasks', () {
      final t1 = StudentTask.fromJson({'task_status': 'completed'});
      final t2 = StudentTask.fromJson({
        'task_type': 'assignment',
        'source_status': 'submitted',
      });
      final t3 = StudentTask.fromJson({
        'task_type': 'quiz',
        'quiz_state': 'finished',
      });
      final t4 = StudentTask.fromJson({'task_status': 'pending'});

      expect(t1.isDone, isTrue);
      expect(t2.isDone, isTrue);
      expect(t3.isDone, isTrue);
      expect(t4.isDone, isFalse);
    });

    test('isOverdue correctly identifies overdue tasks', () {
      final past =
          now.subtract(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;
      final future =
          now.add(const Duration(days: 1)).millisecondsSinceEpoch ~/ 1000;

      // Unfinished, past deadline -> Overdue
      final t1 = StudentTask.fromJson({
        'task_status': 'pending',
        'due_time': past,
      });
      // Finished, past deadline -> Not Overdue
      final t2 = StudentTask.fromJson({
        'task_status': 'completed',
        'due_time': past,
      });
      // Unfinished, future deadline -> Not Overdue
      final t3 = StudentTask.fromJson({
        'task_status': 'pending',
        'due_time': future,
      });
      // Overdue status explicitly set -> Overdue
      final t4 = StudentTask.fromJson({
        'task_status': 'overdue',
        'due_time': future,
      });

      expect(t1.isOverdue(now), isTrue);
      expect(t2.isOverdue(now), isFalse);
      expect(t3.isOverdue(now), isFalse);
      expect(t4.isOverdue(now), isTrue);
    });

    test('isDueSoon correctly identifies tasks due within 48h', () {
      final in10Hours =
          now.add(const Duration(hours: 10)).millisecondsSinceEpoch ~/ 1000;
      final in50Hours =
          now.add(const Duration(hours: 50)).millisecondsSinceEpoch ~/ 1000;

      final t1 = StudentTask.fromJson({
        'task_status': 'pending',
        'due_time': in10Hours,
      });
      final t2 = StudentTask.fromJson({
        'task_status': 'pending',
        'due_time': in50Hours,
      });
      final t3 = StudentTask.fromJson({
        'task_status': 'completed',
        'due_time': in10Hours,
      });

      expect(t1.isDueSoon(now), isTrue);
      expect(t2.isDueSoon(now), isFalse);
      expect(t3.isDueSoon(now), isFalse); // Done tasks are not due soon
    });

    test('filterTasks applies correct filters', () {
      final past =
          now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch ~/ 1000;
      final future =
          now.add(const Duration(hours: 10)).millisecondsSinceEpoch ~/ 1000;

      final tasks = [
        StudentTask.fromJson({
          'source_id': 1,
          'task_status': 'pending',
          'due_time': past,
        }), // Overdue
        StudentTask.fromJson({
          'source_id': 2,
          'task_status': 'pending',
          'due_time': future,
        }), // Soon
        StudentTask.fromJson({
          'source_id': 3,
          'task_status': 'completed',
          'due_time': past,
        }), // Done
      ];

      final pending = filterTasks(tasks, TaskFilter.pending, now);
      expect(pending.length, 2);
      expect(pending.map((t) => t.sourceId), containsAll([1, 2]));

      final overdue = filterTasks(tasks, TaskFilter.overdue, now);
      expect(overdue.length, 1);
      expect(overdue.first.sourceId, 1);

      final soon = filterTasks(tasks, TaskFilter.soon, now);
      expect(soon.length, 1);
      expect(soon.first.sourceId, 2);

      final done = filterTasks(tasks, TaskFilter.done, now);
      expect(done.length, 1);
      expect(done.first.sourceId, 3);
    });

    test('sorted is stable for tasks with same deadline', () {
      final time = now.millisecondsSinceEpoch ~/ 1000;
      final tasks = [
        StudentTask.fromJson({
          'source_id': 3,
          'task_status': 'pending',
          'task_type': 'assignment',
          'due_time': time,
        }),
        StudentTask.fromJson({
          'source_id': 1,
          'task_status': 'pending',
          'task_type': 'quiz',
          'due_time': time,
        }),
        StudentTask.fromJson({
          'source_id': 2,
          'task_status': 'pending',
          'task_type': 'assignment',
          'due_time': time,
        }),
      ];

      final sorted = StudentTask.sorted(tasks, now);

      // All have same priority and same deadline.
      // Next sort criteria is type (assignment < quiz).
      // Then sourceId.
      expect(sorted[0].sourceId, 2); // assignment, id 2
      expect(sorted[1].sourceId, 3); // assignment, id 3
      expect(sorted[2].sourceId, 1); // quiz, id 1
    });
  });
}
