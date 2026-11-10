import 'package:flutter/material.dart';

import '../../models/flashcard_review.dart';
import '../../services/api_service.dart';

/// V2-N5: one spaced-repetition session over the cards due now.
/// [courseId] null = due cards of every enrolled course (dashboard chip).
/// Pops with `true` when at least one answer was saved, so callers can refresh.
class FlashcardReviewScreen extends StatefulWidget {
  final ApiService api;
  final int? courseId;
  final String? courseName;

  const FlashcardReviewScreen({
    super.key,
    required this.api,
    this.courseId,
    this.courseName,
  });

  @override
  State<FlashcardReviewScreen> createState() => _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState extends State<FlashcardReviewScreen> {
  late Future<DueFlashcards> _future = _load();
  List<DueFlashcard> _cards = const [];
  int _index = 0;
  bool _showBack = false;
  bool _saving = false;
  final Map<ReviewRating, int> _answers = {};

  Future<DueFlashcards> _load() async {
    final due = await widget.api.getDueFlashcards(courseId: widget.courseId);
    _cards = due.cards;
    _index = 0;
    _showBack = false;
    _answers.clear();
    return due;
  }

  int get _answered => _answers.values.fold(0, (a, b) => a + b);

  Future<void> _rate(ReviewRating rating) async {
    final card = _cards[_index];
    setState(() => _saving = true);
    try {
      await widget.api.reviewFlashcard(card.courseId, card.id, rating);
      if (!mounted) return;
      setState(() {
        _answers[rating] = (_answers[rating] ?? 0) + 1;
        _index++;
        _showBack = false;
      });
    } catch (e) {
      debugPrint('Flashcard review failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lưu được kết quả ôn. Vui lòng thử lại.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.courseName == null
        ? 'Ôn tập hôm nay'
        : 'Ôn tập: ${widget.courseName}';
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _answered > 0);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: SafeArea(
          child: FutureBuilder<DueFlashcards>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _Message(
                  icon: Icons.cloud_off,
                  text: 'Không tải được thẻ cần ôn.',
                  action: 'Thử lại',
                  onAction: () => setState(() {
                    _future = _load();
                  }),
                );
              }
              if (_cards.isEmpty) {
                return _Message(
                  icon: Icons.task_alt,
                  text: 'Hôm nay không có thẻ nào cần ôn.',
                  subtitle:
                      'Lịch ôn được tính theo SM-2: thẻ nhớ tốt sẽ quay lại sau nhiều ngày hơn.',
                  action: 'Quay lại',
                  onAction: () => Navigator.pop(context, false),
                );
              }
              if (_index >= _cards.length) return _summary();
              return _cardView(_cards[_index]);
            },
          ),
        ),
      ),
    );
  }

  Widget _cardView(DueFlashcard card) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Thẻ ${_index + 1} / ${_cards.length}',
                style: text.titleSmall,
              ),
              const Spacer(),
              if (card.isNew)
                Chip(
                  label: const Text('Thẻ mới'),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: scheme.secondaryContainer,
                ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: _index / _cards.length),
          const SizedBox(height: 16),
          Expanded(
            child: Semantics(
              button: !_showBack,
              label: _showBack ? 'Mặt sau' : 'Mặt trước, chạm để lật',
              child: GestureDetector(
                key: const Key('review-card'),
                onTap: _showBack
                    ? null
                    : () => setState(() => _showBack = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _showBack
                        ? scheme.primaryContainer
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: scheme.outlineVariant, width: 2),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _showBack ? card.backText : card.frontText,
                      textAlign: TextAlign.center,
                      style: text.headlineSmall?.copyWith(
                        fontWeight: _showBack
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: _showBack
                            ? scheme.onPrimaryContainer
                            : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _showBack
                ? 'Bạn nhớ thẻ này ở mức nào? Số dưới mỗi nút là lần ôn kế tiếp.'
                : 'Chạm vào thẻ để lật',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          if (_showBack)
            Row(
              children: [
                for (final r in ReviewRating.values) ...[
                  if (r != ReviewRating.forgot) const SizedBox(width: 8),
                  Expanded(child: _ratingButton(card, r)),
                ],
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => setState(() => _showBack = true),
                icon: const Icon(Icons.sync),
                label: const Text('Lật thẻ'),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _ratingButton(DueFlashcard card, ReviewRating r) {
    final days = card.intervalFor(r);
    final scheme = Theme.of(context).colorScheme;
    final forgot = r == ReviewRating.forgot;
    return FilledButton.tonal(
      key: Key('rate-${r.name}'),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        backgroundColor: forgot ? scheme.errorContainer : null,
        foregroundColor: forgot ? scheme.onErrorContainer : null,
      ),
      onPressed: _saving ? null : () => _rate(r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(r.label, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (days != null)
            Text(intervalLabel(days), style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _summary() {
    final text = Theme.of(context).textTheme;
    final forgot = _answers[ReviewRating.forgot] ?? 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, size: 64, color: Colors.orange),
                const SizedBox(height: 12),
                Text('Đã ôn xong $_answered thẻ', style: text.titleLarge),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final r in ReviewRating.values)
                      Chip(label: Text('${r.label}: ${_answers[r] ?? 0}')),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  forgot > 0
                      ? '$forgot thẻ bạn quên sẽ quay lại vào ngày mai.'
                      : 'Các thẻ sẽ quay lại đúng ngày cần ôn tiếp theo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Xong'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subtitle;
  final String action;
  final VoidCallback onAction;

  const _Message({
    required this.icon,
    required this.text,
    required this.action,
    required this.onAction,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
}

/// Dashboard chip "Hôm nay cần ôn N thẻ"; hidden when nothing is due or the call fails.
class DueFlashcardsChip extends StatefulWidget {
  final ApiService api;
  const DueFlashcardsChip({super.key, required this.api});

  @override
  State<DueFlashcardsChip> createState() => _DueFlashcardsChipState();
}

class _DueFlashcardsChipState extends State<DueFlashcardsChip> {
  late Future<int?> _future = _load();

  Future<int?> _load() async {
    try {
      return (await widget.api.getDueFlashcards()).total;
    } catch (error) {
      debugPrint('Due flashcards chip: $error');
      return null;
    }
  }

  Future<void> _open() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FlashcardReviewScreen(api: widget.api)),
    );
    if (changed == true && mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<int?>(
    future: _future,
    builder: (context, snapshot) {
      final n = snapshot.data;
      if (n == null || n == 0) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: ActionChip(
          key: const Key('due-flashcards-chip'),
          avatar: const Icon(Icons.style, size: 18),
          label: Text('Hôm nay cần ôn $n thẻ'),
          onPressed: _open,
        ),
      );
    },
  );
}
