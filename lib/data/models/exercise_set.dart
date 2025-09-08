/// ExerciseSet is an exercise set that was performed.
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

  double get totalWeight => equipmentWeight + platesWeight;

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exercise_template_id': exerciseTemplateId,
      'date_time': dateTime.toIso8601String(),
      'equipment_weight': equipmentWeight,
      'plates_weight': platesWeight,
      'repetitions': repetitions,
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      id: map['id']?.toString(),
      exerciseTemplateId: map['exercise_template_id'].toString(),
      dateTime: DateTime.parse(map['date_time'] as String),
      equipmentWeight: (map['equipment_weight'] as num).toDouble(),
      platesWeight: (map['plates_weight'] as num).toDouble(),
      repetitions: map['repetitions'] as int,
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
