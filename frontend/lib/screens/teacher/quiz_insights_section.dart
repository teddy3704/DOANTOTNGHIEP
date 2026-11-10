import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/class_insights.dart';
import '../../models/quiz_insights.dart';
import '../../services/api_service.dart';
import '../../widgets/moodle_button.dart';
import 'teacher_analytics_widgets.dart';

String _pct(double v) =>
    '${(v * 10).round() / 10}'.replaceAll('.0', '').replaceAll('.', ',');

/// V2-N16 "Phân tích bài kiểm tra": one card per quiz, flagged quizzes first.
/// Loads on its own so a failure never hides the rest of the analytics tab.
class QuizInsightsSection extends StatefulWidget {
  final ApiService api;
  final int courseId;

  /// Roster as loaded by the analytics tab; reminders go only to these students.
  final List<InsightStudent> students;
  const QuizInsightsSection({
    super.key,
    required this.api,
    required this.courseId,
    required this.students,
  });

  @override
  State<QuizInsightsSection> createState() => _QuizInsightsSectionState();
}

class _QuizInsightsSectionState extends State<QuizInsightsSection> {
  late Future<List<QuizInsight>> _future = _load();

  Future<List<QuizInsight>> _load() =>
      widget.api.getQuizInsights(courseId: widget.courseId);

  @override
  Widget build(BuildContext context) => FutureBuilder<List<QuizInsight>>(
    future: _future,
    builder: (context, snap) {
      if (snap.connectionState != ConnectionState.done) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (snap.hasError) {
        return Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: const Text('Chưa tải được phân tích bài kiểm tra'),
            trailing: TextButton(
              onPressed: () => setState(() {
                _future = _load();
              }),
              child: const Text('Thử lại'),
            ),
          ),
        );
      }
      final quizzes = [...snap.data!]
        ..sort((a, b) => b.flags.length.compareTo(a.flags.length));
      if (quizzes.isEmpty) {
        return const Card(
          child: ListTile(title: Text('Khóa học chưa có bài kiểm tra')),
        );
      }
      return Column(
        children: [
          for (final q in quizzes)
            _QuizCard(quiz: q, students: widget.students),
        ],
      );
    },
  );
}

class _QuizCard extends StatelessWidget {
  final QuizInsight quiz;
  final List<InsightStudent> students;
  const _QuizCard({required this.quiz, required this.students});

  static const _bands = ['0–20', '20–40', '40–60', '60–80', '80–100'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final remind = ReminderScope.maybeOf(context);
    final pending = [
      for (final s in students)
        if (quiz.notAttemptedUserIds.contains(s.id)) s,
    ];
    final maxBar = quiz.histogram.fold(0, (m, v) => v > m ? v : m);
    return Card(
      key: Key('quiz-insight-${quiz.quizId}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(quiz.name, style: theme.textTheme.titleMedium),
            if (quiz.flags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final f in quiz.flags)
                    Chip(
                      key: Key('quiz-flag-${f.code}'),
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        Icons.flag_outlined,
                        size: 16,
                        color: scheme.onErrorContainer,
                      ),
                      label: Text(f.label),
                      backgroundColor: scheme.errorContainer,
                      labelStyle: TextStyle(color: scheme.onErrorContainer),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text(
                  quiz.meanPercent == null
                      ? 'Chưa có điểm'
                      : 'Điểm TB ${_pct(quiz.meanPercent!)}%',
                ),
                Text('Đã làm ${quiz.finished}/${quiz.rosterSize}'),
                Text(
                  'Chưa làm ${quiz.notAttempted}'
                  '${quiz.notAttemptedPercent == null ? '' : ' (${_pct(quiz.notAttemptedPercent!)}%)'}',
                ),
                if (quiz.medianSeconds != null)
                  Text(
                    'Thời gian trung vị ${durationText(quiz.medianSeconds!)}'
                    '${quiz.timeLimitSeconds > 0 ? ' / ${durationText(quiz.timeLimitSeconds)}' : ''}',
                  ),
              ],
            ),
            if (quiz.finished > 0) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    minY: 0,
                    maxY: (maxBar < 4 ? 4 : maxBar + 1).toDouble(),
                    gridData: const FlGridData(drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (v, meta) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _bands[v.toInt().clamp(0, 4)],
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      for (var i = 0; i < 5; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: quiz.histogram[i].toDouble(),
                              color: i < 2 ? scheme.error : scheme.primary,
                              width: 18,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                if (remind != null && pending.isNotEmpty)
                  RemindAllButton(
                    count: pending.length,
                    label: 'Nhắc ${pending.length} SV chưa làm',
                    onPressed: () => remind(
                      pending,
                      ReminderDraft.forActivity(
                        title: quiz.name,
                        type: 'quiz',
                        sourceId: quiz.quizId,
                        due: quiz.close,
                      ),
                    ),
                  ),
                if (quiz.moodlePath != null)
                  MoodleButton(
                    path: quiz.moodlePath,
                    courseModuleId: quiz.courseModuleId,
                    compact: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
