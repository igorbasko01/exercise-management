import 'package:exercise_management/data/models/exercise.dart';
import 'package:exercise_management/data/repository/exercise_repository.dart';

class InMemoryExerciseRepository extends ExerciseRepository {
  final List<Exercise> _exercises = [];

  @override
  Future<void> addExercise(Exercise exercise) async {
    _exercises.add(exercise);
  }

  @override
  Future<List<Exercise>> getExercises() async {
    return _exercises;
  }

  @override
  Future<Exercise> getExercise(String id) async {
    return _exercises.firstWhere((exercise) => exercise.id == id);
  }
}