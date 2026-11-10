/// Display-only aliases. Production source values and business IDs stay intact.
/// Enable explicitly for the demo build: --dart-define=DEMO_DISPLAY_NAMES=true.
class DemoDisplayNames {
  static const enabled = bool.fromEnvironment('DEMO_DISPLAY_NAMES');

  static String course(String source, {bool demo = enabled}) => !demo
      ? source
      : switch (source) {
          'Software Testing' => 'Kiểm thử phần mềm',
          'Mobile Application Development' => 'Phát triển ứng dụng di động',
          _ => source,
        };

  static String activity(String source, {bool demo = enabled}) {
    if (!demo) return source;
    const aliases = {
      'Android API Assignment': 'Bài tập API Android',
      'Boundary Value Assignment': 'Bài tập Phân tích giá trị biên',
      'Decision Table Assignment': 'Bài tập Bảng quyết định',
      'Software Testing Quiz': 'Bài kiểm tra Kiểm thử phần mềm',
    };
    if (aliases.containsKey(source)) return aliases[source]!;
    final match = RegExp(
      r'^MVP3 - (Bài tập|Quiz) (\d+\.\d+)$',
    ).firstMatch(source);
    if (match == null) return source;
    return '${match[1] == 'Quiz' ? 'Bài kiểm tra' : 'Bài tập'} ${match[2]}';
  }

  static String section(String source, {bool demo = enabled}) =>
      demo && source == 'Course Activities' ? 'Hoạt động khóa học' : source;
}

String vietnameseDecimal(num value, {int digits = 1}) =>
    value.toStringAsFixed(digits).replaceAll('.', ',');

String gradeCategoryLabel(String source) =>
    source == 'Điểm quá trình' ? 'Điểm hoạt động trong kỳ' : source;

/// Presentation only: preserve null and show one Vietnamese decimal place.
String formatPercentageVi(num? value) =>
    value == null ? 'Chưa có dữ liệu' : '${vietnameseDecimal(value)}%';
