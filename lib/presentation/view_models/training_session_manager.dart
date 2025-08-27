import 'package:flutter/material.dart';

class TrainingSessionManager extends ChangeNotifier {
  final Set<String> _completedSetIds = {};

  Set<String> get completedSetIds => Set.from(_completedSetIds);

  bool isSetCompleted(String setId) => _completedSetIds.contains(setId);

  void toggleSetCompletion(String setId) {
    if (_completedSetIds.contains(setId)) {
      _completedSetIds.remove(setId);
    } else {
      _completedSetIds.add(setId);
    }
    notifyListeners();
  }
}