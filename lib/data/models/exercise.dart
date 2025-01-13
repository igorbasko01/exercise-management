import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';

class Exercise {
  final String id;
  final String name;
  final MuscleGroup muscleGroup;
  final RepetitionsRange repetitionsRangeTarget;
  final String? description;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.repetitionsRangeTarget,
    this.description,
  });
}