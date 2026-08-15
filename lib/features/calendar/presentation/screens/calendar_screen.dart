import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_failure.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../domain/calendar_repository.dart';
import '../../domain/learning_event.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(upcomingEventsProvider);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lịch học tập',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Theo dõi các mốc quan trọng và chủ động sắp xếp thời gian.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        events.when(
          loading: () => const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverToBoxAdapter(child: _CalendarLoadingSkeleton()),
          ),
          error: (error, _) => SliverFillRemaining(
            hasScrollBody: false,
            child: ErrorState(
              message: _calendarErrorMessage(error),
              onRetry: () => ref.invalidate(upcomingEventsProvider),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: 'Lịch đang trống',
                  message: 'Bạn chưa có sự kiện học tập sắp tới.',
                  icon: Icons.event_available_outlined,
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: _CalendarTimeline(events: items),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CalendarTimeline extends StatelessWidget {
  const _CalendarTimeline({required this.events});

  final List<LearningEvent> events;

  @override
  Widget build(BuildContext context) {
    final groups = _groupEventsByDate(events);
    return Column(
      children: [
        for (var index = 0; index < groups.length; index++) ...[
          _DateGroup(group: groups[index]),
          if (index < groups.length - 1) const SizedBox(height: 18),
        ],
      ],
    );
  }
}

class _DateGroup extends StatelessWidget {
  const _DateGroup({required this.group});

  final _EventDateGroup group;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = _DateHeading(date: group.date);
      final eventList = Column(
        children: [
          for (var index = 0; index < group.events.length; index++) ...[
            _EventCard(event: group.events[index]),
            if (index < group.events.length - 1) const SizedBox(height: 10),
          ],
        ],
      );

      if (constraints.maxWidth >= 720) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 190, child: heading),
            const SizedBox(width: 18),
            Expanded(child: eventList),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [heading, const SizedBox(height: 10), eventList],
      );
    },
  );
}

class _DateHeading extends StatelessWidget {
  const _DateHeading({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      header: true,
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      date.day.toString().padLeft(2, '0'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'THG ${date.month}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatDateHeading(date),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final LearningEvent event;

  @override
  Widget build(BuildContext context) {
    final presentation = _EventCategory.fromSource(event.eventType);
    final colors = Theme.of(context).colorScheme;
    final time = _formatTime(event.startsAt);
    final title = _friendlyEventName(event.name, presentation);

    return Semantics(
      container: true,
      label:
          '${presentation.label}: $title. ${_formatAccessibleDateTime(event.startsAt)}',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SizedBox.square(
                    dimension: 46,
                    child: Icon(
                      presentation.icon,
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _EventMeta(icon: Icons.schedule_rounded, label: time),
                          _EventMeta(
                            icon: presentation.icon,
                            label: presentation.label,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventMeta extends StatelessWidget {
  const _EventMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CalendarLoadingSkeleton extends StatelessWidget {
  const _CalendarLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Semantics(
          key: const Key('calendar-loading-skeleton'),
          liveRegion: true,
          label: 'Đang tải lịch học tập',
          child: ExcludeSemantics(
            child: Column(
              children: [
                for (var index = 0; index < 3; index++) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBlock(width: 88, height: 20, color: color),
                      const SizedBox(width: 18),
                      Expanded(child: _SkeletonBlock(height: 92, color: color)),
                    ],
                  ),
                  if (index < 2) const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height, required this.color, this.width});

  final double? width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(16),
    ),
  );
}

enum _EventCategory {
  deadline('Hạn nộp bài', Icons.assignment_late_outlined),
  course('Hoạt động khóa học', Icons.school_outlined),
  personal('Lịch cá nhân', Icons.person_outline_rounded),
  group('Hoạt động nhóm', Icons.groups_outlined),
  learning('Sự kiện học tập', Icons.event_note_outlined);

  const _EventCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static _EventCategory fromSource(String value) {
    switch (value.trim().toLowerCase()) {
      case 'due':
      case 'assignment':
      case 'submission':
        return deadline;
      case 'course':
      case 'courseevent':
      case 'opening':
        return course;
      case 'user':
      case 'personal':
        return personal;
      case 'group':
        return group;
      default:
        return learning;
    }
  }
}

class _EventDateGroup {
  const _EventDateGroup({required this.date, required this.events});

  final DateTime date;
  final List<LearningEvent> events;
}

List<_EventDateGroup> _groupEventsByDate(List<LearningEvent> events) {
  final sorted = [...events]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  final grouped = <DateTime, List<LearningEvent>>{};
  for (final event in sorted) {
    final local = event.startsAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    grouped.putIfAbsent(day, () => <LearningEvent>[]).add(event);
  }
  return [
    for (final entry in grouped.entries)
      _EventDateGroup(date: entry.key, events: entry.value),
  ];
}

String _calendarErrorMessage(Object error) => switch (error) {
  NetworkFailure() || TimeoutFailure() =>
    'Không thể cập nhật lịch lúc này. Vui lòng kiểm tra kết nối và thử lại.',
  PermissionFailure() => 'Bạn chưa có quyền xem lịch học tập.',
  _ => 'Lịch học tập hiện chưa sẵn sàng. Vui lòng thử lại sau.',
};

const _weekdays = <String>[
  'Thứ Hai',
  'Thứ Ba',
  'Thứ Tư',
  'Thứ Năm',
  'Thứ Sáu',
  'Thứ Bảy',
  'Chủ Nhật',
];

String _formatDateHeading(DateTime value) =>
    '${_weekdays[value.weekday - 1]}, ${value.day} tháng ${value.month}, ${value.year}';

String _formatTime(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String _formatAccessibleDateTime(DateTime value) {
  final local = value.toLocal();
  return '${_formatDateHeading(local)}, lúc ${_formatTime(local)}';
}

String _friendlyEventName(String value, _EventCategory category) {
  final trimmed = value.trim();
  if (category == _EventCategory.deadline) {
    return trimmed.replaceFirst(RegExp(r'^Hạn nộp\s*:\s*'), '');
  }
  return trimmed;
}
