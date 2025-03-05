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
}