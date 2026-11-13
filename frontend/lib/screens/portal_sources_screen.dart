import 'package:flutter/material.dart';
import '../core/data_profile.dart';

import '../models/portal.dart';
import '../services/api_exception.dart';
import '../services/api_service.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/portal_widgets.dart';

/// V3-P7: where the data comes from, which fields are used or deliberately not used.
class PortalSourcesScreen extends StatelessWidget {
  final ApiService api;
  final bool teacher;
  const PortalSourcesScreen({
    super.key,
    required this.api,
    this.teacher = false,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nguồn dữ liệu')),
    body: PortalView<PortalSources>(
      load: (_) => api.getPortalSources(teacher: teacher),
      builder: (context, s, refresh) => RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  _SourceTile(
                    icon: Icons.school_outlined,
                    title: 'LMS Moodle',
                    subtitle: 'Hoạt động, bài nộp, quiz, chuyên cần',
                    status: s.lmsStatus,
                  ),
                  const Divider(height: 1),
                  _SourceTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Portal đào tạo',
                    subtitle: [
                      'Bảng điểm, CTĐT, rèn luyện, quyết định',
                      if (s.lastSuccess != null)
                        'Cập nhật ${_time(s.lastSuccess!)}',
                      'Lưu tạm ${s.cacheMinutes} phút, không lưu vào CSDL',
                    ].join('\n'),
                    status: s.portalStatus,
                  ),
                ],
              ),
            ),
            if (s.provider.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  s.provider,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SectionHeader('Dữ liệu ứng dụng sử dụng'),
            Card(
              child: Column(
                children: [
                  for (final (source, fields) in s.used)
                    ListTile(
                      dense: true,
                      leading: const Icon(Icons.check, color: Colors.green),
                      title: Text(source),
                      subtitle: Text(fields),
                    ),
                ],
              ),
            ),
            const SectionHeader('Không sử dụng'),
            Card(
              child: Column(
                children: [
                  for (final (fields, reason) in s.notUsed)
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.block,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(fields),
                      subtitle: Text(reason),
                    ),
                ],
              ),
            ),
            if (s.courseMappings.isNotEmpty || s.advisorClasses.isNotEmpty) ...[
              SectionHeader(
                s.demoMapping ? 'Liên kết (ánh xạ demo)' : 'Liên kết',
              ),
              Card(
                child: Column(
                  children: [
                    for (final c in s.advisorClasses)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.groups_outlined),
                        title: Text('Lớp cố vấn $c'),
                      ),
                    for (final (lms, code) in s.courseMappings)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.link),
                        title: Text(lms),
                        subtitle: Text('Học phần $code'),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  static String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')} ${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}';
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;
  const _SourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'UP' => ('Hoạt động', Colors.green.shade700),
      'DOWN' => ('Mất kết nối', Theme.of(context).colorScheme.error),
      _ => ('Chưa kết nối', Theme.of(context).colorScheme.outline),
    };
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      isThreeLine: subtitle.contains('\n'),
      trailing: Chip(
        label: Text(label, style: TextStyle(color: color)),
        side: BorderSide(color: color),
      ),
    );
  }
}

/// Dashboard card: "GPA tích lũy · tín chỉ · còn thiếu X TC". Hidden when the account
/// has no Portal link or the Portal is not configured.
class PortalSummaryCard extends StatefulWidget {
  final ApiService api;
  final VoidCallback onOpen;
  const PortalSummaryCard({super.key, required this.api, required this.onOpen});

  @override
  State<PortalSummaryCard> createState() => _PortalSummaryCardState();
}

class _PortalSummaryCardState extends State<PortalSummaryCard> {
  late Future<PortalSummary> _future = widget.api.getPortalSummary();

  @override
  Widget build(BuildContext context) => FutureBuilder<PortalSummary>(
    future: _future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const SizedBox(height: 4);
      }
      if (snap.hasError) {
        final e = snap.error;
        // Real export (REAL-DATA-1): say plainly that the Portal has no record for this student code.
        if (DataProfile.isReal && e is ApiException && e.portalNotLinked) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('Học vụ · GPA'),
              subtitle: Text(DataProfile.portalNotLinked),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onOpen,
            ),
          );
        }
        // Only a Portal outage gets a retry; anything else keeps the dashboard clean.
        if (e is! ApiException || e.code != 'PORTAL_UNAVAILABLE') {
          return const SizedBox.shrink();
        }
        return Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off),
            title: const Text('Chưa tải được dữ liệu học vụ'),
            trailing: TextButton(
              onPressed: () => setState(() {
                _future = widget.api.getPortalSummary(refresh: true);
              }),
              child: const Text('Thử lại'),
            ),
          ),
        );
      }
      final s = snap.data!;
      final scheme = Theme.of(context).colorScheme;
      final t = Theme.of(context).textTheme;
      return Card(
        key: const Key('portal-summary-card'),
        color: scheme.primaryContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onOpen,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('GPA tích lũy', style: t.labelLarge),
                      Text(
                        vn(s.cumulativeGpa4),
                        style: t.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                      Text(
                        [
                          '${vn(s.cumulativeCredits, 0)} tín chỉ',
                          if (s.remainingCompulsoryCredits != null)
                            'còn thiếu ${s.remainingCompulsoryCredits} TC bắt buộc',
                        ].join(' · '),
                        style: t.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      DataUntilText(s.dataUntil),
                    ],
                  ),
                ),
                if (s.band != null) Chip(label: Text(s.band!)),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      );
    },
  );
}
