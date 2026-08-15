import 'dart:async';

import 'package:dlu_lms_mobile/core/errors/app_failure.dart';
import 'package:dlu_lms_mobile/features/calendar/domain/calendar_repository.dart';
import 'package:dlu_lms_mobile/features/calendar/domain/learning_event.dart';
import 'package:dlu_lms_mobile/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar shows a contextual loading skeleton then empty state', (
    tester,
  ) async {
    final completer = Completer<List<LearningEvent>>();

    await tester.pumpWidget(
      _calendarApp(_CompleterCalendarRepository(completer)),
    );
    await tester.pump();

    expect(find.byKey(const Key('calendar-loading-skeleton')), findsOneWidget);
    expect(find.text('Lịch học tập'), findsOneWidget);

    completer.complete(const <LearningEvent>[]);
    await tester.pumpAndSettle();

    expect(find.text('Lịch đang trống'), findsOneWidget);
    expect(find.text('Bạn chưa có sự kiện học tập sắp tới.'), findsOneWidget);
  });

  testWidgets('calendar groups events and translates internal categories', (
    tester,
  ) async {
    final repository = _StaticCalendarRepository([
      LearningEvent(
        id: 'event-2',
        courseId: 'course-private-42',
        name: 'Thảo luận chuyên đề',
        startsAt: DateTime(2026, 8, 19, 9, 30),
        eventType: 'course',
      ),
      LearningEvent(
        id: 'event-1',
        courseId: 'course-private-42',
        name: 'Nộp báo cáo giữa kỳ',
        startsAt: DateTime(2026, 8, 18, 20),
        eventType: 'due',
      ),
      LearningEvent(
        id: 'event-3',
        courseId: 'course-private-99',
        name: 'Ôn tập theo kế hoạch',
        startsAt: DateTime(2026, 8, 18, 8),
        eventType: 'unrecognized_internal_type',
      ),
    ]);

    await tester.pumpWidget(_calendarApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Thứ Ba, 18 tháng 8, 2026'), findsOneWidget);
    expect(find.text('Thứ Tư, 19 tháng 8, 2026'), findsOneWidget);
    expect(find.text('Hạn nộp bài'), findsOneWidget);
    expect(find.text('Hoạt động khóa học'), findsOneWidget);
    expect(find.text('Sự kiện học tập'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('due'), findsNothing);
    expect(find.text('course'), findsNothing);
    expect(find.text('unrecognized_internal_type'), findsNothing);
    expect(find.textContaining('course-private'), findsNothing);
  });

  testWidgets('calendar retries with a friendly error message', (tester) async {
    final repository = _RetryCalendarRepository();

    await tester.pumpWidget(_calendarApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể tải dữ liệu'), findsOneWidget);
    expect(
      find.text(
        'Không thể cập nhật lịch lúc này. Vui lòng kiểm tra kết nối và thử lại.',
      ),
      findsOneWidget,
    );
    expect(repository.requestCount, 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Thử lại'));
    await tester.pumpAndSettle();

    expect(repository.requestCount, 2);
    expect(find.text('Lịch đang trống'), findsOneWidget);
  });

  testWidgets('calendar keeps configuration details out of the UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      _calendarApp(
        const _FailingCalendarRepository(
          ConfigurationFailure(
            'API lịch học chưa được cấu hình.',
            code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Lịch học tập hiện chưa sẵn sàng. Vui lòng thử lại sau.'),
      findsOneWidget,
    );
    expect(find.textContaining('API'), findsNothing);
    expect(
      find.textContaining('MOODLE_WEB_SERVICES_NOT_ENABLED'),
      findsNothing,
    );
  });

  testWidgets('calendar supports a compact viewport with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _calendarApp(
        _StaticCalendarRepository([
          LearningEvent(
            id: 'event-accessible',
            courseId: 'hidden-course',
            name: 'Hoàn thành bài tập thảo luận theo nhóm',
            startsAt: DateTime(2026, 8, 18, 20),
            eventType: 'due',
          ),
        ]),
        textScaler: const TextScaler.linear(1.5),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hoàn thành bài tập thảo luận theo nhóm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _calendarApp(
  CalendarRepository repository, {
  TextScaler textScaler = TextScaler.noScaling,
}) => ProviderScope(
  overrides: <Override>[
    calendarRepositoryProvider.overrideWithValue(repository),
  ],
  child: MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: child!,
    ),
    home: const Scaffold(body: CalendarScreen()),
  ),
);

class _CompleterCalendarRepository implements CalendarRepository {
  _CompleterCalendarRepository(this.completer);

  final Completer<List<LearningEvent>> completer;

  @override
  Future<List<LearningEvent>> getUpcomingEvents() => completer.future;
}

class _StaticCalendarRepository implements CalendarRepository {
  const _StaticCalendarRepository(this.events);

  final List<LearningEvent> events;

  @override
  Future<List<LearningEvent>> getUpcomingEvents() async => events;
}

class _RetryCalendarRepository implements CalendarRepository {
  int requestCount = 0;

  @override
  Future<List<LearningEvent>> getUpcomingEvents() async {
    requestCount += 1;
    if (requestCount == 1) {
      throw const NetworkFailure('Network details for diagnostics only.');
    }
    return const <LearningEvent>[];
  }
}

class _FailingCalendarRepository implements CalendarRepository {
  const _FailingCalendarRepository(this.error);

  final Object error;

  @override
  Future<List<LearningEvent>> getUpcomingEvents() async => throw error;
}
