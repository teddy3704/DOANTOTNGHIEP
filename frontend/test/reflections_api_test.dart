import 'support/mock_api.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  http.Response json(Object body, [int status = 200]) => http.Response.bytes(
    utf8.encode(jsonEncode(body)),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test('getReflections calls the dev student route and parses rows', () async {
    late Uri requested;
    final api = testApi(
      client: MockClient((request) async {
        requested = request.url;
        return json([
          {
            'id': 1,
            'user_id': 205,
            'course_id': 14,
            'content': 'Hiểu bài',
            'understanding_level': 2,
            'created_at': '2026-10-10T08:00:00',
          },
          {
            'id': 2,
            'user_id': 205,
            'course_id': null,
            'content': 'Ghi chú',
            'understanding_level': null,
            'created_at': null,
          },
        ]);
      }),
    );

    final rows = await api.getReflections();

    expect(requested.path, '/api/v1/dev/students/205/reflections');
    expect(requested.hasQuery, isFalse);
    expect(rows, hasLength(2));
    expect(rows[0]['content'], 'Hiểu bài');
    expect(rows[1]['understanding_level'], isNull);
    expect(rows[1]['course_id'], isNull);
  });

  test('getReflections sends courseId and studentId', () async {
    late Uri requested;
    final api = testApi(
      client: MockClient((request) async {
        requested = request.url;
        return json([]);
      }),
    );

    await api.getReflections(studentId: 7, courseId: 14);

    expect(requested.path, '/api/v1/dev/students/7/reflections');
    expect(requested.queryParameters, {'courseId': '14'});
  });

  test('getReflections returns an empty list for an empty array', () async {
    final api = testApi(client: MockClient((_) async => json([])));
    expect(await api.getReflections(), isEmpty);
  });

  test('getReflections accepts a data envelope', () async {
    final api = testApi(
      client: MockClient(
        (_) async => json({
          'data': [
            {'id': 1, 'content': 'x'},
          ],
        }),
      ),
    );
    expect(await api.getReflections(), hasLength(1));
  });

  test(
    'getReflections surfaces the HTTP status instead of an empty list',
    () async {
      final api = testApi(
        client: MockClient((_) async => http.Response('', 403)),
      );
      expect(
        api.getReflections(),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('403'),
          ),
        ),
      );
    },
  );

  test('getReflections rejects invalid JSON shapes', () async {
    expect(
      testApi(
        client: MockClient((_) async => json({'status': 'ok'})),
      ).getReflections(),
      throwsA(isA<FormatException>()),
    );
    expect(
      testApi(client: MockClient((_) async => json([1, 2]))).getReflections(),
      throwsA(isA<FormatException>()),
    );
    expect(
      testApi(
        client: MockClient((_) async => http.Response('<html>', 200)),
      ).getReflections(),
      throwsA(isA<FormatException>()),
    );
  });

  test('addReflection posts to the dev route with the payload', () async {
    late http.Request captured;
    final api = testApi(
      client: MockClient((request) async {
        captured = request;
        return json({'status': 'success'});
      }),
    );

    await api.addReflection('Nội dung', 4, courseId: 14);

    expect(captured.method, 'POST');
    expect(captured.url.path, '/api/v1/dev/students/205/reflections');
    expect(jsonDecode(captured.body), {
      'content': 'Nội dung',
      'understandingLevel': 4,
      'courseId': 14,
    });
  });

  test('addReflection throws on a server error', () async {
    final api = testApi(
      client: MockClient((_) async => http.Response('', 400)),
    );
    expect(api.addReflection('x', 3), throwsException);
  });
}
