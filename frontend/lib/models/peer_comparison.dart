double? _d(Object? v) => v is num ? v.toDouble() : null;
int? _i(Object? v) => v is num ? v.toInt() : null;

/// One anonymous class metric. When [suppressed] only [classSize] is known.
class PeerMetric {
  final bool suppressed;
  final int classSize;
  final double? mine, median, percentBelow;
  final List<int> histogram;
  final int? myBin;

  const PeerMetric({
    required this.suppressed,
    required this.classSize,
    this.mine,
    this.median,
    this.percentBelow,
    this.histogram = const [],
    this.myBin,
  });

  factory PeerMetric.fromJson(Object? raw) {
    final j = raw is Map<String, dynamic> ? raw : const <String, dynamic>{};
    return PeerMetric(
      suppressed: j['suppressed'] != false,
      classSize: _i(j['classSize']) ?? 0,
      mine: _d(j['mine']),
      median: _d(j['median']),
      percentBelow: _d(j['percentBelow']),
      histogram: (j['histogram'] is List ? j['histogram'] as List : const [])
          .whereType<Map>()
          .map((h) => _i(h['count']) ?? 0)
          .toList(),
      myBin: _i(j['myBin']),
    );
  }

  /// "Bạn cao hơn 64,3% bạn cùng lớp · trung vị lớp 55,0%".
  String conclusion(String what) {
    if (suppressed) return 'Lớp quá nhỏ để so sánh ẩn danh';
    String f(double v) => '${v.toStringAsFixed(1).replaceAll('.', ',')}%';
    final medianText = median == null ? '' : ' · trung vị lớp ${f(median!)}';
    if (mine == null || percentBelow == null) {
      return 'Bạn chưa có dữ liệu $what$medianText';
    }
    return '$what của bạn ${f(mine!)}, cao hơn ${f(percentBelow!)} bạn cùng lớp$medianText';
  }
}

class PeerComparison {
  final int minClassSize;
  final PeerMetric progress, grade;

  const PeerComparison({
    required this.minClassSize,
    required this.progress,
    required this.grade,
  });

  factory PeerComparison.fromJson(Map<String, dynamic> j) => PeerComparison(
    minClassSize: _i(j['minClassSize']) ?? 5,
    progress: PeerMetric.fromJson(j['progress']),
    grade: PeerMetric.fromJson(j['grade']),
  );
}
