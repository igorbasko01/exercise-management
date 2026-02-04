import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/value.dart';

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
      {Value<String?>? id,
      String? name,
      MuscleGroup? muscleGroup,
      RepetitionsRange? repetitionsRangeTarget,
      String? description}) {
    return ExerciseTemplate(
      id: id != null ? id.value : this.id,
      name: name ?? this.name,
      muscleGroup: muscleGroup ?? this.muscleGroup,
      repetitionsRangeTarget:
          repetitionsRangeTarget ?? this.repetitionsRangeTarget,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'muscle_group': muscleGroup.index,
      'repetitions_range': repetitionsRangeTarget.index,
      'description': description,
    };
  }

  factory ExerciseTemplate.fromMap(Map<String, dynamic> map) {
    final muscleGroupValue = map['muscle_group'];
    final repetitionsRangeValue = map['repetitions_range'];

    return ExerciseTemplate(
      id: map['id']?.toString(),
      name: map['name'].toString(),
      muscleGroup: MuscleGroup.values[muscleGroupValue is int
          ? muscleGroupValue
          : int.parse(muscleGroupValue.toString())],
      repetitionsRangeTarget: RepetitionsRange.values[
          repetitionsRangeValue is int
              ? repetitionsRangeValue
              : int.parse(repetitionsRangeValue.toString())],
      description: map['description']?.toString(),
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
