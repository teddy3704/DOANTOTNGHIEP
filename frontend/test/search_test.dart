import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/search_screen.dart';
import 'package:lms_mobile_app/screens/student/student_course_detail_screen.dart';

import 'support/mock_api.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets(
    'debounced, min 2 chars, grouped results, empty state, teacher path',
    (tester) async {
      final calls = <String>[];
      final api = testApi(
        client: MockClient((r) async {
          calls.add('${r.url.path}?${r.url.query}');
          if (r.url.queryParameters['q'] == 'zz') return _json({'results': []});
          return _json({
            'results': [
              {'type': 'course', 'title': 'Kiểm thử phần mềm', 'courseId': 13},
              {
                'type': 'task',
                'title': 'Bài tập kiểm thử',
                'subtitle': 'Kiểm thử phần mềm',
                'courseId': 13,
              },
              {
                'type': 'flashcard',
                'title': 'Kiểm thử hộp trắng là gì?',
                'subtitle': 'Kiểm thử phần mềm',
                'courseId': 13,
              },
            ],
            'total': 3,
          });
        }),
      );
      await tester.pumpWidget(MaterialApp(home: SearchScreen(api: api)));
      await tester.enterText(find.byKey(const Key('search-field')), 'k');
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, isEmpty);

      await tester.enterText(find.byKey(const Key('search-field')), 'kie');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(find.byKey(const Key('search-field')), 'kiem thu');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(calls, ['/api/v1/dev/students/205/search?q=kiem+thu']);
      expect(find.text('Khóa học'), findsOneWidget);
      expect(find.text('Việc cần làm'), findsOneWidget);
      expect(find.text('Thẻ ghi nhớ'), findsOneWidget);
      expect(find.text('Bài tập kiểm thử'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('search-field')), 'zz');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Không tìm thấy kết quả'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(home: SearchScreen(api: api, teacher: true)),
      );
      await tester.enterText(
        find.byKey(const Key('search-field')),
        "' OR 1=1 --",
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(calls.last, '/api/v1/dev/teachers/102/search?q=%27+OR+1%3D1+--');
    },
  );

  testWidgets('an older, slower answer never replaces the newer one', (
    tester,
  ) async {
    final slow = Completer<http.Response>();
    final api = testApi(
      client: MockClient((r) {
        final q = r.url.queryParameters['q'];
        if (q == 'kiem') return slow.future;
        return Future.value(
          _json({
            'results': [
              {'type': 'course', 'title': 'Kiểm thử phần mềm', 'courseId': 13},
            ],
          }),
        );
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(api: api, debounce: const Duration(milliseconds: 1)),
      ),
    );
    await tester.enterText(find.byKey(const Key('search-field')), 'kiem');
    await tester.pump(const Duration(milliseconds: 5));
    await tester.enterText(find.byKey(const Key('search-field')), 'kiem thu');
    await tester.pump(const Duration(milliseconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Kiểm thử phần mềm'), findsOneWidget);
    slow.complete(
      _json({
        'results': [
          {'type': 'course', 'title': 'Kết quả cũ', 'courseId': 99},
        ],
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kết quả cũ'), findsNothing);
    expect(find.text('Kiểm thử phần mềm'), findsOneWidget);
  });

  testWidgets('tapping a student course result opens that course', (
    tester,
  ) async {
    final api = testApi(
      client: MockClient((r) async {
        if (r.url.path.endsWith('/search')) {
          return _json({
            'results': [
              {'type': 'course', 'title': 'Kiểm thử phần mềm', 'courseId': 13},
            ],
          });
        }
        return http.Response('', 404);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(api: api, debounce: const Duration(milliseconds: 1)),
      ),
    );
    await tester.enterText(find.byKey(const Key('search-field')), 'dao');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kiểm thử phần mềm'));
    await tester.pumpAndSettle();
    final page = tester.widget<StudentCourseDetailScreen>(
      find.byType(StudentCourseDetailScreen),
    );
    expect(page.course.courseId, 13);
  });
}
