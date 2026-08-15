import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import 'learning_event.dart';

abstract interface class CalendarRepository {
  Future<List<LearningEvent>> getUpcomingEvents();
}

class UnconfiguredCalendarRepository implements CalendarRepository {
  const UnconfiguredCalendarRepository();

  @override
  Future<List<LearningEvent>> getUpcomingEvents() {
    throw const ConfigurationFailure(
      'API lịch học DLU chưa được xác nhận.',
      code: 'MOODLE_WEB_SERVICES_NOT_ENABLED',
    );
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>(
  (ref) => const UnconfiguredCalendarRepository(),
);

final upcomingEventsProvider = FutureProvider.autoDispose<List<LearningEvent>>(
  (ref) => ref.watch(calendarRepositoryProvider).getUpcomingEvents(),
);
