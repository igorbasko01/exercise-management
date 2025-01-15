import 'package:exercise_management/data/models/exercise.dart';

abstract class ExerciseService {
  Future<void> addExercise(Exercise exercise);
  Future<List<Exercise>> getExercises();
  Future<Exercise> getExercise(String id);
}