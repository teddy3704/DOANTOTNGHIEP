import 'package:flutter/material.dart';

import '../../../models/portal.dart';
import '../../../services/api_service.dart';
import '../../../widgets/learning_widgets.dart';
import '../../../widgets/portal_widgets.dart';

/// V3-P2: study-program progress with LMS courses and next-term eligibility.
class ProgramTab extends StatelessWidget {
  final ApiService api;
  const ProgramTab({super.key, required this.api});

  @override
  Widget build(BuildContext context) => PortalView<ProgramProgress>(
    load: (refresh) => api.getProgramProgress(refresh: refresh),
    builder: (context, p, refresh) {
      final pct = p.completionPercent;
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            p.programId == null
                                ? 'Hoàn thành chương trình'
                                : 'Hoàn thành ${p.programId}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        Text(
                          pct == null ? '—' : '${vn(pct, 1)}%',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: pct == null ? 0 : pct / 100,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 8,
                      children: [
                        PortalStat(
                          'TC bắt buộc đã đạt',
                          '${p.compulsoryPassedCredits}/${p.compulsoryCredits}',
                        ),
                        PortalStat(
                          'TC tự chọn đã đạt',
                          '${p.electivePassedCredits}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final s in ProgramStatus.values)
                  if ((p.counts[s] ?? 0) > 0)
                    Chip(
                      avatar: CircleAvatar(
                        backgroundColor: statusColor(context, s),
                        radius: 6,
                      ),
                      label: Text('${s.label}: ${p.counts[s]}'),
                    ),
              ],
            ),
            SectionHeader('Đủ điều kiện đăng ký (${p.eligible.length})'),
            if (p.eligible.isEmpty)
              const EmptyState('Không còn học phần nào để đăng ký'),
            for (final c in p.eligible.take(8))
              _CourseTile(
                c,
                trailing: c.status == ProgramStatus.failed ? 'Học lại' : null,
              ),
            if (p.eligible.length > 8)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('và ${p.eligible.length - 8} học phần khác'),
              ),
            if (p.blocked.isNotEmpty) ...[
              SectionHeader('Chưa đủ điều kiện (${p.blocked.length})'),
              for (final c in p.blocked)
                _CourseTile(c, subtitle: 'Thiếu: ${c.missing.join(', ')}'),
            ],
            const SectionHeader('Theo học kỳ'),
            for (final sem in p.semesters)
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  title: Text(sem.name.isEmpty ? 'Khác' : sem.name),
                  subtitle: Text(
                    '${sem.courses.where((c) => c.status == ProgramStatus.passed).length}/${sem.courses.length} đã đạt',
                  ),
                  children: [for (final c in sem.courses) _CourseTile(c)],
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _CourseTile extends StatelessWidget {
  final ProgramCourse c;
  final String? subtitle;
  final String? trailing;
  const _CourseTile(this.c, {this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(context, c.status);
    final details = [
      if (c.code != null) c.code!,
      if (c.credits != null) '${c.credits} TC',
      c.compulsory ? 'Bắt buộc' : 'Tự chọn',
      if (c.lmsCourseName != null) 'LMS: ${c.lmsCourseName}',
    ].join(' · ');
    return ListTile(
      dense: true,
      leading: Icon(switch (c.status) {
        ProgramStatus.passed => Icons.check_circle,
        ProgramStatus.failed => Icons.replay_circle_filled,
        ProgramStatus.inLms => Icons.school,
        ProgramStatus.inProgress => Icons.timelapse,
        ProgramStatus.notTaken => Icons.radio_button_unchecked,
      }, color: color),
      title: Text(c.name),
      subtitle: Text(subtitle == null ? details : '$details\n$subtitle'),
      isThreeLine: subtitle != null,
      trailing: Text(
        trailing ??
            (c.letter ??
                (c.status == ProgramStatus.passed ? '' : c.status.label)),
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
