import 'dart:async';

import 'package:dlu_lms_mobile/core/external_links/official_lms_launcher.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_content.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_content_repository.dart';
import 'package:dlu_lms_mobile/features/courses/domain/course_repository.dart';
import 'package:dlu_lms_mobile/features/courses/presentation/screens/course_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('course detail renders contextual loading then empty content', (
    tester,
  ) async {
    final completer = Completer<Course>();

    await tester.pumpWidget(
      _courseDetailApp(
        courseRepository: _MemoryCourseRepository(
          onGetCourse: (_) => completer.future,
        ),
        contentRepository: const _MemoryCourseContentRepository(
          <CourseSection>[],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Đang tải khóa học…'), findsOneWidget);

    completer.complete(_course);
    await tester.pumpAndSettle();

    expect(find.text('Nội dung khóa học'), findsOneWidget);
    expect(find.text('Chưa có nội dung'), findsOneWidget);
    expect(find.text('Nội dung môn học sẽ xuất hiện tại đây.'), findsOneWidget);
  });

  testWidgets('assignment without a due date does not crash', (tester) async {
    const sections = <CourseSection>[
      CourseSection(
        id: 'topic-1',
        courseId: 'course-1',
        number: 1,
        name: 'Bắt đầu môn học',
        activities: <CourseActivity>[
          CourseActivity(
            id: 'item-1',
            instanceId: 'assignment-1',
            kind: CourseActivityKind.assignment,
            name: 'Bài tập khởi động',
            visible: true,
            statusLabel: 'Chưa nộp',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      _courseDetailApp(
        courseRepository: _MemoryCourseRepository(
          onGetCourse: (_) async => _course,
        ),
        contentRepository: const _MemoryCourseContentRepository(sections),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bài tập khởi động'), findsOneWidget);
    expect(find.text('Bài tập · Chưa nộp'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('resource details are scroll-safe on a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const resourceName = 'Hướng dẫn chuẩn bị bài học';
    const sections = <CourseSection>[
      CourseSection(
        id: 'topic-1',
        courseId: 'course-1',
        number: 1,
        name: 'Tài liệu nhập môn',
        activities: <CourseActivity>[
          CourseActivity(
            id: 'item-2',
            instanceId: 'resource-1',
            kind: CourseActivityKind.resource,
            name: resourceName,
            visible: true,
            description:
                'Tài liệu giúp sinh viên chuẩn bị kiến thức và các bước thực hành trước buổi học.',
            fileName: 'huong-dan-chuan-bi-bai-hoc.pdf',
            mimeType: 'application/pdf',
            fileSize: 1572864,
          ),
        ],
      ),
    ];

    final launchedUris = <Uri>[];
    await tester.pumpWidget(
      _courseDetailApp(
        courseRepository: _MemoryCourseRepository(
          onGetCourse: (_) async => _course,
        ),
        contentRepository: const _MemoryCourseContentRepository(sections),
        lmsLauncher: OfficialLmsLauncher(
          lmsBaseUri: Uri.parse('https://lms.dlu.edu.vn'),
          launch: (uri) async {
            launchedUris.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(resourceName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(resourceName));
    await tester.pumpAndSettle();

    expect(find.text('Thông tin tài liệu'), findsOneWidget);
    await tester.ensureVisible(find.text('PDF'));
    expect(find.text('1.5 MB'), findsOneWidget);
    await tester.ensureVisible(find.text('Mở LMS'));
    await tester.tap(find.text('Mở LMS'));
    await tester.pump();
    expect(launchedUris, <Uri>[Uri.parse('https://lms.dlu.edu.vn')]);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _courseDetailApp({
  required CourseRepository courseRepository,
  required CourseContentRepository contentRepository,
  OfficialLmsLauncher? lmsLauncher,
}) => ProviderScope(
  overrides: <Override>[
    courseRepositoryProvider.overrideWithValue(courseRepository),
    courseContentRepositoryProvider.overrideWithValue(contentRepository),
    if (lmsLauncher != null)
      officialLmsLauncherProvider.overrideWithValue(lmsLauncher),
  ],
  child: const MaterialApp(home: CourseDetailScreen(courseId: 'course-1')),
);

const _course = Course(
  id: 'course-1',
  shortName: 'MOB301',
  fullName: 'Phát triển ứng dụng di động',
  category: 'Công nghệ thông tin',
  accentIndex: 0,
  summary: 'Xây dựng ứng dụng đa nền tảng theo quy trình hiện đại.',
);

class _MemoryCourseRepository implements CourseRepository {
  const _MemoryCourseRepository({required this.onGetCourse});

  final Future<Course> Function(String courseId) onGetCourse;

  @override
  Future<Course> getCourse(String courseId) => onGetCourse(courseId);

  @override
  Future<List<Course>> getMyCourses() async => const <Course>[_course];
}

class _MemoryCourseContentRepository implements CourseContentRepository {
  const _MemoryCourseContentRepository(this.sections);

  final List<CourseSection> sections;

  @override
  Future<List<CourseSection>> getSections(String courseId) async => sections;
}
