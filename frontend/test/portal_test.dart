import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/core/gpa_simulator.dart';
import 'package:lms_mobile_app/models/portal.dart';
import 'package:lms_mobile_app/screens/portal_sources_screen.dart';
import 'package:lms_mobile_app/screens/student/academic_record_screen.dart';
import 'package:lms_mobile_app/screens/student/portal/gpa_simulation_tab.dart';
import 'package:lms_mobile_app/screens/teacher/advisor_class_screen.dart';
import 'package:lms_mobile_app/services/api_exception.dart';

import 'support/mock_api.dart';

// Invented values only (docs/V3_PORTAL_PROMPT.md §2.9).
http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _until = {'yearStudy': '2099-2100', 'termId': 'HK01'};

final _summary = {
  'cumulativeGpa4': 3.19,
  'cumulativeGpa10': 7.6,
  'cumulativeCredits': 16,
  'rank': 'Khá',
  'band': 'Khá',
  'remainingCompulsoryCredits': 10,
  'dataUntil': _until,
};

Map<String, dynamic> _course(String code, String name, {String? letter}) => {
  'code': code,
  'name': name,
  'credits': 3,
  'score10': letter == null ? null : (letter == 'F' ? 3.5 : 8.0),
  'score4': letter == null ? null : (letter == 'F' ? 0 : 3),
  'letter': letter,
  'scored': letter != null,
  'passed': letter != null && letter != 'F',
};

final _transcript = {
  'dataUntil': _until,
  'summary': _summary,
  'terms': [
    {
      'yearStudy': '2098-2099',
      'termId': 'HK01',
      'gpa4': 3.0,
      'cumulativeGpa4': 3.0,
      'hasScores': true,
      'courses': [_course('TIN1001', 'Nhập môn lập trình', letter: 'A')],
    },
    {
      'yearStudy': '2098-2099',
      'termId': 'HK02',
      'gpa4': 1.29,
      'cumulativeGpa4': 2.08,
      'hasScores': true,
      'courses': [
        _course('TIN1003', 'Cấu trúc dữ liệu', letter: 'B'),
        _course('TIN1004', 'Cơ sở dữ liệu', letter: 'F'),
      ],
    },
    {
      'yearStudy': '2099-2100',
      'termId': 'HK02',
      'hasScores': false,
      'courses': [_course('TIN3206', 'Kiểm thử phần mềm')],
    },
  ],
};

final _program = {
  'programId': 'CQ99CT-PM',
  'summary': {
    'compulsoryCredits': 23,
    'compulsoryPassedCredits': 13,
    'electivePassedCredits': 3,
    'completionPercent': 56.5,
    'statusCounts': {'PASSED': 5, 'IN_LMS': 2, 'NOT_TAKEN': 2},
  },
  'semesters': [
    {
      'semester': 'Học kỳ 5',
      'courses': [
        {
          'code': 'TIN3206',
          'name': 'Kiểm thử phần mềm',
          'credits': 3,
          'compulsory': true,
          'status': 'IN_LMS',
          'lmsCourseName': 'Software Testing',
        },
      ],
    },
  ],
  'eligible': [
    {
      'code': 'TIN2002',
      'name': 'Mạng máy tính',
      'credits': 3,
      'compulsory': true,
    },
  ],
  'blocked': [
    {
      'code': 'TIN3302',
      'name': 'Đồ án chuyên ngành',
      'credits': 4,
      'compulsory': true,
      'missing': ['TIN3206'],
    },
  ],
};

final _bands = [
  {'name': 'Xuất sắc', 'min': 3.6},
  {'name': 'Giỏi', 'min': 3.2},
  {'name': 'Khá', 'min': 2.5},
  {'name': 'Trung bình', 'min': 2.0},
];

final _conversion = [
  {'letter': 'A', 'min10': 8.6, 'score4': 4, 'derived': true},
  {'letter': 'B', 'min10': 7.0, 'score4': 3, 'derived': true},
  {'letter': 'C', 'min10': 6.0, 'score4': 2, 'derived': true},
  {'letter': 'D', 'min10': 4.0, 'score4': 1, 'derived': false},
  {'letter': 'F', 'min10': 3.5, 'score4': 0, 'derived': true},
];

