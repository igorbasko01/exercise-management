/// One completed session (all sets of one exercise template on one date),
/// with its all-time rank among every session of that template.
class ExerciseSessionSummary {
  final DateTime date;
  final double totalVolume;
  final int rank;
  final String setsLabel;

  ExerciseSessionSummary({
    required this.date,
    required this.totalVolume,
    required this.rank,
    required this.setsLabel,
  });
}

/// All-time ranking summary for a single exercise template: its most recent
/// session groups (newest first, at most two) and its all-time best session.
class ExerciseRankSummary {
  final String exerciseTemplateId;
  final String exerciseName;
  final List<ExerciseSessionSummary> recentSessions;
  final ExerciseSessionSummary? bestSession;

  ExerciseRankSummary({
    required this.exerciseTemplateId,
    required this.exerciseName,
    required this.recentSessions,
    this.bestSession,
  });
}
