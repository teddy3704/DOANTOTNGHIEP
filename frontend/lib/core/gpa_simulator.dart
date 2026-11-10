import '../models/portal.dart';

/// V3-P3 what-if engine. Same formulas as the backend's AcademicEngine:
/// projected = (GPA × C + Σ credits × score4) / (C + Σ credits);
/// need(band) = (band × (C + R) − GPA × C) / R.
enum TargetStatus { achieved, feasible, notFeasible }

class TargetResult {
  final GradeBand band;
  final double? needed;
  final TargetStatus status;
  const TargetResult(this.band, this.needed, this.status);
}

class SimulationResult {
  final double? projectedGpa;
  final int countedCredits;
  final int remainingCredits;
  final String? band;
  final List<TargetResult> targets;
  const SimulationResult({
    required this.projectedGpa,
    required this.countedCredits,
    required this.remainingCredits,
    required this.band,
    required this.targets,
  });
}

class GpaSimulator {
  final double gpa;
  final int credits;
  final int remainingCredits;
  final List<GradeBand> bands;
  final List<LetterGrade> conversion;

  const GpaSimulator({
    required this.gpa,
    required this.credits,
    required this.remainingCredits,
    required this.bands,
    required this.conversion,
  });

  factory GpaSimulator.of(GpaSimulation s) => GpaSimulator(
    gpa: s.gpa4 ?? 0,
    credits: s.credits,
    remainingCredits: s.remainingCredits,
    bands: s.bands,
    conversion: s.conversion,
  );

  double? score4(String letter) {
    for (final g in conversion) {
      if (g.letter == letter) return g.score4;
    }
    return null;
  }

  String? bandOf(double? g) {
    if (g == null) return null;
    for (final b in bands) {
      if (g >= b.min - 1e-9) return b.name;
    }
    return null;
  }

  List<TargetResult> targets(double g, int c, int r) => [
    for (final b in bands)
      if (r <= 0)
        TargetResult(
          b,
          null,
          g >= b.min - 1e-9 ? TargetStatus.achieved : TargetStatus.notFeasible,
        )
      else
        () {
          final need = (b.min * (c + r) - g * c) / r;
          final status = need <= 1e-9
              ? TargetStatus.achieved
              : need <= 4 + 1e-9
              ? TargetStatus.feasible
              : TargetStatus.notFeasible;
          return TargetResult(b, need, status);
        }(),
  ];

  /// [chosen]: credits → letter for the courses the student has set ("nếu tôi được…").
  SimulationResult simulate(List<(int credits, String letter)> chosen) {
    var points = gpa * credits;
    var total = credits;
    var used = 0;
    for (final (cr, letter) in chosen) {
      final s4 = score4(letter);
      if (s4 == null || cr <= 0) continue;
      points += s4 * cr;
      total += cr;
      used += cr;
    }
    final projected = total == 0 ? null : points / total;
    final remaining = (remainingCredits - used).clamp(0, 1 << 30);
    return SimulationResult(
      projectedGpa: projected,
      countedCredits: total,
      remainingCredits: remaining,
      band: bandOf(projected),
      targets: targets(projected ?? 0, total, remaining),
    );
  }
}
