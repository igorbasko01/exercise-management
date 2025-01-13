import 'package:exercise_management/data/models/exercise.dart';

abstract class ExerciseRepository {
  Future<void> addExercise(Exercise exercise);
  Future<void> deleteExercise(Exercise exercise);
  Future<void> updateExercise(Exercise exercise);
  Future<List<Exercise>> getExercises();
  Future<Exercise> getExercise(String id);
}