import 'package:exercise_management/core/value.dart';

/// ExerciseSet is an exercise set that was performed.
class ExerciseSet {
  final String? id;
  final String exerciseTemplateId;
  final DateTime dateTime;
  final double equipmentWeight;
  final double platesWeight;
  final int repetitions;
  final DateTime? completedAt;

  ExerciseSet({
    this.id,
    required this.exerciseTemplateId,
    required this.dateTime,
    required this.equipmentWeight,
    required this.platesWeight,
    required this.repetitions,
    this.completedAt,
  });

  double get totalWeight => equipmentWeight + platesWeight;

  ExerciseSet copyWith({
    Value<String?>? id,
    String? exerciseTemplateId,
    DateTime? dateTime,
    double? equipmentWeight,
    double? platesWeight,
    int? repetitions,
    Value<DateTime?>? completedAt,
  }) {
    return ExerciseSet(
      id: id != null ? id.value : this.id,
      exerciseTemplateId: exerciseTemplateId ?? this.exerciseTemplateId,
      dateTime: dateTime ?? this.dateTime,
      equipmentWeight: equipmentWeight ?? this.equipmentWeight,
      platesWeight: platesWeight ?? this.platesWeight,
      repetitions: repetitions ?? this.repetitions,
      completedAt: completedAt != null ? completedAt.value : this.completedAt,
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
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    final equipmentWeight = map['equipment_weight'];
    final platesWeight = map['plates_weight'];
    final repetitions = map['repetitions'];
    final completedAtValue = map['completed_at'];

    return ExerciseSet(
      id: map['id']?.toString(),
      exerciseTemplateId: map['exercise_template_id'].toString(),
      dateTime: DateTime.parse(map['date_time'].toString()),
      equipmentWeight: equipmentWeight is num
          ? equipmentWeight.toDouble()
          : double.parse(equipmentWeight.toString()),
      platesWeight: platesWeight is num
          ? platesWeight.toDouble()
          : double.parse(platesWeight.toString()),
      repetitions:
          repetitions is int ? repetitions : int.parse(repetitions.toString()),
      completedAt: completedAtValue != null
          ? DateTime.parse(completedAtValue.toString())
          : null,
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
        other.repetitions == repetitions &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        exerciseTemplateId.hashCode ^
        dateTime.hashCode ^
        equipmentWeight.hashCode ^
        platesWeight.hashCode ^
        repetitions.hashCode ^
        completedAt.hashCode;
  }
}
