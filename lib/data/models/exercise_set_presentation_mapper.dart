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
    );
  }
}
