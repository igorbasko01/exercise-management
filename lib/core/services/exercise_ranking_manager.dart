import 'package:exercise_management/data/models/exercise_set_presentation.dart';

/// Key for identifying a unique exercise group (date + template)
class RankKey {
  final String date;
  final String templateId;

  RankKey(this.date, this.templateId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankKey &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          templateId == other.templateId;

  @override
  int get hashCode => date.hashCode ^ templateId.hashCode;

  @override
  String toString() => '$date-$templateId';
}

/// Entry representing the total volume for an exercise group
class VolumeEntry {
  final RankKey key;
  final double volume;

  VolumeEntry(this.key, this.volume);
}

/// Pure ranking calculations shared by callers that need to rank exercise
/// groups by total volume without a database to do it in SQL (e.g. the
/// in-memory repository, or a fallback when a SQL ranks query fails).
class ExerciseRankingManager {
  /// Rank (1-based; ties share a rank, e.g. 1, 1, 3, 4, 4, 6...) of every
  /// exercise group in [allSets], grouped by date (via [formatDate]) and
  /// template, ranked within each template by total volume descending.
  static Map<RankKey, int> calculateRanks(List<ExerciseSetPresentation> allSets, String Function(DateTime) formatDate) {
    // Group sets by date and template
    final groupedSets = <RankKey, List<ExerciseSetPresentation>>{};
    for (var set in allSets) {
      final date = formatDate(set.dateTime);
      final key = RankKey(date, set.exerciseTemplateId);
      groupedSets.putIfAbsent(key, () => []).add(set);
    }

    // Calculate total volume for each group
    final volumeEntries = <VolumeEntry>[];
    for (var entry in groupedSets.entries) {
      final volume = calculateTotalVolume(entry.value);
      volumeEntries.add(VolumeEntry(entry.key, volume));
    }

    // Group by template ID to rank within each exercise type
    final volumesByTemplate = <String, List<VolumeEntry>>{};
    for (var entry in volumeEntries) {
      volumesByTemplate
          .putIfAbsent(entry.key.templateId, () => [])
          .add(entry);
    }

    // Assign ranks per template, using standard competition ranking so that
    // sessions tied on volume share the same rank (e.g. 1, 1, 3, 4, 4, 6...)
    final ranks = <RankKey, int>{};
    for (var templateEntries in volumesByTemplate.values) {
      // Sort entries for this template by volume (descending)
      final sortedEntries = templateEntries.toList()
        ..sort((a, b) => b.volume.compareTo(a.volume));

      int rank = 0;
      double? previousVolume;
      for (var i = 0; i < sortedEntries.length; i++) {
        final entry = sortedEntries[i];
        if (previousVolume == null || entry.volume < previousVolume) {
          rank = i + 1;
        }
        ranks[entry.key] = rank;
        previousVolume = entry.volume;
      }
    }

    return ranks;
  }

  /// Calculate total volume for a list of exercise sets
  /// Total volume = sum of (weight * repetitions) for all sets
  static double calculateTotalVolume(List<ExerciseSetPresentation> exercises) {
    return exercises
        .map((set) => (set.equipmentWeight + set.platesWeight) * set.repetitions)
        .fold(0.0, (value, element) => value + element);
  }
}
