import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExerciseSet', () {
    final now = DateTime.now();
    final exerciseSet = ExerciseSet(
      id: '1',
      exerciseTemplateId: 'template1',
      dateTime: now,
      equipmentWeight: 10,
      platesWeight: 20,
      repetitions: 8,
      completedAt: now,
    );

    test('copyWith should update completedAt when Value is provided', () {
      final newCompletedAt = now.add(const Duration(hours: 1));
      final updatedSet = exerciseSet.copyWith(
        completedAt: Value(newCompletedAt),
      );

      expect(updatedSet.completedAt, newCompletedAt);
      expect(updatedSet.id, exerciseSet.id);
    });

    test('copyWith should set completedAt to null when Value(null) is provided',
        () {
      final updatedSet = exerciseSet.copyWith(
        completedAt: const Value(null),
      );

      expect(updatedSet.completedAt, isNull);
      expect(updatedSet.id, exerciseSet.id);
    });

    test('copyWith should not update completedAt when not provided', () {
      final updatedSet = exerciseSet.copyWith(
        repetitions: 12,
      );

      expect(updatedSet.completedAt, exerciseSet.completedAt);
      expect(updatedSet.repetitions, 12);
    });

    test('copyWith should update id when Value is provided', () {
      final updatedSet = exerciseSet.copyWith(
        id: const Value('newId'),
      );

      expect(updatedSet.id, 'newId');
    });

    test('copyWith should set id to null when Value(null) is provided', () {
      final updatedSet = exerciseSet.copyWith(
        id: const Value(null),
      );

      expect(updatedSet.id, isNull);
    });
  });
}
