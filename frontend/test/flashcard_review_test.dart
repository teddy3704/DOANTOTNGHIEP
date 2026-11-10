import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/models/flashcard_review.dart';
import 'package:lms_mobile_app/screens/student/flashcard_review_screen.dart';
import 'package:lms_mobile_app/screens/student/student_flashcard_screen.dart';

import 'support/mock_api.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _card(int id, {bool isNew = false, int good = 15}) => {
  'id': id,
  'courseId': 13,
  'frontText': 'Câu hỏi $id',
  'backText': 'Đáp án $id',
  'isNew': isNew,
  'repetitions': isNew ? 0 : 2,
  'easeFactor': 2.5,
  'intervalDays': isNew ? 0 : 6,
  'dueAt': null,
  'nextIntervals': {'1': 1, '3': good, '4': good, '5': good},
};

Map<String, dynamic> _due(List<Map<String, dynamic>> cards) => {
  'total': cards.length,
  'newCount': cards.where((c) => c['isNew'] == true).length,
  'reviewCount': cards.where((c) => c['isNew'] != true).length,
  'cards': cards,
};

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  group('model', () {
    test('parses due cards and button intervals', () {
      final due = DueFlashcards.fromJson(
        _due([_card(1), _card(2, isNew: true)]),
      );
      expect(due.total, 2);
      expect(due.newCount, 1);
      expect(due.cards.first.intervalFor(ReviewRating.good), 15);
      expect(due.cards.last.isNew, isTrue);
      expect(
        () => DueFlashcards.fromJson({'total': 1}),
        throwsA(isA<FormatException>()),
      );
    });

    test('interval labels', () {
      expect(intervalLabel(1), '1 ngày');
      expect(intervalLabel(29), '29 ngày');
      expect(intervalLabel(60), '2 tháng');
      expect(intervalLabel(365), '1 năm');
      expect(intervalLabel(548), '1,5 năm');
    });

    test('ratings map to SM-2 qualities 1/3/4/5', () {
      expect(ReviewRating.values.map((r) => r.value), [1, 3, 4, 5]);
    });
  });

  group('API', () {
    test('due list with and without course, review posts the rating', () async {
      final calls = <String>[];
      final api = testApi(
        client: MockClient((r) async {
          calls.add('${r.method} ${r.url.path}?${r.url.query} ${r.body}');
          if (r.method == 'POST') {
            return _json({'intervalDays': 6, 'dueAt': '2026-11-26T02:00:00Z'});
          }
          return _json(_due([_card(1)]));
        }),
      );
      expect((await api.getDueFlashcards()).total, 1);
      await api.getDueFlashcards(courseId: 13);
      final result = await api.reviewFlashcard(13, 7, ReviewRating.good);
      expect(result.intervalDays, 6);
      expect(calls, [
        'GET /api/v1/dev/students/205/flashcards/due? ',
        'GET /api/v1/dev/students/205/flashcards/due?courseId=13 ',
        'POST /api/v1/dev/students/205/courses/13/flashcards/7/review? {"rating":4}',
      ]);
    });

    test('error status is thrown', () {
      final api = testApi(
        client: MockClient((_) async => http.Response('', 404)),
      );
      expect(api.getDueFlashcards(courseId: 99), throwsA(isA<Exception>()));
    });
  });

  group('review session', () {
    testWidgets('flip, rate with interval labels, then summary', (
      tester,
    ) async {
      final posted = <String>[];
      final api = testApi(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posted.add('${r.url.path} ${r.body}');
            return _json({'intervalDays': 1});
          }
          return _json(_due([_card(1), _card(2, isNew: true, good: 1)]));
        }),
      );
      await tester.pumpWidget(
        _app(FlashcardReviewScreen(api: api, courseId: 13, courseName: 'CTDL')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Thẻ 1 / 2'), findsOneWidget);
      expect(find.text('Câu hỏi 1'), findsOneWidget);
      expect(find.byKey(const Key('rate-good')), findsNothing);

      await tester.tap(find.byKey(const Key('review-card')));
      await tester.pumpAndSettle();
      expect(find.text('Đáp án 1'), findsOneWidget);
      expect(find.text('15 ngày'), findsNWidgets(3));
      expect(find.text('1 ngày'), findsOneWidget);

      await tester.tap(find.byKey(const Key('rate-good')));
      await tester.pumpAndSettle();
      expect(find.text('Thẻ 2 / 2'), findsOneWidget);
      expect(find.text('Thẻ mới'), findsOneWidget);

      await tester.tap(find.text('Lật thẻ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rate-forgot')));
      await tester.pumpAndSettle();

      expect(find.text('Đã ôn xong 2 thẻ'), findsOneWidget);
      expect(find.text('Được: 1'), findsOneWidget);
      expect(find.text('Quên: 1'), findsOneWidget);
      expect(find.textContaining('1 thẻ bạn quên'), findsOneWidget);
      expect(posted, [
        '/api/v1/dev/students/205/courses/13/flashcards/1/review {"rating":4}',
        '/api/v1/dev/students/205/courses/13/flashcards/2/review {"rating":1}',
      ]);
    });

    testWidgets('nothing due shows an explained empty state', (tester) async {
      final api = testApi(client: MockClient((_) async => _json(_due([]))));
      await tester.pumpWidget(_app(FlashcardReviewScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay không có thẻ nào cần ôn.'), findsOneWidget);
    });

    testWidgets('failed save keeps the card and tells the student', (
      tester,
    ) async {
      final api = testApi(
        client: MockClient((r) async {
          if (r.method == 'POST') return http.Response('', 500);
          return _json(_due([_card(1)]));
        }),
      );
      await tester.pumpWidget(_app(FlashcardReviewScreen(api: api)));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('review-card')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('rate-easy')));
      await tester.pumpAndSettle();
      expect(
        find.text('Không lưu được kết quả ôn. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(find.text('Thẻ 1 / 1'), findsOneWidget);
    });

    testWidgets('load error offers retry', (tester) async {
      var fail = true;
      final api = testApi(
        client: MockClient((_) async {
          if (fail) return http.Response('', 500);
          return _json(_due([_card(1)]));
        }),
      );
      await tester.pumpWidget(_app(FlashcardReviewScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Không tải được thẻ cần ôn.'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Câu hỏi 1'), findsOneWidget);
    });
  });

  group('entry points', () {
    testWidgets('dashboard chip shows the due count and opens a session', (
      tester,
    ) async {
      final api = testApi(
        client: MockClient((_) async => _json(_due([_card(1), _card(2)]))),
      );
      await tester.pumpWidget(
        _app(Scaffold(body: DueFlashcardsChip(api: api))),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hôm nay cần ôn 2 thẻ'), findsOneWidget);
      await tester.tap(find.byKey(const Key('due-flashcards-chip')));
      await tester.pumpAndSettle();
      expect(find.text('Ôn tập hôm nay'), findsOneWidget);
    });

    testWidgets('chip is hidden when nothing is due or the call fails', (
      tester,
    ) async {
      for (final response in [_json(_due([])), http.Response('', 500)]) {
        final api = testApi(client: MockClient((_) async => response));
        await tester.pumpWidget(
          _app(
            Scaffold(
              body: DueFlashcardsChip(key: UniqueKey(), api: api),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('due-flashcards-chip')), findsNothing);
      }
    });

    testWidgets('course flashcard screen shows due count on the start button', (
      tester,
    ) async {
      final api = testApi(
        client: MockClient((r) async {
          if (r.url.path.endsWith('/flashcards/due')) {
            return _json(_due([_card(1)]));
          }
          if (r.url.path.endsWith('/flashcards')) {
            return _json([
              {'id': 1, 'course_id': 13, 'front_text': 'Q', 'back_text': 'A'},
            ]);
          }
          return _json([]);
        }),
      );
      await tester.pumpWidget(
        _app(
          StudentFlashcardScreen(api: api, courseId: 13, courseName: 'CTDL'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu ôn tập · 1 thẻ đến hạn'), findsOneWidget);
      await tester.tap(find.byKey(const Key('start-review')));
      await tester.pumpAndSettle();
      expect(find.text('Ôn tập: CTDL'), findsOneWidget);
      expect(find.text('Câu hỏi 1'), findsOneWidget);
    });
  });
}
