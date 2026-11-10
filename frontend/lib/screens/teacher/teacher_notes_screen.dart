import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/api_exception.dart';
import '../../widgets/learning_note_dialog.dart';
import '../../widgets/async_tab.dart';

class TeacherNotesScreen extends StatefulWidget {
  final ApiService api;
  final int studentId;
  final String studentName;
  final int? courseId;

  const TeacherNotesScreen({
    super.key,
    required this.api,
    required this.studentId,
    required this.studentName,
    this.courseId,
  });

  @override
  State<TeacherNotesScreen> createState() => _TeacherNotesScreenState();
}

class _TeacherNotesScreenState extends State<TeacherNotesScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;
  Object? _loadError;
  final Set<int> _updating = {};

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final data = await widget.api.getTeacherNotes(
        widget.studentId,
        courseId: widget.courseId,
      );
      if (mounted) setState(() => _notes = data);
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
        isReflection: false,
        onSave: (content, level, status) => widget.api.addTeacherNote(
          widget.studentId,
          content,
          courseId: widget.courseId,
          status: status,
        ),
      ),
    );
    if (saved == true && mounted) await _loadNotes();
  }

  Future<void> _updateStatus(int noteId, bool resolved) async {
    if (_updating.contains(noteId)) return;
    setState(() => _updating.add(noteId));
    try {
      await widget.api.updateTeacherNoteStatus(
        noteId,
        resolved ? 'active' : 'resolved',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            resolved
                ? 'Đã chuyển về Đang theo dõi'
                : 'Đã đánh dấu Đã giải quyết',
          ),
        ),
      );
      await _loadNotes();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _updating.remove(noteId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ghi chú: ${widget.studentName}')),
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
                  CourseLoadError(onRetry: _loadNotes),
                ],
              ),
            )
          : _notes.isEmpty
          ? const Center(child: Text('Chưa có ghi chú nào.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (listContext, index) {
                final item = _notes[index];
                final date = DateTime.tryParse(item['created_at'] ?? '');
                final dateString = date != null
                    ? '${date.day}/${date.month}/${date.year}'
                    : '';
                final bool resolved = item['status'] == 'resolved';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      resolved ? Icons.check_circle : Icons.visibility,
                      color: resolved ? Colors.green : Colors.orange,
                    ),
                    title: Text(item['note'] ?? ''),
                    subtitle: Text(
                      'Trạng thái: ${resolved ? 'Đã giải quyết' : 'Đang theo dõi'} • Ngày: $dateString',
                    ),
                    trailing: IconButton(
                      icon: Icon(resolved ? Icons.undo : Icons.check),
                      tooltip: resolved
                          ? 'Đánh dấu đang theo dõi'
                          : 'Đánh dấu đã giải quyết',
                      onPressed:
                          item['id'] is! int || _updating.contains(item['id'])
                          ? null
                          : () => _updateStatus(item['id'] as int, resolved),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Thêm ghi chú'),
      ),
    );
  }
}
