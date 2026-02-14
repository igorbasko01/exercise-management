import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';

class InMemoryExerciseProgramRepository implements ExerciseProgramRepository {
  final Map<String, ExerciseProgram> _programs = {};
  int _nextId = 1;
  int _nextSessionId = 1;

  @override
  Future<Result<List<ExerciseProgram>>> getPrograms() async {
    return Result.ok(_programs.values.toList());
  }

  @override
  Future<Result<ExerciseProgram>> getProgram(String id) async {
    if (_programs.containsKey(id)) {
      return Result.ok(_programs[id]!);
    }
    return Result.error(ExerciseNotFoundException('Program $id not found'));
  }

  @override
  Future<Result<ExerciseProgram>> addProgram(ExerciseProgram program) async {
    final id = _nextId.toString();
    _nextId++;

    if (program.isActive) {
      _programs.forEach((key, value) {
        if (value.isActive) {
          _programs[key] = value.copyWith(isActive: false);
        }
      });
    }

    // Assign IDs to sessions too
    final sessions = program.sessions.map((s) {
      final sId = _nextSessionId.toString();
      _nextSessionId++;
      return s.copyWith(
        id: Value(sId),
        programId: Value(id),
      );
    }).toList();

    final newProgram = program.copyWith(
      id: Value(id),
      sessions: sessions,
    );
    _programs[id] = newProgram;
    return Result.ok(newProgram);
  }

  @override
  Future<Result<ExerciseProgram>> updateProgram(ExerciseProgram program) async {
    if (!_programs.containsKey(program.id)) {
      return Result.error(
          ExerciseNotFoundException('Program ${program.id} not found'));
    }
    // Deep copy/update logic for in-memory is simple replacement

    if (program.isActive) {
      _programs.forEach((key, value) {
        if (key != program.id && value.isActive) {
          _programs[key] = value.copyWith(isActive: false);
        }
      });
    }

    _programs[program.id!] = program;
    return Result.ok(program);
  }

  @override
  Future<Result<ExerciseProgram>> deleteProgram(String id) async {
    if (_programs.containsKey(id)) {
      final program = _programs.remove(id);
      return Result.ok(program!);
    }
    return Result.error(ExerciseNotFoundException('Program $id not found'));
  }
}
