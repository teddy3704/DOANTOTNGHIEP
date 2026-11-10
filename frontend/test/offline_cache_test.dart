import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/services/api_exception.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/services/offline_cache.dart';
import 'package:lms_mobile_app/widgets/offline_banner.dart';

import 'support/mock_api.dart';

http.Response _json(Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

ApiService _api(http.Client client, OfflineStore store) => ApiService(
  client: client,
  baseUrl: mockApiBaseUrl,
  localDevelopment: true,
  session: MockApiSession(),
  offlineStore: store,
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('only the summary GET paths are cacheable', () {
    for (final p in [
      '/dev/students/205/dashboard',
      '/dev/students/205/tasks',
      '/dev/students/205/courses',
      '/dev/students/205/courses/14/grades',
      '/dev/students/205/courses/14/grade-forecast',
      '/dev/students/205/courses/14/flashcards',
      '/dev/students/205/study-plan?from=2026-11-16',
      '/dev/students/205/flashcards/due',
    ]) {
      expect(isOfflineCacheable(p), isTrue, reason: p);
    }
    for (final p in [
      '/dev/students/205/notifications',
      '/dev/students/205/portal/summary',
      '/dev/teachers/102/courses',
      '/auth/demo-login',
    ]) {
      expect(isOfflineCacheable(p), isFalse, reason: p);
    }
  });

  test(
    'network error serves the cache, marks offline, blocks writes; online again clears',
    () async {
      final store = MemoryOfflineStore();
      var online = true;
      final api = _api(
        MockClient((r) async {
          if (!online) throw http.ClientException('SocketException: no route');
          return _json({'today': '2026-11-16', 'dailyMinutes': 60, 'days': []});
        }),
        store,
      );
      await api.getStudyPlan();
      await _settle();
      expect(store.entries.keys, [
        '$mockApiBaseUrl/dev/students/205/study-plan',
      ]);
      expect(
        store.entries.values.single.body,
        isNot(contains('mock-test-token')),
      );
      expect(api.offlineSince.value, isNull);

      online = false;
      final week = await api.getStudyPlan();
      expect(week.dailyMinutes, 60);
      expect(api.offlineSince.value, isNotNull);
      await expectLater(
        api.generateStudyPlan(60),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            ApiService.offlineWriteMessage,
          ),
        ),
      );

      online = true;
      await api.getStudyPlan();
      expect(api.offlineSince.value, isNull);
    },
  );

  test('no cache: the normal connection error is shown', () async {
    final api = _api(
      MockClient((r) async => throw http.ClientException('offline')),
      MemoryOfflineStore(),
    );
    await expectLater(
      api.getStudyPlan(),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('Không thể kết nối máy chủ'),
        ),
      ),
    );
    expect(api.offlineSince.value, isNull);
  });

  test('changing role or signing out empties the cache', () async {
    final store = MemoryOfflineStore();
    final api = _api(
      MockClient((r) async {
        if (r.url.path.endsWith('/demo-login')) {
          return _json({'token': 't', 'role': 'TEACHER', 'userId': 102});
        }
        return _json({'today': '2026-11-16', 'dailyMinutes': 60, 'days': []});
      }),
      store,
    );
    await api.getStudyPlan();
    await _settle();
    expect(store.entries, isNotEmpty);
    api.signOut();
    await _settle();
    expect(store.entries, isEmpty);

    await store.put('/dev/students/205/dashboard', '{}', DateTime(2026));
    api.offlineSince.value = DateTime(2026);
    try {
      await api.demoLogin('TEACHER');
    } catch (_) {
      /* login body shape is not the point here */
    }
    await _settle();
    expect(store.entries, isEmpty);
    expect(api.offlineSince.value, isNull);
  });

  testWidgets('banner shows the cached time and hides when online', (
    tester,
  ) async {
    final api = _api(MockClient((r) async => _json({})), MemoryOfflineStore());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: OfflineBanner(api: api)),
      ),
    );
    expect(find.byKey(const Key('offline-banner')), findsNothing);
    api.offlineSince.value = DateTime(2026, 11, 16, 21, 30);
    await tester.pump();
    expect(
      find.text('Đang ngoại tuyến · dữ liệu lúc 21:30 16/11'),
      findsOneWidget,
    );
    api.offlineSince.value = null;
    await tester.pump();
    expect(find.byKey(const Key('offline-banner')), findsNothing);
  });

  testWidgets(
    'offline: content below the banner does not add the status bar inset twice',
    (tester) async {
      final api = _api(
        MockClient((r) async => http.Response('', 404)),
        MemoryOfflineStore(),
      );
      api.offlineSince.value = DateTime(2026, 11, 16, 21, 30);
      double? innerTop;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(top: 24)),
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  OfflineBanner(api: api),
                  Expanded(
                    child: ValueListenableBuilder<DateTime?>(
                      valueListenable: api.offlineSince,
                      builder: (context, offline, child) =>
                          MediaQuery.removePadding(
                            context: context,
                            removeTop: offline != null,
                            child: child!,
                          ),
                      child: Builder(
                        builder: (context) {
                          innerTop = MediaQuery.paddingOf(context).top;
                          return const SizedBox.expand();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(innerTop, 0);
    },
  );

  group('FINAL-F2 isolation', () {
    const plan = {'today': '2026-11-16', 'dailyMinutes': 60, 'days': []};

    test(
      '401 and 403 are shown as errors, never covered by the cache',
      () async {
        final store = MemoryOfflineStore();
        var status = 200;
        final api = _api(
          MockClient(
            (r) async => status == 200
                ? _json(plan)
                : http.Response('{"code":"FORBIDDEN"}', status),
          ),
          store,
        );
        await api.getStudyPlan();
        await _settle();
        expect(store.entries, isNotEmpty);
        for (final code in [403, 401]) {
          status = code;
          await expectLater(
            api.getStudyPlan(),
            throwsA(
              isA<ApiException>().having((e) => e.statusCode, 'status', code),
            ),
          );
          expect(api.offlineSince.value, isNull);
        }
      },
    );

    test('another API environment never reads this cache', () async {
      final store = MemoryOfflineStore();
      await _api(MockClient((r) async => _json(plan)), store).getStudyPlan();
      await _settle();
      final other = ApiService(
        client: MockClient((r) async => throw http.ClientException('offline')),
        baseUrl: 'http://10.0.2.2:8081/api/v1',
        localDevelopment: true,
        session: MockApiSession(),
        offlineStore: store,
      );
      await expectLater(other.getStudyPlan(), throwsA(isA<ApiException>()));
      expect(other.offlineSince.value, isNull);
    });

    test(
      'an answer that arrives after sign-out is not cached or shown as offline',
      () async {
        final store = MemoryOfflineStore();
        final late = Completer<http.Response>();
        final api = _api(MockClient((r) => late.future), store);
        final pending = api.getStudyPlan();
        api.signOut();
        await _settle();
        late.complete(_json(plan));
        await pending;
        await _settle();
        expect(store.entries, isEmpty);
      },
    );

    test(
      'a failure that arrives after sign-out does not serve the old cache',
      () async {
        final store = MemoryOfflineStore();
        final late = Completer<http.Response>();
        final api = _api(MockClient((r) => late.future), store);
        final pending = api.getStudyPlan();
        api.signOut();
        await _settle();
        // Old data written by someone else after the clear (e.g. a racing write).
        await store.put(
          '$mockApiBaseUrl/dev/students/205/study-plan',
          jsonEncode(plan),
          DateTime(2026),
        );
        late.completeError(http.ClientException('offline'));
        await expectLater(pending, throwsA(isA<ApiException>()));
        expect(api.offlineSince.value, isNull);
      },
    );

    test(
      'after an app restart the saved data is still served for the same user',
      () async {
        final store = MemoryOfflineStore();
        await _api(MockClient((r) async => _json(plan)), store).getStudyPlan();
        await _settle();
        final restarted = _api(
          MockClient((r) async => throw http.ClientException('offline')),
          store,
        );
        expect((await restarted.getStudyPlan()).dailyMinutes, 60);
        expect(restarted.offlineSince.value, isNotNull);
      },
    );
  });
}
