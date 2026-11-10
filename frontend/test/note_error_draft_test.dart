import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lms_mobile_app/screens/student/student_reflection_screen.dart';
import 'package:lms_mobile_app/screens/teacher/teacher_notes_screen.dart';
import 'package:lms_mobile_app/screens/role_selection_screen.dart';
import 'package:lms_mobile_app/services/api_service.dart';

import 'support/mock_api.dart';

void main() {
  for (final reflection in [true, false]) {
    testWidgets(
      '${reflection ? 'Reflection' : 'Teacher note'} distinguishes load error and retries',
      (tester) async {
        var fail = true;
        final api = testApi(
          client: MockClient(
            (_) async => http.Response(fail ? '{}' : '[]', fail ? 503 : 200),
          ),
        );
        addTearDown(api.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: reflection
                ? StudentReflectionScreen(api: api)
                : TeacherNotesScreen(
                    api: api,
                    studentId: mockStudentId,
                    studentName: 'MOCK',
                    courseId: 14,
                  ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
        expect(
          find.text(
            reflection ? 'Chưa có nhật ký nào.' : 'Chưa có ghi chú nào.',
          ),
          findsNothing,
        );
        fail = false;
        await tester.tap(find.text('Thử lại'));
        await tester.pumpAndSettle();
        expect(
          find.text(
            reflection ? 'Chưa có nhật ký nào.' : 'Chưa có ghi chú nào.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${reflection ? 'Reflection' : 'Teacher note'} failed save preserves draft for retry',
      (tester) async {
        var failSave = true;
        final savedBodies = <Map<String, dynamic>>[];
        final api = testApi(
          client: MockClient((request) async {
            if (request.method == 'GET') return http.Response('[]', 200);
            savedBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
            return http.Response(failSave ? '{}' : '', failSave ? 503 : 204);
          }),
        );
        addTearDown(api.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: reflection
                ? StudentReflectionScreen(api: api)
                : TeacherNotesScreen(
                    api: api,
                    studentId: mockStudentId,
                    studentName: 'MOCK',
                    courseId: 14,
                  ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text(reflection ? 'Ghi chép' : 'Thêm ghi chú'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Bản nháp tiếng Việt');
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Bản nháp tiếng Việt'), findsOneWidget);
        expect(
          find.text('Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại.'),
          findsOneWidget,
        );
        failSave = false;
        await tester.tap(find.text('Lưu'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(savedBodies, hasLength(2));
        expect(savedBodies[0], savedBodies[1]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('role picker is unavailable without explicit local mode', (
    tester,
  ) async {
    final api = ApiService(
      client: MockClient((_) async => http.Response('{}', 500)),
    );
    addTearDown(api.dispose);
    await tester.pumpWidget(
      MaterialApp(home: RoleSelectionScreen(apiService: api)),
    );
    expect(find.text('Sinh viên'), findsNothing);
    expect(
      find.textContaining('Đăng nhập LMS chưa được cấu hình'),
      findsOneWidget,
    );
  });
}
