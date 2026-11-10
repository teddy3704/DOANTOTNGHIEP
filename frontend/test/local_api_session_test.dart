import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/constants/api_constants.dart';
import 'package:lms_mobile_app/services/api_exception.dart';
import 'package:lms_mobile_app/services/api_service.dart';

const _baseUrl = 'http://127.0.0.1:8081/api/v1';
http.Response _json(Object body, [int code = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  code,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('HTTP is accepted only for explicitly enabled local hosts', () {
    for (final host in ['localhost', '127.0.0.1', '10.0.2.2']) {
      expect(
        ApiConstants.validateBaseUrl(
          'http://$host:8081/api/v1',
          localDevelopment: true,
        ).port,
        8081,
      );
    }
    for (final url in [
      'http://example.com/api/v1',
      'http://localhost:8081/api/v1?token=not-a-secret',
      'http://user:password@localhost/api/v1',
      '',
    ]) {
      expect(
        () => ApiConstants.validateBaseUrl(url, localDevelopment: true),
        throwsFormatException,
      );
    }
    expect(
      () => ApiConstants.validateBaseUrl(_baseUrl, localDevelopment: false),
      throwsFormatException,
    );
    expect(
      ApiConstants.validateBaseUrl(
        'https://example.com/api/v1',
        localDevelopment: false,
      ).scheme,
      'https',
    );
  });

  test(
    'login obtains server identity and injects Bearer on subsequent requests',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        baseUrl: _baseUrl,
        localDevelopment: true,
        client: MockClient((request) async {
          requests.add(request);
          if (request.url.path.endsWith('/demo-login')) {
            return _json({
              'token': 'mock-token',
              'userId': '901',
              'role': 'STUDENT',
            });
          }
          return _json([
            {'content': 'Tự đánh giá tiếng Việt'},
          ]);
        }),
      );
      addTearDown(api.dispose);
      await api.demoLogin('student');
      final rows = await api.getReflections();
      expect(requests[0].url.path, '/api/v1/auth/demo-login');
      expect(requests[0].headers['authorization'], isNull);
      expect(jsonDecode(requests[0].body), {'role': 'STUDENT'});
      expect(requests[1].url.path, '/api/v1/dev/students/901/reflections');
      expect(requests[1].headers['authorization'], 'Bearer mock-token');
      expect(rows.single['content'], 'Tự đánh giá tiếng Việt');
      api.signOut();
      expect(api.session.token, isNull);
    },
  );

  test('disabled local login makes no network request', () async {
    var calls = 0;
    final api = ApiService(
      baseUrl: _baseUrl,
      client: MockClient((_) async {
        calls++;
        return _json({});
      }),
    );
    addTearDown(api.dispose);
    await expectLater(api.demoLogin('STUDENT'), throwsA(isA<ApiException>()));
    expect(calls, 0);
  });

  test('mismatched login role never becomes a session', () async {
    final api = ApiService(
      baseUrl: _baseUrl,
      localDevelopment: true,
      client: MockClient(
        (_) async =>
            _json({'token': 'mock-token', 'userId': 901, 'role': 'TEACHER'}),
      ),
    );
    addTearDown(api.dispose);
    await expectLater(api.demoLogin('STUDENT'), throwsFormatException);
    expect(api.session.token, isNull);
  });

  test('401 clears session without falling back to fixture data', () async {
    final api = ApiService(
      baseUrl: _baseUrl,
      localDevelopment: true,
      client: MockClient(
        (request) async => request.url.path.endsWith('/demo-login')
            ? _json({'token': 'mock-token', 'userId': 901, 'role': 'STUDENT'})
            : _json({'private': 'not displayed'}, 401),
      ),
    );
    addTearDown(api.dispose);
    await api.demoLogin('STUDENT');
    await expectLater(
      api.getReflections(),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
    );
    expect(api.session.token, isNull);
  });

  test('notes GET POST PUT share injected transport, UTF-8 and auth', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      baseUrl: _baseUrl,
      localDevelopment: true,
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/demo-login')) {
          return _json({
            'token': 'mock-teacher',
            'userId': 902,
            'role': 'TEACHER',
          });
        }
        if (request.method == 'GET') {
          return _json([
            {'id': 7, 'note': 'Cần hỗ trợ'},
          ]);
        }
        return http.Response('', 204);
      }),
    );
    addTearDown(api.dispose);
    await api.demoLogin('TEACHER');
    expect(
      (await api.getTeacherNotes(901, courseId: 14)).single['note'],
      'Cần hỗ trợ',
    );
    await api.addTeacherNote(901, 'Nhắc học bài', courseId: 14);
    await api.updateTeacherNoteStatus(7, 'resolved');
    for (final request in requests.skip(1)) {
      expect(request.headers['authorization'], 'Bearer mock-teacher');
      expect(request.url.path, startsWith('/api/v1/teachers/902/notes'));
    }
    expect(requests[1].url.queryParameters, {
      'studentId': '901',
      'courseId': '14',
    });
    expect(jsonDecode(requests[2].body)['note'], 'Nhắc học bài');
    expect(requests.last.method, 'PUT');
    expect(jsonDecode(requests.last.body), {'status': 'resolved'});
  });

  test('network timeout maps to a readable error', () async {
    final api = ApiService(
      baseUrl: _baseUrl,
      localDevelopment: true,
      requestTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.dispose);
    await expectLater(
      api.demoLogin('STUDENT'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('quá lâu'),
        ),
      ),
    );
  });
}
