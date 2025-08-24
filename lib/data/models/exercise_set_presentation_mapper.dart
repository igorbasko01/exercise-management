import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_set_presentation.dart';
import 'package:exercise_management/data/models/exercise_template.dart';

class ExerciseSetPresentationMapper {
  static ExerciseSetPresentation from(
      ExerciseSet set, ExerciseTemplate template) {
    return ExerciseSetPresentation(
      setId: set.id,
      displayName: template.name,
      repetitions: set.repetitions,
      platesWeight: set.platesWeight,
      equipmentWeight: set.equipmentWeight,
      dateTime: set.dateTime,
      exerciseTemplateId: set.exerciseTemplateId,
      repetitionsRange: template.repetitionsRangeTarget,
    );
  }

  static ExerciseSetPresentation fromMap(Map<String, dynamic> map) {
    return ExerciseSetPresentation(
      setId: (map['id'] as int).toString(),
      exerciseTemplateId: (map['exercise_template_id'] as int).toString(),
      dateTime: DateTime.parse(map['date_time'] as String),
      equipmentWeight: (map['equipment_weight'] as num).toDouble(),
      platesWeight: (map['plates_weight'] as num).toDouble(),
      repetitions: map['repetitions'] as int,
      displayName: map['display_name'] as String,
      repetitionsRange: RepetitionsRange.values.firstWhere(
          (e) => e.index == map['repetitions_range'],
          orElse: () => RepetitionsRange.medium),
    );
  }

  static ExerciseSet toExerciseSet(ExerciseSetPresentation presentation) {
    return ExerciseSet(
      id: presentation.setId,
      exerciseTemplateId: presentation.exerciseTemplateId,
      dateTime: presentation.dateTime,
      equipmentWeight: presentation.equipmentWeight,
      platesWeight: presentation.platesWeight,
      repetitions: presentation.repetitions,
    );
  }
}
