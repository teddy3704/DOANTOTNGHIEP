import 'package:flutter/material.dart';

import '../services/api_exception.dart';

/// Shared by reflections and teacher support notes. Keep the draft visible
/// until the server confirms the save, and do not submit twice while pending.
class LearningNoteDialog extends StatefulWidget {
  final bool isReflection;
  final Future<void> Function(String content, int level, String status) onSave;
  const LearningNoteDialog({
    super.key,
    required this.isReflection,
    required this.onSave,
  });

  @override
  State<LearningNoteDialog> createState() => _LearningNoteDialogState();
}

class _LearningNoteDialogState extends State<LearningNoteDialog> {
  final _controller = TextEditingController();
  int _level = 3;
  String _status = 'active';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final content = _controller.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Vui lòng nhập nội dung.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(content, _level, _status);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = apiErrorMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        widget.isReflection
            ? 'Thêm nhật ký tự đánh giá'
            : 'Thêm ghi chú hỗ trợ',
      ),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            enabled: !_saving,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: widget.isReflection
                  ? 'Bạn đã học được gì? (Ghi chú)'
                  : 'Ghi chú về tình hình sinh viên',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          if (widget.isReflection) ...[
            const Text('Mức độ hiểu bài:'),
            Slider(
              value: _level.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_level',
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _level = value.toInt()),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Kém'), Text('Tốt')],
            ),
          ] else
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Trạng thái',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'active', child: Text('Đang theo dõi')),
                DropdownMenuItem(
                  value: 'resolved',
                  child: Text('Đã giải quyết'),
                ),
              ],
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value != null) setState(() => _status = value);
                    },
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
}
