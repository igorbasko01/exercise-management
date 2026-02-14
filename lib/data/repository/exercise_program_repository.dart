import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';

abstract class ExerciseProgramRepository {
  Future<Result<List<ExerciseProgram>>> getPrograms();
  Future<Result<ExerciseProgram>> getProgram(String id);
  Future<Result<ExerciseProgram>> addProgram(ExerciseProgram program);
  Future<Result<ExerciseProgram>> updateProgram(ExerciseProgram program);
  Future<Result<ExerciseProgram>> deleteProgram(String id);
}
