import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_template.dart';

class ExerciseProgramSession {
  final String? id;
  final String? programId;
  final String name;
  final String? description;
  final List<ExerciseTemplate> exercises;

  ExerciseProgramSession({
    this.id,
    this.programId,
    required this.name,
    this.description,
    this.exercises = const [],
  });

  ExerciseProgramSession copyWith({
    Value<String?>? id,
    Value<String?>? programId,
    String? name,
    String? description,
    List<ExerciseTemplate>? exercises,
  }) {
    return ExerciseProgramSession(
      id: id != null ? id.value : this.id,
      programId: programId != null ? programId.value : this.programId,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'program_id': programId,
      'name': name,
      'description': description,
    };
  }

  factory ExerciseProgramSession.fromMap(
      Map<String, dynamic> map, List<ExerciseTemplate> exercises) {
    return ExerciseProgramSession(
      id: map['id']?.toString(),
      programId: map['program_id']?.toString(),
      name: map['name'],
      description: map['description'],
      exercises: exercises,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseProgramSession &&
        other.id == id &&
        other.programId == programId &&
        other.name == name &&
        other.description == description;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        programId.hashCode ^
        name.hashCode ^
        description.hashCode;
  }
}
