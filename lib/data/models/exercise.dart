import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';

class ExerciseTemplate {
  final String? id;
  final String name;
  final MuscleGroup muscleGroup;
  final RepetitionsRange repetitionsRangeTarget;
  final String? description;

  ExerciseTemplate({
    this.id,
    required this.name,
    required this.muscleGroup,
    required this.repetitionsRangeTarget,
    this.description,
  });

  ExerciseTemplate copyWith({required String id}) {
    return ExerciseTemplate(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      repetitionsRangeTarget: repetitionsRangeTarget,
      description: description,
    );
  }
}