final _sim = {
  'dataUntil': _until,
  'gpa4': 3.19,
  'credits': 16,
  'remainingCredits': 13,
  'bands': _bands,
  'conversion': _conversion,
  'courses': [
    {
      'code': 'TIN3206',
      'name': 'Kiểm thử phần mềm',
      'credits': 3,
      'status': 'IN_LMS',
      'lmsCourseName': 'Software Testing',
      'forecastPercent': 82.0,
      'forecastLetter': 'B',
    },
    {
      'code': 'TIN2002',
      'name': 'Mạng máy tính',
      'credits': 3,
      'status': 'NOT_TAKEN',
    },
  ],
};

final _overview = {
  'classId': 'ITK99Z',
  'term': {'yearStudy': '2099-2100', 'termId': 'HK01'},
  'terms': [
    {'yearStudy': '2099-2100', 'termId': 'HK01'},
    {'yearStudy': '2098-2099', 'termId': 'HK02'},
  ],
  'previousTerm': {'yearStudy': '2098-2099', 'termId': 'HK02'},
  'size': 3,
  'ranks': {'Giỏi': 1, 'Khá': 1, 'Yếu': 1},
  'histogram': [
    {'from': 0, 'to': 1, 'count': 0},
    {'from': 1, 'to': 2, 'count': 1},
    {'from': 2, 'to': 2.5, 'count': 0},
    {'from': 2.5, 'to': 3.2, 'count': 1},
    {'from': 3.2, 'to': 3.6, 'count': 1},
    {'from': 3.6, 'to': 4, 'count': 0},
  ],
  'averageGpa4': 2.73,
  'previousAverageGpa4': 2.67,
  'trend': 0.06,
  'attentionCount': 1,
  'mask': false,
  'students': [
    {
      'no': 1,
      'name': 'Nguyễn Văn An',
      'studentId': '2399Z001',
      'gpa4': 3.0,
      'rank': 'Khá',
      'conduct': 80,
      'flags': [],
    },
    {
      'no': 2,
      'name': 'Lê Cường',
      'studentId': '2399Z002',
      'gpa4': 1.8,
      'rank': 'Yếu',
      'conduct': 45,
      'flags': ['LOW_GPA', 'WEAK_RANK', 'LOW_CONDUCT'],
    },
  ],
};

