import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/student/student_flashcard_screen.dart';
import 'package:lms_mobile_app/screens/student/student_reflection_screen.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Widget _app(Widget child) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(
      size: Size(360, 640),
      viewInsets: EdgeInsets.only(bottom: 280),
    ),
    child: child,
  ),
);

void main() {
  group('flashcard API', () {
    test('uses the dev student route and parses rows', () async {
      late Uri url;
      final api = testApi(
        client: MockClient((r) async {
          url = r.url;
          return _json([
            {'id': 1, 'course_id': 14, 'front_text': 'Q', 'back_text': 'A'},
          ]);
        }),
      );
      final rows = await api.getFlashcards(14);
      expect(url.path, '/api/v1/dev/students/205/courses/14/flashcards');
      expect(rows.single['front_text'], 'Q');
    });

    test('empty list, error status and invalid JSON', () async {
      expect(
        await testApi(
          client: MockClient((_) async => _json([])),
        ).getFlashcards(14),
        isEmpty,
      );
      expect(
        testApi(
          client: MockClient((_) async => http.Response('', 403)),
        ).getFlashcards(14),
        throwsA(
          isA<Exception>().having((e) => e.toString(), 'm', contains('403')),
        ),
      );
      expect(
        testApi(
          client: MockClient((_) async => _json({'x': 1})),
        ).getFlashcards(14),
        throwsA(isA<FormatException>()),
      );
    });

    test('add, update and delete hit the dev route', () async {
      final calls = <String>[];
      final api = testApi(
        client: MockClient((r) async {
          calls.add('${r.method} ${r.url.path}');
          return _json({'status': 'success'});
        }),
      );
      await api.addFlashcard(14, 'Q', 'A');
      await api.updateFlashcard(14, 3, 'Q', 'A');
      await api.deleteFlashcard(14, 3);
      expect(calls, [
        'POST /api/v1/dev/students/205/courses/14/flashcards',
        'PUT /api/v1/dev/students/205/courses/14/flashcards/3',
        'DELETE /api/v1/dev/students/205/courses/14/flashcards/3',
      ]);
    });
  });

  group('dialogs do not overflow with the keyboard open', () {
    testWidgets('flashcard add dialog', (tester) async {
      final api = testApi(client: MockClient((_) async => _json([])));
      await tester.pumpWidget(
        _app(
          StudentFlashcardScreen(api: api, courseId: 14, courseName: 'Test'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa có thẻ ghi nhớ nào.'), findsOneWidget);
      await tester.tap(find.text('Tạo thẻ đầu tiên'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm thẻ ghi nhớ mới'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reflection add dialog', (tester) async {
      final api = testApi(client: MockClient((_) async => _json([])));
      await tester.pumpWidget(
        _app(
          StudentReflectionScreen(api: api, courseId: 14, courseName: 'Test'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ghi chép'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm nhật ký tự đánh giá'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
