import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';

/// This class represents a description of an exercise.
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

  ExerciseTemplate copyWith(
      {String? id,
      String? name,
      MuscleGroup? muscleGroup,
      RepetitionsRange? repetitionsRangeTarget,
      String? description}) {
    return ExerciseTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      repetitionsRangeTarget:
          repetitionsRangeTarget ?? this.repetitionsRangeTarget,
      description: description ?? this.description,
    );
  }

  ExerciseTemplate copyWithoutId(
      {String? name,
      MuscleGroup? muscleGroup,
      RepetitionsRange? repetitionsRangeTarget,
      String? description}) {
    return ExerciseTemplate(
      id: null,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      repetitionsRangeTarget:
          repetitionsRangeTarget ?? this.repetitionsRangeTarget,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseTemplate &&
        other.id == id &&
        other.name == name &&
        other.muscleGroup == muscleGroup &&
        other.repetitionsRangeTarget == repetitionsRangeTarget &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        muscleGroup.hashCode ^
        repetitionsRangeTarget.hashCode ^
        description.hashCode;
  }
}
