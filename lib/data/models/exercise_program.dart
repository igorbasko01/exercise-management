import 'package:exercise_management/core/enums/progression_type.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';

class ExerciseProgram {
  final String? id;
  final String name;
  final String? description;
  final List<ExerciseProgramSession> sessions;
  final bool isActive;
  final ProgressionType progressionType;

  const ExerciseProgram({
    this.id,
    required this.name,
    this.description,
    required this.sessions,
    this.isActive = false,
    this.progressionType = ProgressionType.standard,
  });

  ExerciseProgram copyWith({
    Value<String?>? id,
    String? name,
    Value<String?>? description,
    List<ExerciseProgramSession>? sessions,
    bool? isActive,
    ProgressionType? progressionType,
  }) {
    return ExerciseProgram(
      id: id != null ? id.value : this.id,
      name: name ?? this.name,
      description: description != null ? description.value : this.description,
      sessions: sessions ?? this.sessions,
      isActive: isActive ?? this.isActive,
      progressionType: progressionType ?? this.progressionType,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'is_active': isActive ? 1 : 0,
      'progression_type': progressionType.index,
    };
  }

  factory ExerciseProgram.fromMap(Map<String, dynamic> map,
      [List<ExerciseProgramSession>? sessions]) {
    final isActiveValue = map['is_active'];
    final progressionTypeValue = map['progression_type'];
    return ExerciseProgram(
      id: map['id']?.toString(),
      name: map['name'],
      description: map['description'],
      sessions: sessions ?? [],
      isActive: isActiveValue is int
          ? isActiveValue == 1
          : int.tryParse(isActiveValue?.toString() ?? '0') == 1,
      progressionType: ProgressionType.values[progressionTypeValue is int
          ? progressionTypeValue
          : int.tryParse(progressionTypeValue?.toString() ?? '0') ?? 0],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ExerciseProgram &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.isActive == isActive &&
        other.progressionType == progressionType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        isActive.hashCode ^
        progressionType.hashCode;
  }
}
