import '../core/theme/app_colors.dart';
import '../core/data_profile.dart';
import '../core/display_text.dart';

import 'package:flutter/material.dart';

class CourseCard extends StatelessWidget {
  final String courseName;
  final String? courseShortname;
  final double? progressPercentage;
  final int? completedTasks;
  final int? totalTasks;
  final double? attendancePercentage;
  final VoidCallback onTap;

  const CourseCard({
    super.key,
    required this.courseName,
    this.courseShortname,
    this.progressPercentage,
    this.completedTasks,
    this.totalTasks,
    this.attendancePercentage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (progressPercentage ?? 0.0) / 100.0;
    final formattedProgress = progressPercentage != null
        ? '${vietnameseDecimal(progressPercentage!)}%'
        : 'Chưa có dữ liệu';

    final attendanceText = attendancePercentage != null
        ? '${DataProfile.isReal ? 'Điểm chuyên cần' : 'Chuyên cần'}: ${vietnameseDecimal(attendancePercentage!)}%'
        : DataProfile.noAttendance;

    final taskText = (completedTasks != null && totalTasks != null)
        ? '$completedTasks / $totalTasks hoạt động hoàn thành'
        : 'Chưa có dữ liệu công việc';

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DemoDisplayNames.course(courseName),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.strong,
                          ),
                        ),
                        if (courseShortname != null &&
                            courseShortname!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            courseShortname!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: context.muted),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DataProfile.isReal
                        ? '${DataProfile.progress}:'
                        : 'Tiến độ học tập:',
                    style: TextStyle(fontSize: 13, color: context.strong),
                  ),
                  Text(
                    formattedProgress,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: context.tint(Colors.blue),
                color: const Color(0xFF1E88E5),
                borderRadius: BorderRadius.circular(4),
                minHeight: 6,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.task_alt, size: 16, color: context.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          taskText,
                          style: TextStyle(fontSize: 13, color: context.strong),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.how_to_reg, size: 16, color: context.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attendanceText,
                          style: TextStyle(
                            fontSize: 13,
                            color: attendancePercentage == null
                                ? context.muted
                                : context.strong,
                          ),
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
