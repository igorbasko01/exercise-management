import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/services/exercise_ranking_manager.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  late ExerciseRankingManager manager;
  final dateFormat = DateFormat('yyyy-MM-dd');

  String formatDate(DateTime date) => dateFormat.format(date);

  setUp(() {
    manager = ExerciseRankingManager();
  });

  group('RankKey', () {
    test('should be equal when date and templateId match', () {
      final key1 = RankKey('2024-01-01', 'template1');
      final key2 = RankKey('2024-01-01', 'template1');

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('should not be equal when date differs', () {
      final key1 = RankKey('2024-01-01', 'template1');
      final key2 = RankKey('2024-01-02', 'template1');

      expect(key1, isNot(equals(key2)));
    });

    test('should not be equal when templateId differs', () {
      final key1 = RankKey('2024-01-01', 'template1');
      final key2 = RankKey('2024-01-01', 'template2');

      expect(key1, isNot(equals(key2)));
    });

    test('should have correct toString format', () {
      final key = RankKey('2024-01-01', 'template1');
      expect(key.toString(), equals('2024-01-01-template1'));
    });
  });

  group('VolumeEntry', () {
    test('should store key and volume correctly', () {
      final key = RankKey('2024-01-01', 'template1');
      final entry = VolumeEntry(key, 150.0);

      expect(entry.key, equals(key));
      expect(entry.volume, equals(150.0));
    });
  });

  group('calculateTotalVolume', () {
    test('should calculate total volume for single set', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
      ];

      final volume = ExerciseRankingManager.calculateTotalVolume(sets);

      // (20 + 80) * 10 = 1000
      expect(volume, equals(1000.0));
    });

    test('should calculate total volume for multiple sets', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 8,
        ),
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 6,
        ),
      ];

      final volume = ExerciseRankingManager.calculateTotalVolume(sets);

      // (100 * 10) + (100 * 8) + (100 * 6) = 2400
      expect(volume, equals(2400.0));
    });

    test('should return zero for empty list', () {
      final volume = ExerciseRankingManager.calculateTotalVolume([]);
      expect(volume, equals(0.0));
    });

    test('should handle zero weights and reps', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 0.0,
          platesWeight: 0.0,
          repetitions: 0,
        ),
      ];

      final volume = ExerciseRankingManager.calculateTotalVolume(sets);
      expect(volume, equals(0.0));
    });
  });

  group('getRank', () {
    test('should return 1 for unknown exercise group (default)', () {
      final rank = manager.getRank('2024-01-01', 'unknown-template');
      expect(rank, equals(1));
    });

    test('should return calculated rank after calculateRanks', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets, formatDate);
      final rank = manager.getRank('2024-01-01', 'template1');

      expect(rank, equals(1));
    });
  });

  group('calculateRanks', () {
    test('should assign rank 1 to single exercise group', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      expect(manager.getRank('2024-01-01', 'template1'), equals(1));
    });

    test('should rank by total volume (descending) for same template', () {
      final sets = [
        // Session 1: volume = 100 * 10 = 1000
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        // Session 2: volume = 100 * 12 = 1200 (highest)
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 12,
        ),
        // Session 3: volume = 100 * 8 = 800 (lowest)
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 3),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 8,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      expect(manager.getRank('2024-01-02', 'template1'), equals(1)); // Highest volume
      expect(manager.getRank('2024-01-01', 'template1'), equals(2)); // Middle volume
      expect(manager.getRank('2024-01-03', 'template1'), equals(3)); // Lowest volume
    });

    test('should calculate total volume across multiple sets in same session', () {
      final sets = [
        // Session 1: 3 sets, total volume = 1000 + 800 + 600 = 2400
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 8,
        ),
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 6,
        ),
        // Session 2: 1 set, total volume = 1500
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 25.0,
          platesWeight: 125.0,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      expect(manager.getRank('2024-01-01', 'template1'), equals(1)); // 2400 volume
      expect(manager.getRank('2024-01-02', 'template1'), equals(2)); // 1500 volume
    });

    test('should rank independently for different templates', () {
      final sets = [
        // Template 1, Session 1: volume = 1000
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        // Template 1, Session 2: volume = 1200
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 12,
        ),
        // Template 2, Session 1: volume = 500
        _createExerciseSet(
          templateId: 'template2',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 10.0,
          platesWeight: 40.0,
          repetitions: 10,
        ),
        // Template 2, Session 2: volume = 600
        _createExerciseSet(
          templateId: 'template2',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 10.0,
          platesWeight: 40.0,
          repetitions: 12,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      // Template 1 rankings (independent)
      expect(manager.getRank('2024-01-02', 'template1'), equals(1));
      expect(manager.getRank('2024-01-01', 'template1'), equals(2));

      // Template 2 rankings (independent)
      expect(manager.getRank('2024-01-02', 'template2'), equals(1));
      expect(manager.getRank('2024-01-01', 'template2'), equals(2));
    });

    test('should handle same date with different templates', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'template2',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 10.0,
          platesWeight: 40.0,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      expect(manager.getRank('2024-01-01', 'template1'), equals(1));
      expect(manager.getRank('2024-01-01', 'template2'), equals(1));
    });

    test('should handle empty sets list', () {
      manager.calculateRanks([], formatDate);

      expect(manager.getRank('2024-01-01', 'template1'), equals(1)); // Default
    });

    test('should update ranks when calculateRanks is called multiple times', () {
      // First calculation
      final sets1 = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets1, formatDate);
      expect(manager.getRank('2024-01-01', 'template1'), equals(1));

      // Second calculation with new data
      final sets2 = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 15,
        ),
      ];

      manager.calculateRanks(sets2, formatDate);
      expect(manager.getRank('2024-01-02', 'template1'), equals(1)); // Now rank 1
      expect(manager.getRank('2024-01-01', 'template1'), equals(2)); // Now rank 2
    });

    test('should handle complex scenario with multiple templates and sessions', () {
      final sets = [
        // Bench Press - Session 1 (Jan 1): 3 sets, total volume = 2400
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 8,
        ),
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.0,
          platesWeight: 80.0,
          repetitions: 6,
        ),
        // Bench Press - Session 2 (Jan 3): 2 sets, total volume = 2100
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 3),
          equipmentWeight: 20.0,
          platesWeight: 85.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 3),
          equipmentWeight: 20.0,
          platesWeight: 85.0,
          repetitions: 10,
        ),
        // Bench Press - Session 3 (Jan 5): 3 sets, total volume = 3300 (highest)
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 5),
          equipmentWeight: 20.0,
          platesWeight: 90.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 5),
          equipmentWeight: 20.0,
          platesWeight: 90.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'bench-press',
          date: DateTime(2024, 1, 5),
          equipmentWeight: 20.0,
          platesWeight: 90.0,
          repetitions: 10,
        ),
        // Squat - Session 1 (Jan 2): 2 sets, total volume = 3000 (highest for squat)
        _createExerciseSet(
          templateId: 'squat',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 20.0,
          platesWeight: 130.0,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'squat',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 20.0,
          platesWeight: 130.0,
          repetitions: 10,
        ),
        // Squat - Session 2 (Jan 4): 1 set, total volume = 1400
        _createExerciseSet(
          templateId: 'squat',
          date: DateTime(2024, 1, 4),
          equipmentWeight: 20.0,
          platesWeight: 120.0,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      // Bench Press rankings
      expect(manager.getRank('2024-01-05', 'bench-press'), equals(1)); // 3300 volume
      expect(manager.getRank('2024-01-01', 'bench-press'), equals(2)); // 2400 volume
      expect(manager.getRank('2024-01-03', 'bench-press'), equals(3)); // 2100 volume

      // Squat rankings (independent from bench press)
      expect(manager.getRank('2024-01-02', 'squat'), equals(1)); // 3000 volume
      expect(manager.getRank('2024-01-04', 'squat'), equals(2)); // 1400 volume
    });

    test('should handle fractional weights', () {
      final sets = [
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 1),
          equipmentWeight: 20.5,
          platesWeight: 79.5,
          repetitions: 10,
        ),
        _createExerciseSet(
          templateId: 'template1',
          date: DateTime(2024, 1, 2),
          equipmentWeight: 22.5,
          platesWeight: 82.5,
          repetitions: 10,
        ),
      ];

      manager.calculateRanks(sets, formatDate);

      expect(manager.getRank('2024-01-02', 'template1'), equals(1)); // 1050 volume
      expect(manager.getRank('2024-01-01', 'template1'), equals(2)); // 1000 volume
    });
  });
}

ExerciseSetPresentation _createExerciseSet({
  required String templateId,
  required DateTime date,
  required double equipmentWeight,
  required double platesWeight,
  required int repetitions,
}) {
  return ExerciseSetPresentation(
    setId: 'set-${date.millisecondsSinceEpoch}-$templateId',
    exerciseTemplateId: templateId,
    dateTime: date,
    equipmentWeight: equipmentWeight,
    platesWeight: platesWeight,
    repetitions: repetitions,
    displayName: 'Exercise $templateId',
    repetitionsRange: RepetitionsRange.medium,
  );
}

