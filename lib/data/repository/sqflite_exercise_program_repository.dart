import 'dart:async';
import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteExerciseProgramRepository implements ExerciseProgramRepository {
  final Database database;
  static const String programTable = 'exercise_programs';
  static const String sessionTable = 'exercise_program_sessions';
  static const String linkTable = 'session_exercises';
  static const String exerciseTable = 'exercise_templates';

  SqfliteExerciseProgramRepository(this.database);

  final _updates = StreamController<void>.broadcast();

  @override
  Stream<Result<List<ExerciseProgram>>> watchPrograms() async* {
    yield await getPrograms();
    await for (final _ in _updates.stream) {
      yield await getPrograms();
    }
  }

  void _notifyProgramsChanged() {
    _updates.add(null);
  }

  @override
  Future<Result<List<ExerciseProgram>>> getPrograms() async {
    try {
      final List<Map<String, dynamic>> programMaps =
          await database.query(programTable, where: 'deleted_at IS NULL');

      List<ExerciseProgram> programs = [];
      for (var map in programMaps) {
        final programId = map['id'].toString();
        // For list view, we might not need all sessions/exercises loaded immediately,
        // but let's load them for completeness as per current simple architecture.
        // Optimization: Could be lazy loaded or just load session count.
        // For now, let's load full structure.
        final sessionsResult = await _getSessionsForProgram(programId);
        programs.add(ExerciseProgram.fromMap(map, sessionsResult));
      }
      return Result.ok(programs);
    } catch (e) {
      return Result.error(
          ExerciseDatabaseException("Failed to fetch programs: $e"));
    }
  }

  @override
  Future<Result<ExerciseProgram>> getProgram(String id) async {
    try {
      final List<Map<String, dynamic>> maps = await database.query(
        programTable,
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );

      if (maps.isEmpty) {
        return Result.error(ExerciseNotFoundException('Program $id not found'));
      }

      final sessions = await _getSessionsForProgram(id);
      return Result.ok(ExerciseProgram.fromMap(maps.first, sessions));
    } catch (e) {
      if (e is BaseException) return Result.error(e);
      return Result.error(
          ExerciseDatabaseException("Failed to fetch program: $e"));
    }
  }

  Future<List<ExerciseProgramSession>> _getSessionsForProgram(
      String programId) async {
    final List<Map<String, dynamic>> sessionMaps = await database.query(
      sessionTable,
      where: 'program_id = ? AND deleted_at IS NULL',
      whereArgs: [programId],
      orderBy:
          'id', // Assuming insertion order or id order corresponds to creation
    );

    List<ExerciseProgramSession> sessions = [];
    for (var map in sessionMaps) {
      final sessionId = map['id'].toString();
      final exercises = await _getExercisesForSession(sessionId);
      sessions.add(ExerciseProgramSession.fromMap(map, exercises));
    }
    return sessions;
  }

  Future<List<ExerciseTemplate>> _getExercisesForSession(
      String sessionId) async {
    // Join query to get exercises in order
    final List<Map<String, dynamic>> result = await database.rawQuery('''
      SELECT e.* 
      FROM $exerciseTable e
      INNER JOIN $linkTable l ON e.id = l.exercise_template_id
      WHERE l.session_id = ? AND l.deleted_at IS NULL AND e.deleted_at IS NULL
      ORDER BY l.ordering
    ''', [sessionId]);

    return result.map((e) => ExerciseTemplate.fromMap(e)).toList();
  }

  @override
  Future<Result<ExerciseProgram>> addProgram(ExerciseProgram program) async {
    return await database
        .transaction((txn) async {
          try {
            // If new program is active, deactivate others
            if (program.isActive) {
              await txn.rawUpdate(
                  'UPDATE $programTable SET is_active = 0 WHERE is_active = 1');
            }

            // Insert Program
            final programMap = program.toMap();
            final String programIdStr = program.id ?? DateTime.now().millisecondsSinceEpoch.toString() + 'temp';
            programMap['id'] = programIdStr;
            programMap['sync_status'] = 'pending_insert';
            programMap['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

            await txn.insert(programTable, programMap);

            List<ExerciseProgramSession> savedSessions = [];

            for (var session in program.sessions) {
              // Insert Session
              final sessionMap = session.toMap();
              final String sessionIdStr = session.id ?? DateTime.now().millisecondsSinceEpoch.toString() + 'temp' + session.hashCode.toString();
              sessionMap['id'] = sessionIdStr;
              sessionMap['program_id'] = programIdStr;
              sessionMap['sync_status'] = 'pending_insert';
              sessionMap['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

              await txn.insert(sessionTable, sessionMap);

              // Insert Link/Exercises
              int order = 0;
              for (var exercise in session.exercises) {
                await txn.insert(linkTable, {
                  'session_id': sessionIdStr,
                  'exercise_template_id': exercise.id,
                  'ordering': order++,
                  'sync_status': 'pending_insert',
                  'last_updated_at': DateTime.now().toUtc().toIso8601String()
                });
              }

              savedSessions.add(session.copyWith(
                id: Value(sessionIdStr),
                programId: Value(programIdStr),
              ));
            }

            return Result.ok(program.copyWith(
              id: Value(programIdStr),
              sessions: savedSessions,
            ));
          } catch (e) {
            throw ExerciseDatabaseException("Failed to add program: $e");
          }
        })
        .then((value) => value)
        .catchError((e) {
          if (e is BaseException) return Result<ExerciseProgram>.error(e);
          return Result<ExerciseProgram>.error(
              ExerciseDatabaseException(e.toString()));
        });
  }

  @override
  Future<Result<ExerciseProgram>> updateProgram(ExerciseProgram program) async {
    return await database
        .transaction((txn) async {
          try {
            // If updated program is active, deactivate others
            if (program.isActive) {
              await txn.rawUpdate(
                  'UPDATE $programTable SET is_active = 0 WHERE is_active = 1');
            }

            // Update Program details
            final programMap = program.toMap();
            programMap['sync_status'] = 'pending_update';
            programMap['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

            int count = await txn.update(
              programTable,
              programMap,
              where: 'id = ?',
              whereArgs: [program.id],
            );

            if (count == 0) {
              throw ExerciseNotFoundException(
                  'Program ${program.id} not found');
            }

            // Soft Delete old sessions and links
            await txn.update(
              sessionTable,
              {
                'deleted_at': DateTime.now().toUtc().toIso8601String(),
                'sync_status': 'pending_delete',
                'last_updated_at': DateTime.now().toUtc().toIso8601String()
              },
              where: 'program_id = ?',
              whereArgs: [program.id],
            );

            await txn.rawUpdate('''
              UPDATE $linkTable
              SET deleted_at = ?, sync_status = 'pending_delete', last_updated_at = ?
              WHERE session_id IN (SELECT id FROM $sessionTable WHERE program_id = ?)
            ''', [DateTime.now().toUtc().toIso8601String(), DateTime.now().toUtc().toIso8601String(), program.id]);

            // Re-insert sessions (treating as new inserts)
            List<ExerciseProgramSession> savedSessions = [];
            for (var session in program.sessions) {
              final sessionMap = session.toMap();
              final sessionIdStr = DateTime.now().millisecondsSinceEpoch.toString() + 'temp' + session.hashCode.toString();
              sessionMap['id'] = sessionIdStr;
              sessionMap['program_id'] = program.id;
              sessionMap['sync_status'] = 'pending_insert';
              sessionMap['last_updated_at'] = DateTime.now().toUtc().toIso8601String();

              await txn.insert(sessionTable, sessionMap);

              int order = 0;
              for (var exercise in session.exercises) {
                await txn.insert(linkTable, {
                  'session_id': sessionIdStr,
                  'exercise_template_id': exercise.id,
                  'ordering': order++,
                  'sync_status': 'pending_insert',
                  'last_updated_at': DateTime.now().toUtc().toIso8601String()
                });
              }
              savedSessions.add(session.copyWith(
                id: Value(sessionIdStr),
                programId: Value(program.id),
              ));
            }
            
            _notifyProgramsChanged();

            return Result.ok(program.copyWith(sessions: savedSessions));
          } catch (e) {
            if (e is BaseException) rethrow;
            throw ExerciseDatabaseException("Failed to update program: $e");
          }
        })
        .then((value) => value)
        .catchError((e) {
          if (e is BaseException) return Result<ExerciseProgram>.error(e);
          return Result<ExerciseProgram>.error(
              ExerciseDatabaseException(e.toString()));
        });
  }

  @override
  Future<Result<void>> clearAll() async {
    try {
      await database.delete(linkTable);
      await database.delete(sessionTable);
      await database.delete(programTable);
      _notifyProgramsChanged();
      return Result.ok(null);
    } catch (e) {
      return Result.error(
          ExerciseDatabaseException("Failed to clear programs: $e"));
    }
  }

  @override
  Future<Result<ExerciseProgram>> deleteProgram(String id) async {
    try {
      // Fetch before delete to return
      final result = await getProgram(id);
      if (result is Error) return result;
      final program = (result as Ok<ExerciseProgram>).value;

      final now = DateTime.now().toUtc().toIso8601String();

      await database.update(
        programTable,
        {
          'deleted_at': now,
          'sync_status': 'pending_delete',
          'last_updated_at': now
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      await database.update(
        sessionTable,
        {
          'deleted_at': now,
          'sync_status': 'pending_delete',
          'last_updated_at': now
        },
        where: 'program_id = ?',
        whereArgs: [id],
      );

      await database.rawUpdate('''
        UPDATE $linkTable
        SET deleted_at = ?, sync_status = 'pending_delete', last_updated_at = ?
        WHERE session_id IN (SELECT id FROM $sessionTable WHERE program_id = ?)
      ''', [now, now, id]);

      _notifyProgramsChanged();

      return Result.ok(program);
    } catch (e) {
      return Result.error(ExerciseNotFoundException('Program $id not found'));
    }
  }
}
