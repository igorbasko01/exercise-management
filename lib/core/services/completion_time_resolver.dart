import 'package:clock/clock.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';

/// Outcome of resolving when a set was actually completed: the timestamp to
/// stamp, and whether it was derived from sibling sets rather than "now".
typedef CompletionTimeResolution = ({DateTime completedAt, bool isDerived});

/// Decides the `completedAt` timestamp to stamp when a set is marked
/// complete:
///
/// 1. The set's own day is today -> now.
/// 2. A past day -> the latest completion among that day's other sets, plus
///    a one-minute offset.
/// 3. A past day with no completions yet -> the set's own `dateTime`.
class CompletionTimeResolver {
  static CompletionTimeResolution resolve(
    ExerciseSetPresentation set,
    List<ExerciseSetPresentation> siblingsOnSameDay,
  ) {
    final now = clock.now();
    if (_isSameDay(set.dateTime, now)) {
      return (completedAt: now, isDerived: false);
    }

    final latestCompletion = siblingsOnSameDay
        .map((sibling) => sibling.completedAt)
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (max, dt) => max == null || dt.isAfter(max) ? dt : max);

    final completedAt = latestCompletion == null
        ? set.dateTime
        : latestCompletion.add(const Duration(minutes: 1));

    return (completedAt: completedAt, isDerived: true);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
