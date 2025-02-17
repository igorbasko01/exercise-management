import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:flutter/material.dart';

class ExerciseTemplatesViewModel extends ChangeNotifier {
  final ExerciseTemplateRepository _exerciseTemplateRepository;
  List<ExerciseTemplate> _exerciseTemplates = [];
  bool _isLoading = false;
  String? _errorMessage;

  ExerciseTemplatesViewModel(this._exerciseTemplateRepository);

  List<ExerciseTemplate> get exerciseTemplates => _exerciseTemplates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchExerciseTemplates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _exerciseTemplateRepository.getExercises();

    switch (result) {
      case Ok():
        _exerciseTemplates = result.value;
        _isLoading = false;
        break;
      case Error():
        _errorMessage = result.error.message;
        break;
    }
    notifyListeners();
  }
}