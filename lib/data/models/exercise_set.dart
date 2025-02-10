class ExerciseSet {
  final String id;
  final String exerciseTemplateId;
  final DateTime dateTime;
  final double equipmentWeight;
  final double platesWeight;
  final int repetitions;

  ExerciseSet({
    required this.id,
    required this.exerciseTemplateId,
    required this.dateTime,
    required this.equipmentWeight,
    required this.platesWeight,
    required this.repetitions,
  });
}