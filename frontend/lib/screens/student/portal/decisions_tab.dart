import 'package:flutter/material.dart';

import '../../../models/portal.dart';
import '../../../services/api_service.dart';
import '../../../widgets/learning_widgets.dart';
import '../../../widgets/portal_widgets.dart';

/// V3-P5: the student's own academic decisions; academic warnings link to the GPA simulation.
class DecisionsTab extends StatelessWidget {
  final ApiService api;
  final VoidCallback onOpenSimulation;
  const DecisionsTab({
    super.key,
    required this.api,
    required this.onOpenSimulation,
  });

  @override
  Widget build(BuildContext context) => PortalView<DecisionList>(
    load: (refresh) => api.getDecisions(refresh: refresh),
    builder: (context, d, refresh) {
      final scheme = Theme.of(context).colorScheme;
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (d.warningCount > 0)
              Card(
                key: const Key('academic-warning'),
                color: scheme.errorContainer,
                child: ListTile(
                  leading: Icon(
                    Icons.warning_amber,
                    color: scheme.onErrorContainer,
                  ),
                  title: Text(
                    'Bạn có ${d.warningCount} quyết định cảnh báo học vụ',
                    style: TextStyle(color: scheme.onErrorContainer),
                  ),
                  trailing: TextButton(
                    onPressed: onOpenSimulation,
                    child: const Text('Xem mức cần đạt'),
                  ),
                ),
              ),
            if (d.decisions.isEmpty)
              const EmptyState(
                'Chưa có quyết định nào',
                icon: Icons.description_outlined,
              ),
            for (final x in d.decisions)
              Card(
                child: ExpansionTile(
                  leading: Icon(
                    x.academicWarning
                        ? Icons.warning_amber
                        : Icons.description_outlined,
                    color: x.academicWarning ? scheme.error : scheme.primary,
                  ),
                  title: Text(x.name),
                  subtitle: Text(
                    [
                      if (x.signDate != null)
                        '${x.signDate!.day.toString().padLeft(2, '0')}/${x.signDate!.month.toString().padLeft(2, '0')}/${x.signDate!.year}',
                      if (x.termId != null) termLabel(x.termId),
                      if (x.yearStudy != null) x.yearStudy!,
                    ].join(' · '),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [if (x.fullText != null) Text(x.fullText!)],
                ),
              ),
          ],
        ),
      );
    },
  );
}
