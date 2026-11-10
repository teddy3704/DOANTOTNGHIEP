import '../core/display_text.dart';

double? _d(Object? v) => v is num ? v.toDouble() : null;
int? _i(Object? v) => v is num ? v.toInt() : null;

/// One gradable activity with its effective share of the final grade (shares sum to 1).
class ForecastItem {
  final int gradeItemId;
  final String name;
  final String? activityType;
  final String? category;
  final double? scorePercent;
  final double weight;
  final int? dueTime;
  final String? moodlePath;
  final int? courseModuleId;

  const ForecastItem({
    required this.gradeItemId,
    required this.name,
    required this.weight,
    this.activityType,
    this.category,
    this.scorePercent,
    this.dueTime,
    this.moodlePath,
    this.courseModuleId,
  });

  bool get isGraded => scorePercent != null;

  factory ForecastItem.fromJson(Map<String, dynamic> json) => ForecastItem(
    gradeItemId: _i(json['gradeItemId']) ?? 0,
    name: json['name']?.toString() ?? 'Hoạt động',
    activityType: json['activityType']?.toString(),
    category: json['category']?.toString(),
    scorePercent: _d(json['scorePercent']),
    weight: _d(json['weight']) ?? 0,
    dueTime: _i(json['dueTime']),
    moodlePath: json['moodlePath']?.toString(),
    courseModuleId: _i(json['courseModuleId']),
  );
}

enum ForecastOutcome { achieved, feasible, notFeasible, noRemaining }

/// Grade forecast from the server. Projections for other targets or slider values are computed
/// here with the server's weights: final = Σ wᵢ·sᵢ (graded) + Σ wⱼ·plannedⱼ (ungraded).
class GradeForecast {
  final double? current;
  final double passPercent;
  final bool passFromDefault;
  final bool approximation;
  final double gradedContribution;
  final double remainingWeight;
  final List<ForecastItem> items;

  const GradeForecast({
    required this.current,
    required this.passPercent,
    required this.passFromDefault,
    required this.approximation,
    required this.gradedContribution,
    required this.remainingWeight,
    required this.items,
  });

  factory GradeForecast.fromJson(Map<String, dynamic> json) => GradeForecast(
    current: _d(json['current']),
    passPercent: _d(json['passPercent']) ?? 50,
    passFromDefault: json['passSource'] != 'items',
    approximation: json['approximation'] == true,
    gradedContribution: _d(json['gradedContribution']) ?? 0,
    remainingWeight: _d(json['remainingWeight']) ?? 0,
    items: (json['items'] is List ? json['items'] as List : const [])
        .whereType<Map<String, dynamic>>()
        .map(ForecastItem.fromJson)
        .toList(),
  );

  List<ForecastItem> get remaining => items.where((i) => !i.isGraded).toList();
  List<ForecastItem> get graded => items.where((i) => i.isGraded).toList();
  bool get hasRemaining => remainingWeight > 1e-9;
  double get bestCase => gradedContribution + remainingWeight * 100;

  /// Average % needed on every ungraded item to reach [target]; null when nothing is left.
  double? needFor(double target) =>
      hasRemaining ? (target - gradedContribution) / remainingWeight : null;

  ForecastOutcome outcomeFor(double target) {
    final need = needFor(target);
    if (need == null) return ForecastOutcome.noRemaining;
    if (need <= 1e-9) return ForecastOutcome.achieved;
    return need <= 100 + 1e-9
        ? ForecastOutcome.feasible
        : ForecastOutcome.notFeasible;
  }

  /// Final grade if each ungraded item gets [planned] (gradeItemId → %), missing ones 0.
  double projected(Map<int, double> planned) {
    var total = gradedContribution;
    for (final item in remaining) {
      total += item.weight * (planned[item.gradeItemId] ?? 0);
    }
    return total;
  }

  /// Plain-language conclusion for a target; every number comes from the fields above.
  String conclusion(double target) {
    final t = formatPercentageVi(target);
    final n = remaining.length;
    switch (outcomeFor(target)) {
      case ForecastOutcome.noRemaining:
        final finalGrade = formatPercentageVi(gradedContribution);
        return gradedContribution + 1e-9 >= target
            ? 'Đã chấm hết các bài. Tổng điểm $finalGrade, đạt mục tiêu $t.'
            : 'Đã chấm hết các bài. Tổng điểm $finalGrade, chưa đạt mục tiêu $t.';
      case ForecastOutcome.achieved:
        return 'Bạn đã chắc chắn đạt $t, kể cả khi $n bài còn lại được 0 điểm.';
      case ForecastOutcome.feasible:
        return 'Bạn cần trung bình ${formatPercentageVi(needFor(target))} ở $n bài còn lại để đạt $t.';
      case ForecastOutcome.notFeasible:
        return 'Không thể đạt $t: kể cả được 100% ở $n bài còn lại, tổng tối đa là ${formatPercentageVi(bestCase)}.';
    }
  }
}
