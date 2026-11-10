import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'flashcard_review_screen.dart';

class StudentFlashcardScreen extends StatefulWidget {
  final ApiService api;
  final int courseId;
  final String courseName;

  /// When set, the add-card dialog opens after loading with this front text (V2-N2).
  final String? openAddWithFront;

  const StudentFlashcardScreen({
    super.key,
    required this.api,
    required this.courseId,
    required this.courseName,
    this.openAddWithFront,
  });

  @override
  State<StudentFlashcardScreen> createState() => _StudentFlashcardScreenState();
}

class _StudentFlashcardScreenState extends State<StudentFlashcardScreen> {
  List<Map<String, dynamic>> _flashcards = [];
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = true;

  /// Cards due now by SM-2 (V2-N5); null when the count could not be loaded.
  int? _dueCount;

  @override
  void initState() {
    super.initState();
    _loadFlashcards().then((_) {
      final front = widget.openAddWithFront;
      if (front != null && mounted) _showFlashcardDialog(initialFront: front);
    });
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    try {
      final data = await widget.api.getFlashcards(widget.courseId);
      final reflections = await widget.api.getReflections(
        courseId: widget.courseId,
      );

      final weakReflections = reflections.where((r) {
        final level =
            int.tryParse(r['understanding_level']?.toString() ?? '5') ?? 5;
        return level <= 2;
      }).toList();

      int? due;
      try {
        due = (await widget.api.getDueFlashcards(
          courseId: widget.courseId,
        )).total;
      } catch (e) {
        debugPrint('Failed to load due flashcards: $e');
      }

      if (!mounted) return;
      setState(() {
        _flashcards = data;
        _suggestions = weakReflections;
        _dueCount = due;
      });
    } catch (e) {
      debugPrint('Failed to load flashcards: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi tải dữ liệu flashcard!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startReview() async {
    if (_flashcards.isEmpty) return;
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardReviewScreen(
          api: widget.api,
          courseId: widget.courseId,
          courseName: widget.courseName,
        ),
      ),
    );
    if (changed == true && mounted) _loadFlashcards();
  }

  void _showFlashcardDialog({
    Map<String, dynamic>? card,
    String? initialFront,
  }) {
    final bool isEdit = card != null;
    final TextEditingController frontController = TextEditingController(
      text: isEdit ? card['front_text'] : (initialFront ?? ''),
    );
    final TextEditingController backController = TextEditingController(
      text: isEdit ? card['back_text'] : '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEdit ? 'Chỉnh sửa thẻ' : 'Thêm thẻ ghi nhớ mới'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(
                  labelText: 'Mặt trước (Câu hỏi/Thuật ngữ)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 255,
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: backController,
                decoration: const InputDecoration(
                  labelText: 'Mặt sau (Câu trả lời/Định nghĩa)',
                  border: OutlineInputBorder(),
                ),
                maxLength: 1000,
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Xác nhận xóa'),
                      content: const Text(
                        'Bạn có chắc chắn muốn xóa thẻ này? Dữ liệu không thể khôi phục.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Hủy'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext); // close edit dialog
                    }
                    try {
                      await widget.api.deleteFlashcard(
                        widget.courseId,
                        card['id'],
                      );
                      _loadFlashcards();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa thẻ')),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lỗi khi xóa thẻ')),
                      );
                    }
                  }
                },
                child: const Text(
                  'Xóa thẻ',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final front = frontController.text.trim();
                final back = backController.text.trim();
                if (front.isEmpty || back.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập đủ mặt trước và mặt sau'),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                try {
                  if (isEdit) {
                    await widget.api.updateFlashcard(
                      widget.courseId,
                      card['id'],
                      front,
                      back,
                    );
                  } else {
                    await widget.api.addFlashcard(widget.courseId, front, back);
                  }
                  _loadFlashcards();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isEdit ? 'Đã cập nhật thẻ' : 'Đã thêm thẻ mới',
                      ),
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi khi lưu thẻ')),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.end,
        );
      },
    );
  }

  Widget _buildListMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_suggestions.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Gợi ý từ Nhật ký tự đánh giá (Chưa hiểu rõ)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.strong,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final text = _suggestions[index]['content']?.toString() ?? '';
                return Card(
                  color: context.tint(Colors.orange),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: context.tintBorder(Colors.orange)),
                  ),
                  child: Container(
                    width: 240,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.orange.shade900,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () =>
                                _showFlashcardDialog(initialFront: text),
                            child: const Text(
                              'Tạo thẻ',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 32),
        ],
        if (_flashcards.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style, size: 64, color: context.hairline),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có thẻ ghi nhớ nào.',
                    style: TextStyle(color: context.muted),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _showFlashcardDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo thẻ đầu tiên'),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('start-review'),
                      onPressed: _startReview,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(switch (_dueCount) {
                        null => 'Bắt đầu ôn tập',
                        0 => 'Bắt đầu ôn tập (không có thẻ đến hạn)',
                        final n => 'Bắt đầu ôn tập · $n thẻ đến hạn',
                      }),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _flashcards.length,
                    itemBuilder: (context, index) {
                      final card = _flashcards[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _showFlashcardDialog(card: card),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        card['front_text'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: context.muted,
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Text(
                                  card['back_text'] ?? '',
                                  style: TextStyle(color: context.muted),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thẻ ghi nhớ: ${widget.courseName}')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildListMode(),
      ),
      floatingActionButton: _flashcards.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showFlashcardDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thẻ'),
            )
          : null,
    );
  }
}
