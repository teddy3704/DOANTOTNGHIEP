import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/failure_message.dart';
import '../../../core/external_links/official_lms_button.dart';
import '../../../core/widgets/content_skeleton.dart';
import '../../../core/widgets/error_state.dart';
import '../domain/teacher_support_repository.dart';

enum TeacherView { home, courses, work, calendar }

class TeacherSupportScreen extends ConsumerStatefulWidget {
  const TeacherSupportScreen({
    this.view = TeacherView.home,
    this.courseId,
    super.key,
  });
  final TeacherView view;
  final String? courseId;
  @override
  ConsumerState<TeacherSupportScreen> createState() =>
      _TeacherSupportScreenState();
}

class _TeacherSupportScreenState extends ConsumerState<TeacherSupportScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(teacherOverviewProvider);
    return overview.when(
      loading: () => const ContentSkeleton(rows: 4, rowHeight: 100),
      error: (error, _) => ErrorState(
        message: userMessageFor(error),
        onRetry: () => ref.invalidate(teacherOverviewProvider),
      ),
      data: (data) {
        final id = widget.courseId;
        if (id != null) {
          final matches = data.courses.where((c) => c.id == id);
          if (matches.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy học phần trong phạm vi giảng dạy.'),
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Học phần giảng dạy')),
            body: _body(_detail(matches.single)),
          );
        }
        final courses = data.courses
            .where(
              (c) => '${c.name} ${c.code}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
            )
            .toList();
        final children = <Widget>[
          _heading(switch (widget.view) {
            TeacherView.home => 'Góc giảng dạy',
            TeacherView.courses => 'Khóa học giảng dạy',
            TeacherView.work => 'Công việc',
            TeacherView.calendar => 'Lịch giảng dạy',
          }),
          const SizedBox(height: 8),
          Text(switch (widget.view) {
            TeacherView.home => 'Xin chào, ${data.profile.displayName}',
            TeacherView.courses =>
              'Nội dung và hoạt động trong học phần bạn phụ trách.',
            TeacherView.work =>
              'Theo dõi bài tập; chấm bài và quản lý trên LMS.',
            TeacherView.calendar => 'Các mốc thời gian của học phần.',
          }),
          const SizedBox(height: 24),
          if (widget.view == TeacherView.home) ..._home(data),
          if (widget.view == TeacherView.courses) ...[
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Tìm tên hoặc mã học phần',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            if (courses.isEmpty)
              const _QuietState('Không có học phần phù hợp.'),
            for (final course in courses) ...[
              _courseCard(course),
              const SizedBox(height: 12),
            ],
          ],
          if (widget.view == TeacherView.work) ...[
            if (data.courses.every((c) => c.work.isEmpty))
              const _QuietState('Chưa có bài tập cần theo dõi.'),
            for (final course in data.courses)
              for (final work in course.work) ...[
                _workCard(work, course.name),
                const SizedBox(height: 16),
              ],
          ],
          if (widget.view == TeacherView.calendar) ..._calendar(data),
        ];
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(teacherOverviewProvider);
            await ref.read(teacherOverviewProvider.future);
          },
          child: _body(children),
        );
      },
    );
  }

  Widget _body(List<Widget> children) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth > 900
            ? (constraints.maxWidth - 850) / 2
            : 20,
        vertical: 24,
      ),
      children: children,
    ),
  );

  Widget _heading(String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
  );

  List<Widget> _home(TeacherOverview data) {
    final count = data.courses.fold<int>(0, (sum, c) => sum + c.work.length);
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(24),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.school_outlined,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                '${data.courses.length} học phần · $count bài tập',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Một nơi để theo dõi. LMS là nơi thực hiện nghiệp vụ chính thức.',
                style: TextStyle(height: 1.5),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      _heading('Học phần phụ trách'),
      const SizedBox(height: 14),
      if (data.courses.isEmpty)
        const _QuietState('Chưa có học phần được phân công.'),
      for (final c in data.courses) ...[
        _courseCard(c),
        const SizedBox(height: 12),
      ],
      const SizedBox(height: 12),
      _heading('Truy cập LMS'),
      const SizedBox(height: 12),
      const OfficialLmsButton(label: 'Quản lý khóa học trên LMS'),
      const SizedBox(height: 8),
      const Text(
        'Mở trang LMS chính thức; chọn học phần tương ứng sau khi đăng nhập.',
        style: TextStyle(height: 1.5),
      ),
    ];
  }

  Widget _courseCard(TeachingCourse c) => Card(
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/teacher/course/${Uri.encodeComponent(c.id)}'),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c.code,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              c.name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Text('${c.studentCount} sinh viên · ${c.work.length} bài tập'),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    ),
  );

  List<Widget> _detail(TeachingCourse c) => [
    Text(
      c.code,
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    ),
    const SizedBox(height: 8),
    _heading(c.name),
    const SizedBox(height: 12),
    Text(c.summary, style: const TextStyle(height: 1.6)),
    const SizedBox(height: 16),
    Text('${c.studentCount} sinh viên · ${c.work.length} bài tập'),
    const SizedBox(height: 16),
    OutlinedButton.icon(
      onPressed: () =>
          context.push('/teacher/course/${Uri.encodeComponent(c.id)}/students'),
      icon: const Icon(Icons.groups_outlined),
      label: const Text('Theo dõi sinh viên'),
    ),
    const SizedBox(height: 16),
    const OfficialLmsButton(label: 'Quản lý khóa học trên LMS'),
    const SizedBox(height: 24),
    _heading('Nội dung & tài liệu'),
    const SizedBox(height: 12),
    for (final s in c.sections) ...[
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              for (final resource in s.resources)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.description_outlined, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Text(resource)),
                    ],
                  ),
                ),
              if (s.resources.isNotEmpty) ...[
                const SizedBox(height: 12),
                const OfficialLmsButton(label: 'Mở tài liệu trên LMS'),
              ],
              if (s.resources.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Hoạt động học tập của chủ đề được trình bày bên dưới.',
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
    ],
    const SizedBox(height: 12),
    _heading('Bài tập & bài nộp'),
    const SizedBox(height: 12),
    if (c.work.isEmpty) const _QuietState('Chưa có bài tập trong học phần.'),
    for (final w in c.work) ...[
      _workCard(w, c.name),
      const SizedBox(height: 16),
    ],
  ];

  Widget _workCard(TeachingWork w, String course) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            course,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            w.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(w.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 14),
          Text('Hạn nộp: ${_date(w.dueAt)}'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('${w.submitted} đã nộp')),
              Chip(label: Text('${w.missing} chưa nộp')),
            ],
          ),
          const SizedBox(height: 12),
          const OfficialLmsButton(label: 'Chấm bài trên LMS'),
          const SizedBox(height: 8),
          const OfficialLmsButton(label: 'Quản lý bài tập trên LMS'),
          const SizedBox(height: 8),
          const Text(
            'Chọn đúng học phần và bài tập trên LMS. Ứng dụng không sửa điểm hoặc bài nộp.',
            style: TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    ),
  );

  List<Widget> _calendar(TeacherOverview data) {
    final entries = [
      for (final c in data.courses)
        for (final w in c.work) (course: c, work: w),
    ]..sort((a, b) => a.work.dueAt.compareTo(b.work.dueAt));
    if (entries.isEmpty) return [const _QuietState('Chưa có mốc thời gian.')];
    return [
      for (final e in entries) ...[
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Icon(
              Icons.event_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(e.work.title),
            subtitle: Text(
              '${e.course.name}\n${_date(e.work.dueAt)}${e.work.dueAt.isBefore(DateTime.now()) ? ' · Đã qua' : ''}',
            ),
            isThreeLine: true,
            onTap: () => context.push('/teacher/course/${e.course.id}'),
          ),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }

  String _date(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _QuietState extends StatelessWidget {
  const _QuietState(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 36),
    child: Column(
      children: [
        const Icon(Icons.inbox_outlined, size: 40),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}
