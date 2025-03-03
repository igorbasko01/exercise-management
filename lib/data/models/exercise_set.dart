class ExerciseSet {
  final String? id;
  final String exerciseTemplateId;
  final DateTime dateTime;
  final double equipmentWeight;
  final double platesWeight;
  final int repetitions;

  ExerciseSet({
    this.id,
    required this.exerciseTemplateId,
    required this.dateTime,
    required this.equipmentWeight,
    required this.platesWeight,
    required this.repetitions,
  });

  ExerciseSet copyWith({
    String? id,
    String? exerciseTemplateId,
    DateTime? dateTime,
    double? equipmentWeight,
    double? platesWeight,
    int? repetitions,
  }) {
    return ExerciseSet(
      id: id ?? this.id,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      dateTime: dateTime ?? this.dateTime,
      equipmentWeight: equipmentWeight ?? this.equipmentWeight,
      platesWeight: platesWeight ?? this.platesWeight,
      repetitions: repetitions ?? this.repetitions,
    );
  }

  ExerciseSet copyWithoutId({
    String? exerciseTemplateId,
    DateTime? dateTime,
    double? equipmentWeight,
    double? platesWeight,
    int? repetitions,
  }) {
    return ExerciseSet(
      id: null,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      dateTime: dateTime ?? this.dateTime,
      equipmentWeight: equipmentWeight ?? this.equipmentWeight,
      platesWeight: platesWeight ?? this.platesWeight,
      repetitions: repetitions ?? this.repetitions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseSet &&
        other.id == id &&
        other.exerciseTemplateId == exerciseTemplateId &&
        other.dateTime == dateTime &&
        other.equipmentWeight == equipmentWeight &&
        other.platesWeight == platesWeight &&
        other.repetitions == repetitions;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        exerciseTemplateId.hashCode ^
        dateTime.hashCode ^
        equipmentWeight.hashCode ^
        platesWeight.hashCode ^
        repetitions.hashCode;
  }
}