Map<String, dynamic> _masked(Map<String, dynamic> o) => {
  ...o,
  'mask': true,
  'students': [
    for (final s in o['students'] as List)
      {
        ...s as Map<String, dynamic>,
        'name': 'SV 0${s['no']}',
        'studentId': '23**Z0**',
      },
  ],
};

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  group('models and engine', () {
    test('transcript, program and simulation parse', () {
      final t = Transcript.fromJson(_transcript);
      expect(t.terms, hasLength(3));
      expect(t.scoredTerms, hasLength(2));
      expect(t.dataUntil!.label, 'Dữ liệu Portal đến HK1 năm 2099-2100');
      expect(t.terms[1].courses[1].failed, isTrue);
      final p = ProgramProgress.fromJson(_program);
      expect(p.counts[ProgramStatus.inLms], 2);
      expect(p.blocked.single.missing, ['TIN3206']);
      expect(p.semesters.single.courses.single.status, ProgramStatus.inLms);
      expect(() => Transcript.fromJson({'summary': {}}), throwsFormatException);
    });

    test('GPA engine matches the backend numbers', () {
      final e = GpaSimulator.of(GpaSimulation.fromJson(_sim));
      final now = e.simulate(const []);
      expect(
        now.targets[0].status,
        TargetStatus.notFeasible,
      ); // Xuất sắc 4.1046
      expect(now.targets[1].needed, closeTo(3.2123, 1e-4)); // Giỏi
      expect(now.targets[3].needed, closeTo(0.5354, 1e-4));
      final r = e.simulate(const [(3, 'B')]);
      expect(r.projectedGpa, closeTo(3.16, 1e-9));
      expect(r.band, 'Khá');
      expect(r.remainingCredits, 10);
      final none = GpaSimulator(
        gpa: 3.25,
        credits: 120,
        remainingCredits: 0,
        bands: e.bands,
        conversion: e.conversion,
      ).simulate(const []);
      expect(none.targets[1].status, TargetStatus.achieved);
      expect(none.targets[0].status, TargetStatus.notFeasible);
    });

    test('number and term labels', () {
      expect(vn(3.1875), '3,19');
      expect(vn(null), '—');
      expect(termLabel('HK02'), 'HK2');
    });
  });

  group('API', () {
    test('student and teacher paths, error codes', () async {
      final paths = <String>[];
      final api = testApi(
        client: MockClient((r) async {
          paths.add('${r.url.path}${r.url.hasQuery ? '?${r.url.query}' : ''}');
          if (r.url.path.endsWith('/decisions')) {
            return _json({'status': 404, 'code': 'PORTAL_NOT_LINKED'}, 404);
          }
          if (r.url.path.endsWith('/conduct')) {
            return _json({'code': 'PORTAL_UNAVAILABLE'}, 503);
          }
          return _json(_overview);
        }),
      );
      await api.getAdvisorOverview(
        'ITK99Z',
        term: const AdvisorTerm('2098-2099', 'HK02'),
        mask: true,
      );
      expect(
        paths.single,
        '/api/v1/dev/teachers/102/portal/advisor/classes/ITK99Z?yearStudy=2098-2099&termId=HK02&mask=true',
      );
      await expectLater(
        api.getDecisions(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.portalNotLinked, 'notLinked', isTrue)
              .having((e) => e.statusCode, 'status', 404),
        ),
      );
      await expectLater(
        api.getConduct(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Portal đào tạo đang không phản hồi'),
          ),
        ),
      );
    });

    test('client cache: reuse, refresh, cleared on sign-out', () async {
      var calls = 0;
      final api = testApi(
        client: MockClient((_) async {
          calls++;
          return _json(_summary);
        }),
      );
      await api.getPortalSummary();
      await api.getPortalSummary();
      expect(calls, 1);
      await api.getPortalSummary(refresh: true);
      expect(calls, 2);
      api.signOut();
      await api.getPortalSummary(); // cache was cleared: fetched again
      expect(calls, 3);
    });

    test('CSV export asks for text, unmasked and confirmed', () async {
      late http.Request req;
      final api = testApi(
        client: MockClient((r) async {
          req = r;
          return http.Response.bytes(utf8.encode('﻿STT,MSSV\r\n'), 200);
        }),
      );
      final csv = await api.exportAdvisorCsv('ITK99Z');
      expect(csv, startsWith('STT')); // decoder drops the BOM
      expect(req.url.queryParameters, {'mask': 'false', 'confirm': 'true'});
      expect(req.headers['Accept'], contains('text/csv'));
    });
  });

  group('student screens', () {
    MockClient studentBackend({Map<String, http.Response>? override}) =>
        MockClient((r) async {
          final p = r.url.path;
          for (final e in (override ?? {}).entries) {
            if (p.endsWith(e.key)) return e.value;
          }
          if (p.endsWith('/transcript')) return _json(_transcript);
          if (p.endsWith('/program')) return _json(_program);
          if (p.endsWith('/gpa-simulation')) return _json(_sim);
          if (p.endsWith('/conduct')) {
            return _json({
              'terms': [
                {
                  'yearStudy': '2098-2099',
                  'termId': 'HK01',
                  'selfScore': 85,
                  'classScore': 82,
                  'departmentScore': 82,
                  'finalScore': 82,
                  'classification': 'Tốt',
                },
              ],
              'average': 82.0,
            });
          }
          if (p.endsWith('/decisions')) {
            return _json({
              'decisions': [
                {
                  'name': 'Cảnh báo học vụ lần 1',
                  'signDate': '2100-02-15',
                  'academicWarning': true,
                },
              ],
              'warningCount': 1,
            });
          }
          if (p.endsWith('/summary')) return _json(_summary);
          return _json({});
        });

    testWidgets('transcript with failed filter', (tester) async {
      await tester.pumpWidget(
        _app(AcademicRecordScreen(api: testApi(client: studentBackend()))),
      );
      await tester.pumpAndSettle();
      expect(find.text('3,19'), findsWidgets);
      expect(find.text('Dữ liệu Portal đến HK1 năm 2099-2100'), findsOneWidget);
      expect(find.text('HK2 · 2099-2100'), findsOneWidget);
      await tester.tap(find.byKey(const Key('failed-filter')));
      await tester.pumpAndSettle();
      expect(find.text('HK2 · 2099-2100'), findsNothing);
      expect(find.text('Cơ sở dữ liệu'), findsOneWidget);
      expect(find.text('Cấu trúc dữ liệu'), findsNothing);
    });

    testWidgets('program progress shows LMS course and blocked prerequisites', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          AcademicRecordScreen(
            api: testApi(client: studentBackend()),
            initialTab: 1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('56,5%'), findsOneWidget);
      expect(find.text('13/23'), findsOneWidget);
      expect(find.textContaining('Thiếu: TIN3206'), findsOneWidget);
      await tester.tap(find.text('Học kỳ 5'));
      await tester.pumpAndSettle();
      expect(find.textContaining('LMS: Software Testing'), findsOneWidget);
    });

    testWidgets('GPA simulation updates when a letter is picked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          AcademicRecordScreen(
            api: testApi(client: studentBackend()),
            initialTab: 2,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final sentence = find.byKey(const Key('gpa-sentence'));
      expect(
        tester.widget<Text>(sentence).data,
        'Nếu giữ phong độ hiện tại ở 1 môn đang học trên LMS, GPA tích lũy dự kiến 3,16; để đạt Giỏi cần trung bình 3,28 ở 10 tín chỉ còn lại.',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('pick-TIN2002')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(GpaSimulationView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const Key('pick-TIN2002')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('A').last);
      await tester.pumpAndSettle();
      // (3.19·16 + 3·3 + 4·3) / 22 = 3.2745… → Giỏi
      expect(
        tester.widget<Text>(sentence).data,
        startsWith('Với điểm đã chọn, GPA tích lũy dự kiến 3,27'),
      );
      expect(find.text('Giỏi'), findsWidgets);
    });

    testWidgets('academic warning links to the simulation tab', (tester) async {
      await tester.pumpWidget(
        _app(
          AcademicRecordScreen(
            api: testApi(client: studentBackend()),
            initialTab: 4,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('academic-warning')), findsOneWidget);
      await tester.tap(find.text('Xem mức cần đạt'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('gpa-sentence')), findsOneWidget);
    });

    testWidgets('conduct tab', (tester) async {
      await tester.pumpWidget(
        _app(
          AcademicRecordScreen(
            api: testApi(client: studentBackend()),
            initialTab: 3,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Tự đánh giá 85 · Lớp 82 · Khoa 82'), findsOneWidget);
      expect(find.text('Tốt'), findsWidgets);
    });

    testWidgets('not linked, and Portal down with retry', (tester) async {
      var fail = true;
      final api = testApi(
        client: MockClient((r) async {
          if (r.url.path.endsWith('/program')) {
            return _json({'code': 'PORTAL_NOT_LINKED'}, 404);
          }
          if (fail) return _json({'code': 'PORTAL_UNAVAILABLE'}, 503);
          return _json(_transcript);
        }),
      );
      await tester.pumpWidget(_app(AcademicRecordScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.textContaining('không phản hồi'), findsOneWidget);
      fail = false;
      await tester.tap(find.byKey(const Key('portal-retry')));
      await tester.pumpAndSettle();
      expect(find.text('Cơ sở dữ liệu'), findsNothing); // collapsed term cards
      expect(find.text('HK2 · 2099-2100'), findsOneWidget);
      await tester.tap(find.text('Chương trình'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tài khoản chưa liên kết Portal đào tạo'),
        findsOneWidget,
      );
    });

    testWidgets('dashboard summary card: shown when linked, hidden when not', (
      tester,
    ) async {
      var opened = false;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: PortalSummaryCard(
              api: testApi(client: studentBackend()),
              onOpen: () => opened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('16 tín chỉ · còn thiếu 10 TC bắt buộc'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('portal-summary-card')));
      expect(opened, isTrue);

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: PortalSummaryCard(
              key: UniqueKey(),
              api: testApi(
                client: MockClient(
                  (_) async => _json({'code': 'PORTAL_DISABLED'}, 503),
                ),
              ),
              onOpen: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('portal-summary-card')), findsNothing);
      expect(find.text('Chưa tải được dữ liệu học vụ'), findsNothing);

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: PortalSummaryCard(
              key: UniqueKey(),
              api: testApi(
                client: MockClient(
                  (_) async => _json({'code': 'PORTAL_UNAVAILABLE'}, 503),
                ),
              ),
              onOpen: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chưa tải được dữ liệu học vụ'), findsOneWidget);
    });

    testWidgets('data sources screen', (tester) async {
      final api = testApi(
        client: MockClient(
          (_) async => _json({
            'lms': {'status': 'UP'},
            'portal': {
              'status': 'UP',
              'cacheMinutes': 10,
              'provider': 'Nguồn bịa',
            },
            'demoMapping': true,
            'linked': true,
            'used': [
              {'source': 'Bảng điểm sinh viên', 'fields': 'Học phần, tín chỉ'},
            ],
            'notUsed': [
              {'fields': 'Miễn giảm học phí', 'reason': 'Dữ liệu nhạy cảm'},
            ],
            'courseMappings': [
              {
                'lmsCourseId': 13,
                'lmsCourseName': 'Software Testing',
                'portalCode': 'TIN3206',
              },
            ],
          }),
        ),
      );
      await tester.pumpWidget(_app(PortalSourcesScreen(api: api)));
      await tester.pumpAndSettle();
      expect(find.text('Hoạt động'), findsNWidgets(2));
      expect(find.text('Miễn giảm học phí'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('Học phần TIN3206'), 200);
      expect(find.text('Liên kết (ánh xạ demo)'), findsOneWidget);
    });
  });

  group('advisor screens', () {
    testWidgets('mask toggle, attention filter and confirmed CSV copy', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(tester.view.reset);
      final queries = <String>[];
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      final api = testApi(
        client: MockClient((r) async {
          if (r.url.path.endsWith('/export')) {
            return http.Response.bytes(
              utf8.encode('﻿STT,MSSV\r\n1,2399Z001\r\n'),
              200,
            );
          }
          queries.add(r.url.query);
          return _json(
            r.url.queryParameters['mask'] == 'true'
                ? _masked(_overview)
                : _overview,
          );
        }),
      );
      await tester.pumpWidget(
        _app(
          AdvisorClassScreen(api: api, classId: 'ITK99Z', defaultMask: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(queries.single, 'mask=true');
      expect(find.text('SV 01'), findsOneWidget);
      expect(find.text('Nguyễn Văn An'), findsNothing);
      final export = tester.widget<IconButton>(
        find.byKey(const Key('advisor-export')),
      );
      expect(export.onPressed, isNull); // export only when unmasked

      await tester.tap(find.byKey(const Key('advisor-mask')));
      await tester.pumpAndSettle();
      expect(queries.last, 'mask=false');
      expect(find.text('Nguyễn Văn An'), findsOneWidget);

      await tester.tap(find.byKey(const Key('attention-filter')));
      await tester.pumpAndSettle();
      expect(find.text('Nguyễn Văn An'), findsNothing);
      expect(find.text('Lê Cường'), findsOneWidget);

      await tester.tap(find.byKey(const Key('advisor-export')));
      await tester.pumpAndSettle();
      expect(find.text('Xuất danh sách lớp?'), findsOneWidget);
      await tester.tap(find.text('Sao chép CSV'));
      await tester.pumpAndSettle();
      expect(copied, contains('2399Z001'));
      expect(find.text('Đã sao chép CSV 2 sinh viên'), findsOneWidget);
    });

    testWidgets('student detail: LMS linked and not linked', (tester) async {
      for (final linked in [true, false]) {
        final api = testApi(
          client: MockClient(
            (_) async => _json({
              'no': 2,
              'name': 'Lê Cường',
              'studentId': '2399Z002',
              'gpa4': 1.8,
              'cumulativeGpa4': 2.4,
              'flags': ['LOW_GPA'],
              'history': [
                {
                  'yearStudy': '2099-2100',
                  'termId': 'HK01',
                  'gpa4': 1.8,
                  'cumulativeGpa4': 2.4,
                  'conduct': 45,
                },
              ],
              'lms': linked
                  ? {
                      'linked': true,
                      'courses': [
                        {
                          'courseId': 13,
                          'courseName': 'Software Testing',
                          'level': 'RED',
                          'score': 70,
                          'metrics': {'progress': 20.0, 'overdueTasks': 3},
                        },
                      ],
                    }
                  : {'linked': false},
            }),
          ),
        );
        await tester.pumpWidget(
          _app(
            AdvisorStudentScreen(
              key: UniqueKey(),
              api: api,
              classId: 'ITK99Z',
              no: 2,
              term: null,
              mask: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('ĐTB < 2,0'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('Học tập trên LMS'), 200);
        if (linked) {
          await tester.scrollUntilVisible(find.text('Software Testing'), 200);
          expect(
            find.text('Điểm theo dõi 70 · Tiến độ 20% · 3 việc quá hạn'),
            findsOneWidget,
          );
        } else {
          await tester.scrollUntilVisible(
            find.text('Chưa có dữ liệu LMS cho sinh viên này'),
            200,
          );
        }
      }
    });

    testWidgets('home entry hidden without advisor class', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: AdvisorClassEntry(
              api: testApi(
                client: MockClient(
                  (_) async => _json({'code': 'PORTAL_NOT_LINKED'}, 404),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: AdvisorClassEntry(
              key: UniqueKey(),
              api: testApi(
                client: MockClient(
                  (_) async => _json({
                    'classes': ['ITK99Z'],
                    'presentationMask': false,
                  }),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Lớp cố vấn ITK99Z'), findsOneWidget);
    });
  });
}
