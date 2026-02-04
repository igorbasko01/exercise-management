import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation_mapper.dart';

class ExerciseSetPresentation {
  final String? setId;
  final String exerciseTemplateId;
  final DateTime dateTime;
  final double equipmentWeight;
  final double platesWeight;
  final int repetitions;
  final String displayName;
  final RepetitionsRange repetitionsRange;
  final DateTime? completedAt;

  ExerciseSetPresentation({
    this.setId,
    required this.exerciseTemplateId,
    required this.dateTime,
    required this.equipmentWeight,
    required this.platesWeight,
    required this.repetitions,
    required this.displayName,
    required this.repetitionsRange,
    this.completedAt,
  });

  double get totalWeight => equipmentWeight + platesWeight;

  ExerciseSetPresentation copyWith({
    Value<String?>? setId,
    String? exerciseTemplateId,
    DateTime? dateTime,
    double? equipmentWeight,
    double? platesWeight,
    int? repetitions,
    String? displayName,
    RepetitionsRange? repetitionsRange,
    Value<DateTime?>? completedAt,
  }) {
    return ExerciseSetPresentation(
      setId: setId != null ? setId.value : this.setId,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      dateTime: dateTime ?? this.dateTime,
      equipmentWeight: equipmentWeight ?? this.equipmentWeight,
      platesWeight: platesWeight ?? this.platesWeight,
      repetitions: repetitions ?? this.repetitions,
      displayName: displayName ?? this.displayName,
      repetitionsRange: repetitionsRange ?? this.repetitionsRange,
      completedAt: completedAt != null ? completedAt.value : this.completedAt,
    );
  }

  ExerciseSet toExerciseSet() {
    return ExerciseSetPresentationMapper.toExerciseSet(this);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseSetPresentation &&
        other.setId == setId &&
        other.exerciseTemplateId == exerciseTemplateId &&
        other.dateTime == dateTime &&
        other.equipmentWeight == equipmentWeight &&
        other.platesWeight == platesWeight &&
        other.repetitions == repetitions &&
        other.displayName == displayName &&
        other.repetitionsRange == repetitionsRange &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return setId.hashCode ^
        exerciseTemplateId.hashCode ^
        dateTime.hashCode ^
        equipmentWeight.hashCode ^
        platesWeight.hashCode ^
        repetitions.hashCode ^
        displayName.hashCode ^
        repetitionsRange.hashCode ^
        completedAt.hashCode;
  }
}
