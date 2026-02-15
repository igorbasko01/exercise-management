import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:flutter/foundation.dart';

class ExerciseProgramsViewModel extends ChangeNotifier {
  final ExerciseProgramRepository _repository;

  ExerciseProgramsViewModel({required ExerciseProgramRepository repository})
      : _repository = repository {
    fetchPrograms = Command0(_fetchPrograms);
    addProgram = Command1(_addProgram);
    updateProgram = Command1(_updateProgram);
    deleteProgram = Command1(_deleteProgram);
    setActiveProgram = Command1(_setActiveProgram);
  }

  late Command0<List<ExerciseProgram>> fetchPrograms;
  late Command1<ExerciseProgram, ExerciseProgram> addProgram;
  late Command1<ExerciseProgram, ExerciseProgram> updateProgram;
  late Command1<ExerciseProgram, String> deleteProgram;
  late Command1<ExerciseProgram, ExerciseProgram> setActiveProgram;

  List<ExerciseProgram> _programs = [];
  List<ExerciseProgram> get programs => _programs;

  ExerciseProgram? get activeProgram {
    try {
      return _programs.firstWhere((p) => p.isActive);
    } catch (_) {
      return null;
    }
  }

  Future<Result<List<ExerciseProgram>>> _fetchPrograms() async {
    final result = await _repository.getPrograms();
    if (result is Ok<List<ExerciseProgram>>) {
      _programs = result.value;
      notifyListeners();
    }
    return result;
  }

  Future<Result<ExerciseProgram>> _addProgram(ExerciseProgram program) async {
    final result = await _repository.addProgram(program);
    if (result is Ok<ExerciseProgram>) {
      await fetchPrograms.execute(); // Refresh list to get updated state
    }
    return result;
  }

  Future<Result<ExerciseProgram>> _updateProgram(ExerciseProgram program) async {
    final result = await _repository.updateProgram(program);
    if (result is Ok<ExerciseProgram>) {
      await fetchPrograms.execute();
    }
    return result;
  }

  Future<Result<ExerciseProgram>> _deleteProgram(String id) async {
    final result = await _repository.deleteProgram(id);
    if (result is Ok<ExerciseProgram>) {
      _programs.removeWhere((p) => p.id == id);
      notifyListeners();
    }
    return result;
  }

  Future<Result<ExerciseProgram>> _setActiveProgram(
      ExerciseProgram program) async {
    if (program.isActive) return Result.ok(program);
    final updatedProgram = program.copyWith(isActive: true);
    return await _updateProgram(updatedProgram);
  }
}
