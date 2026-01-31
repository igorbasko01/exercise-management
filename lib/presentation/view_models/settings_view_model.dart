import 'dart:io';

import 'package:archive/archive.dart';
import 'package:exercise_management/core/csv_serializer.dart';
import 'package:path/path.dart' as path;
import 'package:exercise_management/core/base_exception.dart';
import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required ExerciseTemplateRepository templatesRepository,
    required ExerciseSetRepository setsRepository,
  })  : _templatesRepository = templatesRepository,
        _setsRepository = setsRepository {
    exportDataCommand = Command0(_exportAndStoreData)
      ..addListener(_onCommandExecuted);
    importDataCommand = Command1(_importData)..addListener(_onCommandExecuted);
  }

  final ExerciseTemplateRepository _templatesRepository;
  final ExerciseSetRepository _setsRepository;

  final String _templatesFileNamePrefix = 'exercise_templates';
  final String _setsFileNamePrefix = 'exercise_sets';

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

    if (templatesResult is Error) {
      return Result.error((templatesResult as Error).error);
    }

    if (setsResult is Error) {
      return Result.error((setsResult as Error).error);
    }

    final templates = (templatesResult as Ok).value;
    final sets = (setsResult as Ok).value;

    final templatesCSV = _createTemplatesCSV(templates);
    final setsCSV = _createSetsCSV(sets);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat("yyyyMMddHHmmss").format(DateTime.now());

    final templatesFile =
        File('${tempDir.path}/${_templatesFileNamePrefix}_$timestamp.csv');
    final setsFile =
        File('${tempDir.path}/${_setsFileNamePrefix}_$timestamp.csv');

    await templatesFile.writeAsString(templatesCSV);
    await setsFile.writeAsString(setsCSV);

    final archive = Archive();
    archive.addFile(ArchiveFile('$_templatesFileNamePrefix.csv',
        templatesFile.lengthSync(), templatesFile.readAsBytesSync()));
    archive.addFile(ArchiveFile('$_setsFileNamePrefix.csv',
        setsFile.lengthSync(), setsFile.readAsBytesSync()));

    final zipFile = File('${tempDir.path}/exercise_data_export_$timestamp.zip');
    await zipFile.writeAsBytes(ZipEncoder().encode(archive));

    await templatesFile.delete();
    await setsFile.delete();

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

      for (final file in archive) {
        if (file.isFile) {
          final content = String.fromCharCodes(file.content as List<int>);
          if (file.name == '$_templatesFileNamePrefix.csv') {
            templates = _parseTemplatesCSV(content);
          } else if (file.name == '$_setsFileNamePrefix.csv') {
            sets = _parseSetsCSV(content);
          }
        }
      }

      if (templates.isEmpty) {
        return Result.error(
            ImportException('No templates found in the zip file.'));
      }

      // Clear existing data
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
