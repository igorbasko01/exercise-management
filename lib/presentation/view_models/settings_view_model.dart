import 'dart:io';

import 'package:archive/archive.dart';
import 'package:exercise_management/core/csv_serializer.dart';
import 'package:path/path.dart' as path;
import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_program_session.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required ExerciseTemplateRepository templatesRepository,
    required ExerciseSetRepository setsRepository,
    required ExerciseProgramRepository programsRepository,
  })  : _templatesRepository = templatesRepository,
        _setsRepository = setsRepository,
        _programsRepository = programsRepository {
    exportDataCommand = Command0(_exportAndStoreData)
      ..addListener(_onCommandExecuted);
    importDataCommand = Command1(_importData)..addListener(_onCommandExecuted);
  }

  final ExerciseTemplateRepository _templatesRepository;
  final ExerciseSetRepository _setsRepository;
  final ExerciseProgramRepository _programsRepository;

  final String _templatesFileNamePrefix = 'exercise_templates';
  final String _setsFileNamePrefix = 'exercise_sets';
  final String _programsFileNamePrefix = 'exercise_programs';
  final String _programSessionsFileNamePrefix = 'exercise_program_sessions';
  final String _sessionExercisesFileNamePrefix = 'session_exercises';

  late final Command0<String> exportDataCommand;
  late final Command1<void, String> importDataCommand;

  void _onCommandExecuted() {
    notifyListeners();
  }

  Future<Result<String>> _exportAndStoreData() async {
    try {
      final exportResult = await _exportData();
      if (exportResult is Error) {
        return exportResult;
      }

      final tempFilePath = (exportResult as Ok).value;

      final storeResult = await _storeInDownloads(tempFilePath);
      return storeResult;
    } catch (e) {
      return Result.error(ExportException(e.toString()));
    }
  }

  Future<Result<String>> _exportData() async {
    final templatesResult = await _templatesRepository.getExercises();
    final setsResult = await _setsRepository.getExercises();
    final programsResult = await _programsRepository.getPrograms();

    if (templatesResult is Error) {
      return Result.error((templatesResult as Error).error);
    }

    if (setsResult is Error) {
      return Result.error((setsResult as Error).error);
    }

    if (programsResult is Error) {
      return Result.error((programsResult as Error).error);
    }

    final templates = (templatesResult as Ok).value;
    final sets = (setsResult as Ok).value;
    final programs = (programsResult as Ok).value as List<ExerciseProgram>;

    final templatesCSV = _createTemplatesCSV(templates);
    final setsCSV = _createSetsCSV(sets);
    final programsCSV = _createProgramsCSV(programs);
    final sessionsCSV = _createProgramSessionsCSV(programs);
    final sessionExercisesCSV = _createSessionExercisesCSV(programs);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat("yyyyMMddHHmmss").format(DateTime.now());

    final templatesFile =
        File('${tempDir.path}/${_templatesFileNamePrefix}_$timestamp.csv');
    final setsFile =
        File('${tempDir.path}/${_setsFileNamePrefix}_$timestamp.csv');
    final programsFile =
        File('${tempDir.path}/${_programsFileNamePrefix}_$timestamp.csv');
    final sessionsFile =
        File('${tempDir.path}/${_programSessionsFileNamePrefix}_$timestamp.csv');
    final sessionExercisesFile =
        File('${tempDir.path}/${_sessionExercisesFileNamePrefix}_$timestamp.csv');

    await templatesFile.writeAsString(templatesCSV);
    await setsFile.writeAsString(setsCSV);
    await programsFile.writeAsString(programsCSV);
    await sessionsFile.writeAsString(sessionsCSV);
    await sessionExercisesFile.writeAsString(sessionExercisesCSV);

    final archive = Archive();
    archive.addFile(ArchiveFile('$_templatesFileNamePrefix.csv',
        templatesFile.lengthSync(), templatesFile.readAsBytesSync()));
    archive.addFile(ArchiveFile('$_setsFileNamePrefix.csv',
        setsFile.lengthSync(), setsFile.readAsBytesSync()));
    archive.addFile(ArchiveFile('$_programsFileNamePrefix.csv',
        programsFile.lengthSync(), programsFile.readAsBytesSync()));
    archive.addFile(ArchiveFile('$_programSessionsFileNamePrefix.csv',
        sessionsFile.lengthSync(), sessionsFile.readAsBytesSync()));
    archive.addFile(ArchiveFile('$_sessionExercisesFileNamePrefix.csv',
        sessionExercisesFile.lengthSync(),
        sessionExercisesFile.readAsBytesSync()));

    final zipFile = File('${tempDir.path}/exercise_data_export_$timestamp.zip');
    await zipFile.writeAsBytes(ZipEncoder().encode(archive));

    await templatesFile.delete();
    await setsFile.delete();
    await programsFile.delete();
    await sessionsFile.delete();
    await sessionExercisesFile.delete();

    return Result.ok(zipFile.path);
  }

  Future<Result<String>> _storeInDownloads(String filePath) async {
    try {
      final downloadsDir = await _getDownloadsDirectory();
      final fileName = path.basename(filePath);
      final downloadPath = path.join(downloadsDir.path, fileName);

      final originalFile = File(filePath);
      await originalFile.copy(downloadPath);

      return Result.ok(downloadPath);
    } catch (e) {
      return Result.error(ExportException('Error saving file: $e'));
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      return await getApplicationDocumentsDirectory();
    } else {
      return await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
  }

  Future<Result<void>> _importData(String filePath) async {
    // check if zip file exists
    final zipFile = File(filePath);
    if (!await zipFile.exists()) {
      return Result.error(ImportException('File not found: $filePath'));
    }

    try {
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      List<ExerciseTemplate> templates = [];
      List<ExerciseSet> sets = [];
      List<ExerciseProgram> programs = [];
      List<ExerciseProgramSession> sessions = [];
      List<Map<String, dynamic>> sessionExerciseLinks = [];

      for (final file in archive) {
        if (file.isFile) {
          final content = String.fromCharCodes(file.content as List<int>);
          if (file.name == '$_templatesFileNamePrefix.csv') {
            templates = _parseTemplatesCSV(content);
          } else if (file.name == '$_setsFileNamePrefix.csv') {
            sets = _parseSetsCSV(content);
          } else if (file.name == '$_programsFileNamePrefix.csv') {
            programs = _parseProgramsCSV(content);
          } else if (file.name == '$_programSessionsFileNamePrefix.csv') {
            sessions = _parseProgramSessionsCSV(content);
          } else if (file.name == '$_sessionExercisesFileNamePrefix.csv') {
            sessionExerciseLinks = _parseSessionExercisesCSV(content);
          }
        }
      }

      if (templates.isEmpty) {
        return Result.error(
            ImportException('No templates found in the zip file.'));
      }

      // Build a template lookup map for session exercise reconstruction
      final templateMap = {for (var t in templates) t.id: t};

      // Reconstruct full program hierarchy from flat CSV data
      final fullPrograms =
          _reconstructPrograms(programs, sessions, sessionExerciseLinks, templateMap);

      // Clear existing data (order matters for foreign key constraints)
      final clearProgramsResult = await _programsRepository.clearAll();
      if (clearProgramsResult is Error) {
        return clearProgramsResult;
      }
      final clearSetsResult = await _setsRepository.clearAll();
      if (clearSetsResult is Error) {
        return clearSetsResult;
      }
      final clearTemplatesResult = await _templatesRepository.clearAll();
      if (clearTemplatesResult is Error) {
        return clearTemplatesResult;
      }

      for (final template in templates) {
        final result = await _templatesRepository.addExercise(template);
        if (result is Error) {
          return Result.error((result as Error).error);
        }
      }

      for (final set in sets) {
        final result = await _setsRepository.addExercise(set);
        if (result is Error) {
          return Result.error((result as Error).error);
        }
      }

      for (final program in fullPrograms) {
        final result = await _programsRepository.addProgram(program);
        if (result is Error) {
          return Result.error((result as Error).error);
        }
      }

      return Result.ok(null);
    } catch (e) {
      return Result.error(ImportException('Error importing data: $e'));
    }
  }

  String _createTemplatesCSV(List<ExerciseTemplate> templates) {
    return CsvSerializer.toCSV(templates.map((t) => t.toMap()).toList());
  }

  String _createSetsCSV(List<ExerciseSet> sets) {
    return CsvSerializer.toCSV(sets.map((s) => s.toMap()).toList());
  }

  String _createProgramsCSV(List<ExerciseProgram> programs) {
    return CsvSerializer.toCSV(programs.map((p) => p.toMap()).toList());
  }

  String _createProgramSessionsCSV(List<ExerciseProgram> programs) {
    final sessionMaps = <Map<String, dynamic>>[];
    for (final program in programs) {
      for (final session in program.sessions) {
        sessionMaps.add(session.toMap());
      }
    }
    return CsvSerializer.toCSV(sessionMaps);
  }

  String _createSessionExercisesCSV(List<ExerciseProgram> programs) {
    final linkMaps = <Map<String, dynamic>>[];
    for (final program in programs) {
      for (final session in program.sessions) {
        for (int i = 0; i < session.exercises.length; i++) {
          linkMaps.add({
            'session_id': session.id,
            'exercise_template_id': session.exercises[i].id,
            'ordering': i,
          });
        }
      }
    }
    return CsvSerializer.toCSV(linkMaps);
  }

  List<ExerciseTemplate> _parseTemplatesCSV(String csvContent) {
    return CsvSerializer.fromCSV(csvContent)
        .map((map) => ExerciseTemplate.fromMap(map))
        .toList();
  }

  List<ExerciseSet> _parseSetsCSV(String csvContent) {
    return CsvSerializer.fromCSV(csvContent)
        .map((map) => ExerciseSet.fromMap(map))
        .toList();
  }

  List<ExerciseProgram> _parseProgramsCSV(String csvContent) {
    return CsvSerializer.fromCSV(csvContent)
        .map((map) => ExerciseProgram.fromMap(map))
        .toList();
  }

  List<ExerciseProgramSession> _parseProgramSessionsCSV(String csvContent) {
    return CsvSerializer.fromCSV(csvContent)
        .map((map) => ExerciseProgramSession.fromMap(map, []))
        .toList();
  }

  List<Map<String, dynamic>> _parseSessionExercisesCSV(String csvContent) {
    return CsvSerializer.fromCSV(csvContent);
  }

  List<ExerciseProgram> _reconstructPrograms(
    List<ExerciseProgram> programs,
    List<ExerciseProgramSession> sessions,
    List<Map<String, dynamic>> sessionExerciseLinks,
    Map<String?, ExerciseTemplate> templateMap,
  ) {
    // Group session exercise links by session_id
    final linksPerSession = <String, List<Map<String, dynamic>>>{};
    for (final link in sessionExerciseLinks) {
      final sessionId = link['session_id']?.toString() ?? '';
      linksPerSession.putIfAbsent(sessionId, () => []).add(link);
    }

    // Sort each group by ordering
    for (final links in linksPerSession.values) {
      links.sort((a, b) {
        final aOrder = a['ordering'];
        final bOrder = b['ordering'];
        final aInt = aOrder is int ? aOrder : int.tryParse(aOrder.toString()) ?? 0;
        final bInt = bOrder is int ? bOrder : int.tryParse(bOrder.toString()) ?? 0;
        return aInt.compareTo(bInt);
      });
    }

    // Build sessions with exercises
    final sessionsPerProgram = <String, List<ExerciseProgramSession>>{};
    for (final session in sessions) {
      final programId = session.programId ?? '';
      final sessionId = session.id ?? '';
      final links = linksPerSession[sessionId] ?? [];
      final exercises = links
          .map((link) => templateMap[link['exercise_template_id']?.toString()])
          .whereType<ExerciseTemplate>()
          .toList();
      final fullSession = ExerciseProgramSession(
        id: session.id,
        programId: session.programId,
        name: session.name,
        description: session.description,
        exercises: exercises,
      );
      sessionsPerProgram.putIfAbsent(programId, () => []).add(fullSession);
    }

    // Build programs with sessions
    return programs.map((program) {
      final programId = program.id ?? '';
      return program.copyWith(
        sessions: sessionsPerProgram[programId] ?? [],
      );
    }).toList();
  }
}

class ExportException implements BaseException {
  @override
  final String message;

  ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}

class ImportException implements BaseException {
  @override
  final String message;

  ImportException(this.message);

  @override
  String toString() => 'ImportException: $message';
}
