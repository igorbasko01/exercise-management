import 'dart:io';

import 'package:archive/archive.dart';
import 'package:csv/csv.dart';
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

    exportDataCommand = Command0(_exportData)..addListener(_onCommandExecuted);
  }

  final ExerciseTemplateRepository _templatesRepository;
  final ExerciseSetRepository _setsRepository;

  late final Command0<String> exportDataCommand;

  void _onCommandExecuted() {
    notifyListeners();
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

    final templatesFile = File('${tempDir.path}/exercise_templates_$timestamp.csv');
    final setsFile = File('${tempDir.path}/exercise_sets_$timestamp.csv');

    await templatesFile.writeAsString(templatesCSV);
    await setsFile.writeAsString(setsCSV);

    final archive = Archive();
    archive.addFile(ArchiveFile('exercise_templates.csv', templatesFile.lengthSync(), templatesFile.readAsBytesSync()));
    archive.addFile(ArchiveFile('exercise_sets.csv', setsFile.lengthSync(), setsFile.readAsBytesSync()));

    final zipFile = File('${tempDir.path}/exercise_data_export_$timestamp.zip');
    await zipFile.writeAsBytes(ZipEncoder().encode(archive));

    await templatesFile.delete();
    await setsFile.delete();

    return Result.ok(zipFile.path);
  }

  String _createTemplatesCSV(List<ExerciseTemplate> templates) {
    final rows = <List<String>>[];

    rows.add(['id', 'name', 'muscle_group', 'repetitions_range', 'description']);

    for (final template in templates) {
      rows.add([
        template.id ?? 'unknown',
        template.name,
        template.muscleGroup.index.toString(),
        template.repetitionsRangeTarget.index.toString(),
        template.description ?? ''
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  String _createSetsCSV(List<ExerciseSet> sets) {
    final rows = <List<String>>[];

    rows.add(['id', 'exercise_template_id', 'date_time', 'equipment_weight', 'plates_weight', 'repetitions']);

    for (final set in sets) {
      rows.add([
        set.id ?? 'unknown',
        set.exerciseTemplateId,
        set.dateTime.toIso8601String(),
        set.equipmentWeight.toString(),
        set.platesWeight.toString(),
        set.repetitions.toString()
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }
}