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

/// Manages ranking of exercise groups by total volume
class ExerciseRankingManager {
  Map<RankKey, int> _ranks = {};

  /// Get the rank for a specific exercise group
  /// Returns 1 if the rank is not found (default/fallback)
  int getRank(String date, String templateId) {
    final key = RankKey(date, templateId);
    return _ranks[key] ?? 1;
  }

  /// Calculate and update ranks for all exercise groups based on total volume
  /// Ranks are calculated per exercise template, comparing sessions of the same exercise
  void calculateRanks(List<ExerciseSetPresentation> allSets, String Function(DateTime) formatDate) {
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

    // Assign ranks per template
    final newRanks = <RankKey, int>{};
    for (var templateEntries in volumesByTemplate.values) {
      // Sort entries for this template by volume (descending)
      final sortedEntries = templateEntries.toList()
        ..sort((a, b) => b.volume.compareTo(a.volume));
      
      // Assign ranks within this template
      for (var i = 0; i < sortedEntries.length; i++) {
        newRanks[sortedEntries[i].key] = i + 1;
      }
    }

    _ranks = newRanks;
  }

  /// Calculate total volume for a list of exercise sets
  /// Total volume = sum of (weight * repetitions) for all sets
  static double calculateTotalVolume(List<ExerciseSetPresentation> exercises) {
    return exercises
        .map((set) => (set.equipmentWeight + set.platesWeight) * set.repetitions)
        .fold(0.0, (value, element) => value + element);
  }
}
