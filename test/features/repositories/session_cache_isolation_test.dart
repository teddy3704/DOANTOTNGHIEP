import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/profile/domain/app_user.dart';
import 'package:dlu_lms_mobile/features/profile/domain/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'auth-dependent data is reloaded after its listeners are released',
    () async {
      final courseRepository = _CountingCourseRepository();
      final userRepository = _CountingUserRepository();
      final container = ProviderContainer(
        overrides: <Override>[
          courseRepositoryProvider.overrideWithValue(courseRepository),
          userRepositoryProvider.overrideWithValue(userRepository),
        ],
      );
      addTearDown(container.dispose);

      final coursesSubscription = container.listen(
        myCoursesProvider,
        (_, _) {},
      );
      final detailSubscription = container.listen(
        courseDetailProvider('course-a'),
        (_, _) {},
      );
      final userSubscription = container.listen(currentUserProvider, (_, _) {});

      await container.read(myCoursesProvider.future);
      await container.read(courseDetailProvider('course-a').future);
      await container.read(currentUserProvider.future);

      expect(courseRepository.listCalls, 1);
      expect(courseRepository.detailCalls, 1);
      expect(userRepository.calls, 1);

      coursesSubscription.close();
      detailSubscription.close();
      userSubscription.close();
      await container.pump();

      expect(container.exists(myCoursesProvider), isFalse);
      expect(container.exists(courseDetailProvider('course-a')), isFalse);
      expect(container.exists(currentUserProvider), isFalse);

      final nextCoursesSubscription = container.listen(
        myCoursesProvider,
        (_, _) {},
      );
      final nextDetailSubscription = container.listen(
        courseDetailProvider('course-a'),
        (_, _) {},
      );
      final nextUserSubscription = container.listen(
        currentUserProvider,
        (_, _) {},
      );
      addTearDown(nextCoursesSubscription.close);
      addTearDown(nextDetailSubscription.close);
      addTearDown(nextUserSubscription.close);

      await container.read(myCoursesProvider.future);
      await container.read(courseDetailProvider('course-a').future);
      await container.read(currentUserProvider.future);

      expect(courseRepository.listCalls, 2);
      expect(courseRepository.detailCalls, 2);
      expect(userRepository.calls, 2);
    },
  );
}

class _CountingCourseRepository implements CourseRepository {
  int listCalls = 0;
  int detailCalls = 0;

  static const _course = Course(
    id: 'course-a',
    shortName: 'COURSE-A',
    fullName: 'Synthetic course',
    category: 'DEV TEST',
    accentIndex: 0,
  );

  @override
  Future<List<Course>> getMyCourses() async {
    listCalls++;
    return const <Course>[_course];
  }

  @override
  Future<Course> getCourse(String courseId) async {
    detailCalls++;
    return _course;
  }
}

class _CountingUserRepository implements UserRepository {
  int calls = 0;

  @override
  Future<AppUser> getCurrentUser() async {
    calls++;
    return const AppUser(
      id: 'user-a',
      displayName: 'Synthetic User',
      email: 'synthetic@example.test',
      roleLabel: 'DEV TEST',
      faculty: 'Synthetic faculty',
    );
  }
}
