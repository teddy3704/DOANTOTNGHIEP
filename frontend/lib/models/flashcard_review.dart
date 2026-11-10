/// V2-N5: spaced-repetition (SM-2) review data from
/// GET /dev/students/{id}/flashcards/due and POST …/flashcards/{id}/review.
library;

int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

/// The four answer buttons and the SM-2 quality each one sends.
enum ReviewRating {
  forgot(1, 'Quên'),
  hard(3, 'Khó'),
  good(4, 'Được'),
  easy(5, 'Dễ');

  final int value;
  final String label;
  const ReviewRating(this.value, this.label);
}

/// "1 ngày", "6 ngày", "2 tháng", "1,5 năm".
String intervalLabel(int days) {
  if (days < 30) return '$days ngày';
  if (days < 365) return '${(days / 30).round()} tháng';
  final years = (days / 365).toStringAsFixed(1).replaceAll('.', ',');
  return '${years.endsWith(',0') ? years.substring(0, years.length - 2) : years} năm';
}

class DueFlashcard {
  final int id;
  final int courseId;
  final String frontText;
  final String backText;
  final bool isNew;
  final int repetitions;
  final int intervalDays;

  /// Next interval in days for each button, keyed by SM-2 quality.
  final Map<int, int> nextIntervals;

  const DueFlashcard({
    required this.id,
    required this.courseId,
    required this.frontText,
    required this.backText,
    required this.isNew,
    required this.repetitions,
    required this.intervalDays,
    required this.nextIntervals,
  });

  factory DueFlashcard.fromJson(Map<String, dynamic> j) {
    final raw = j['nextIntervals'];
    final next = <int, int>{};
    if (raw is Map) {
      raw.forEach((k, v) {
        final key = int.tryParse(k.toString());
        if (key != null && v is num) next[key] = v.toInt();
      });
    }
    return DueFlashcard(
      id: _i(j['id']),
      courseId: _i(j['courseId']),
      frontText: j['frontText']?.toString() ?? '',
      backText: j['backText']?.toString() ?? '',
      isNew: j['isNew'] == true,
      repetitions: _i(j['repetitions']),
      intervalDays: _i(j['intervalDays']),
      nextIntervals: next,
    );
  }

  int? intervalFor(ReviewRating r) => nextIntervals[r.value];
}

class DueFlashcards {
  final int total;
  final int newCount;
  final int reviewCount;
  final List<DueFlashcard> cards;

  const DueFlashcards({
    required this.total,
    required this.newCount,
    required this.reviewCount,
    required this.cards,
  });

  factory DueFlashcards.fromJson(Map<String, dynamic> j) {
    final raw = j['cards'];
    if (raw is! List) throw const FormatException('Expected due cards list');
    final cards = [
      for (final c in raw)
        if (c is Map<String, dynamic>)
          DueFlashcard.fromJson(c)
        else
          throw const FormatException('Invalid due card'),
    ];
    return DueFlashcards(
      total: _i(j['total'], cards.length),
      newCount: _i(j['newCount']),
      reviewCount: _i(j['reviewCount']),
      cards: cards,
    );
  }
}

class ReviewResult {
  final int intervalDays;
  final DateTime? dueAt;

  const ReviewResult({required this.intervalDays, this.dueAt});

  factory ReviewResult.fromJson(Map<String, dynamic> j) => ReviewResult(
    intervalDays: _i(j['intervalDays']),
    dueAt: DateTime.tryParse(j['dueAt']?.toString() ?? ''),
  );
}
