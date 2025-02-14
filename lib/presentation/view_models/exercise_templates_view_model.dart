import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/service/exercise_template_service.dart';
import 'package:flutter/material.dart';

class ExerciseTemplatesViewModel extends ChangeNotifier {
  final ExerciseTemplateService _exerciseTemplateService;
  List<ExerciseTemplate> _exerciseTemplates = [];
  bool _isLoading = false;
  String? _errorMessage;

  ExerciseTemplatesViewModel(this._exerciseTemplateService);

  List<ExerciseTemplate> get exerciseTemplates => _exerciseTemplates;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchExerciseTemplates() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _exerciseTemplateService.getExerciseTemplates();

    result.unpack(
      onSuccess: (exerciseTemplates) {
        _exerciseTemplates = exerciseTemplates;
        _isLoading = false;
      },
      onFailure: (error) {
        _errorMessage = error.message;
      },
    );

    notifyListeners();
  }
}