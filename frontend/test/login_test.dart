import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/login_screen.dart';
import 'package:lms_mobile_app/screens/role_selection_screen.dart';
import 'package:lms_mobile_app/screens/student/student_main_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_main_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';
import 'package:lms_mobile_app/services/api_session.dart';
import 'package:lms_mobile_app/services/offline_cache.dart';
import 'package:lms_mobile_app/services/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_test.dart' show FakeGateway, MemoryStore;
import 'support/mock_api.dart';

class MemoryLoginMemory implements LoginMemory {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String? login) async => value = login;
}

http.Response _json(
  Object body, [
  int status = 200,
  Map<String, String>? headers,
]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8', ...?headers},
);

/// A fake server: 2312005 / right-pw -> STUDENT 205, teacher02 / right-pw -> TEACHER 102,
/// 'locked' -> 429, anything else -> 401. Every other request -> 404 (screens show their own errors).
class _Server {
  final logins = <Map<String, dynamic>>[];
  late final MockClient client = MockClient((r) async {
    if (r.url.path.endsWith('/auth/login')) {
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      logins.add(body);
      if (body['login'] == 'locked') {
        return _json({'code': 'LOGIN_LOCKED'}, 429, {'retry-after': '840'});
      }
      if (body['password'] != 'right-pw') {
        return _json({'code': 'INVALID_CREDENTIALS'}, 401);
      }
      return switch (body['login']) {
        '2312005' => _json({
          'token': 'tok-sv',
          'role': 'STUDENT',
          'userId': '205',
        }),
        'teacher02' => _json({
          'token': 'tok-gv',
          'role': 'TEACHER',
          'userId': '102',
        }),
        _ => _json({'code': 'INVALID_CREDENTIALS'}, 401),
      };
    }
    return http.Response('', 404);
  });
}

void main() {
  late _Server server;
  late ApiService api;
  late MemoryLoginMemory memory;
  late FakeGateway gateway;
  late MemoryOfflineStore offline;

  setUp(() {
    server = _Server();
    offline = MemoryOfflineStore();
    api = ApiService(
      client: server.client,
      baseUrl: mockApiBaseUrl,
      localDevelopment: true,
      session: ApiSession(),
      offlineStore: offline,
    );
    memory = MemoryLoginMemory();
    gateway = FakeGateway();
  });

  Widget app() => MaterialApp(
    home: LoginScreen(
      apiService: api,
      memory: memory,
      reminders: ReminderService(gateway: gateway, store: MemoryStore()),
    ),
  );

  Future<void> signIn(
    WidgetTester tester,
    String login,
    String password,
  ) async {
    await tester.enterText(find.byKey(const Key('login-id')), login);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
  }

  testWidgets('empty form is validated and sends nothing', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
    expect(
      find.text('Nhập mã số sinh viên hoặc tên đăng nhập'),
      findsOneWidget,
    );
    expect(find.text('Nhập mật khẩu'), findsOneWidget);
    expect(server.logins, isEmpty);
  });

  testWidgets(
    'student code opens the student app; the role comes from the server',
    (tester) async {
      await tester.pumpWidget(app());
      await signIn(tester, ' 231 2005 ', 'right-pw');
      expect(server.logins.single, {
        'login': '2312005',
        'password': 'right-pw',
      });
      expect(find.byType(StudentMainScreen), findsOneWidget);
      expect(api.session.userIdFor('STUDENT'), 205);
    },
  );

  testWidgets('username opens the teacher app', (tester) async {
    await tester.pumpWidget(app());
    await signIn(tester, 'teacher02', 'right-pw');
    expect(find.byType(TeacherMainScreen), findsOneWidget);
    expect(api.session.userIdFor('TEACHER'), 102);
  });

  testWidgets('wrong password: one generic message, still on the form', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await signIn(tester, '2312005', 'wrong');
    expect(find.text('Mã số hoặc mật khẩu không đúng'), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(api.session.token, isNull);
  });

  testWidgets('temporary lock shows the minutes left', (tester) async {
    await tester.pumpWidget(app());
    await signIn(tester, 'locked', 'whatever');
    expect(
      find.text('Đăng nhập sai nhiều lần. Vui lòng thử lại sau 14 phút.'),
      findsOneWidget,
    );
  });

  testWidgets('password can be shown and hidden', (tester) async {
    await tester.pumpWidget(app());
    EditableText field() => tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(field().obscureText, isTrue);
    await tester.tap(find.byKey(const Key('login-toggle-password')));
    await tester.pump();
    expect(field().obscureText, isFalse);
    await tester.tap(find.byKey(const Key('login-toggle-password')));
    await tester.pump();
    expect(field().obscureText, isTrue);
  });

  testWidgets(
    '"remember" keeps only the login on the device, never the password',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(MaterialApp(home: LoginScreen(apiService: api)));
      await signIn(tester, '2312005', 'right-pw');
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getKeys().map((k) => '${prefs.get(k)}').join('|');
      expect(prefs.getString('remembered_login'), '2312005');
      expect(stored, isNot(contains('right-pw')));
      expect(stored, isNot(contains('tok-sv')));
    },
  );

  testWidgets('remembered login is filled in; unticking forgets it', (
    tester,
  ) async {
    memory.value = '2312005';
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('2312005'), findsOneWidget);
    await tester.tap(find.byKey(const Key('login-remember')));
    await signIn(tester, '2312005', 'right-pw');
    expect(memory.value, isNull);
  });

  testWidgets(
    'sign-out clears the token, the offline cache and the phone reminders',
    (tester) async {
      await tester.pumpWidget(app());
      await signIn(tester, 'teacher02', 'right-pw');
      await offline.put(
        '$mockApiBaseUrl/dev/students/205/dashboard',
        '{}',
        DateTime(2026),
      );
      final cancelsBefore = gateway.cancels;
      await tester.tap(find.byKey(const Key('logout')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(api.session.token, isNull);
      expect(offline.entries, isEmpty);
      expect(gateway.cancels, greaterThan(cancelsBefore));
      expect(find.byKey(const Key('login-password')), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('login-password')))
            .controller
            ?.text,
        isEmpty,
      );
    },
  );

  testWidgets('demo mode is a small extra button in local builds only', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.tap(find.byKey(const Key('login-demo-mode')));
    await tester.pumpAndSettle();
    expect(find.byType(RoleSelectionScreen), findsOneWidget);

    final production = ApiService(
      client: server.client,
      baseUrl: 'https://api.example.edu.vn/api/v1',
      localDevelopment: false,
      session: ApiSession(),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(apiService: production, memory: memory),
      ),
    );
    expect(find.byKey(const Key('login-demo-mode')), findsNothing);
  });

  testWidgets('sign-in screen fits 320 dp at text scale 1.3, light and dark', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 3;
    tester.view.physicalSize = const Size(960, 1800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final dark in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: dark ? ThemeMode.dark : ThemeMode.light,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(
              c,
            ).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: LoginScreen(apiService: api, memory: memory),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'dark=$dark');
    }
  });
}
