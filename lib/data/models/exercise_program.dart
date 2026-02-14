import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';

class ExerciseProgram {
  final String? id;
  final String name;
  final String? description;
  final List<ExerciseProgramSession> sessions;
  final bool isActive;

  const ExerciseProgram({
    this.id,
    required this.name,
    this.description,
    required this.sessions,
    this.isActive = false,
  });

  ExerciseProgram copyWith({
    Value<String?>? id,
    String? name,
    Value<String?>? description,
    List<ExerciseProgramSession>? sessions,
    bool? isActive,
  }) {
    return ExerciseProgram(
      id: id != null ? id.value : this.id,
      name: name ?? this.name,
      description: description != null ? description.value : this.description,
      sessions: sessions ?? this.sessions,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory ExerciseProgram.fromMap(Map<String, dynamic> map,
      [List<ExerciseProgramSession>? sessions]) {
    return ExerciseProgram(
      id: map['id']?.toString(),
      name: map['name'],
      description: map['description'],
      sessions: sessions ?? [],
      isActive: (map['is_active'] as int?) == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseProgram &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isActive.hashCode;
  }
}
