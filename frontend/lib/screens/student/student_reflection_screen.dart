import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/learning_note_dialog.dart';
import '../../widgets/async_tab.dart';

class StudentReflectionScreen extends StatefulWidget {
  final ApiService api;
  final int? courseId;
  final String? courseName;

  const StudentReflectionScreen({
    super.key,
    required this.api,
    this.courseId,
    this.courseName,
  });

  @override
  State<StudentReflectionScreen> createState() =>
      _StudentReflectionScreenState();
}

class _StudentReflectionScreenState extends State<StudentReflectionScreen> {
  List<Map<String, dynamic>> _reflections = [];
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _loadReflections();
  }

  Future<void> _loadReflections() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await widget.api.getReflections(courseId: widget.courseId);
      if (mounted) setState(() => _reflections = data);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LearningNoteDialog(
        isReflection: true,
        onSave: (content, level, status) =>
            widget.api.addReflection(content, level, courseId: widget.courseId),
      ),
    );
    if (saved == true && mounted) await _loadReflections();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseName != null
              ? 'Nhật ký: ${widget.courseName}'
              : 'Nhật ký tự đánh giá',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      apiErrorMessage(_loadError!),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  CourseLoadError(onRetry: _loadReflections),
                ],
              ),
            )
          : _reflections.isEmpty
          ? const Center(child: Text('Chưa có nhật ký nào.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _reflections.length,
              itemBuilder: (context, index) {
                final item = _reflections[index];
                final date = DateTime.tryParse(item['created_at'] ?? '');
                final dateString = date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : '';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(item['content'] ?? ''),
                    subtitle: Text('Ngày: $dateString'),
                    trailing: CircleAvatar(
                      backgroundColor: _getColor(item['understanding_level']),
                      child: Text(
                        '${item['understanding_level'] ?? '?'}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ghi chép'),
      ),
    );
  }

  Color _getColor(dynamic level) {
    if (level == null) return context.muted;
    final intl = int.tryParse(level.toString()) ?? 0;
    if (intl <= 2) return Colors.red;
    if (intl == 3) return Colors.orange;
    return Colors.green;
  }
}
