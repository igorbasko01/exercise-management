class ExerciseSetPresentation {
  final String? setId;
  final String exerciseTemplateId;
  final DateTime dateTime;
  final double equipmentWeight;
  final double platesWeight;
  final int repetitions;
  final String displayName;

  ExerciseSetPresentation({
    this.setId,
    required this.exerciseTemplateId,
    required this.dateTime,
    required this.equipmentWeight,
    required this.platesWeight,
    required this.repetitions,
    required this.displayName,
  });

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
        other.displayName == displayName;
  }

  @override
  int get hashCode {
    return setId.hashCode ^
        exerciseTemplateId.hashCode ^
        dateTime.hashCode ^
        equipmentWeight.hashCode ^
        platesWeight.hashCode ^
        repetitions.hashCode ^
        displayName.hashCode;
  }
}
