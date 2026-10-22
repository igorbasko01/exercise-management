import 'package:archive/archive.dart';
import 'package:exercise_management/core/csv_serializer.dart';
import 'package:exercise_management/core/enums/muscle_group.dart';
import 'package:exercise_management/core/enums/repetitions_range.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/backup_file_sink.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/models/exercise_set.dart';
import 'package:exercise_management/data/models/exercise_template.dart';
import 'package:exercise_management/data/repository/exceptions.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_program_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseTemplateRepository extends Mock
    implements ExerciseTemplateRepository {}

class MockExerciseSetRepository extends Mock implements ExerciseSetRepository {}

class MockExerciseProgramRepository extends Mock
    implements ExerciseProgramRepository {}

class FakeBackupFileSink implements BackupFileSink {
  final Map<String, List<int>> files = {};
  final List<SavedBackup> shared = [];
  Object? saveError;

  @override
  bool canShare = true;

  @override
  Future<SavedBackup> save(String fileName, List<int> bytes) async {
    if (saveError != null) throw saveError!;
    files['/downloads/$fileName'] = bytes;
    return SavedBackup(
        fileName: fileName,
        location: '/downloads folder',
        path: '/downloads/$fileName');
  }

  @override
  Future<void> share(SavedBackup backup) async => shared.add(backup);

  @override
  Future<List<int>> readBytes(String path) async {
    final bytes = files[path];
    if (bytes == null) throw StateError('File not found: $path');
    return bytes;
  }
}

void main() {
  group('SettingsViewModel importDataCommand', () {
    late SettingsViewModel viewModel;
    late MockExerciseTemplateRepository mockTemplateRepository;
    late MockExerciseSetRepository mockSetRepository;
    late MockExerciseProgramRepository mockProgramRepository;
    late FakeBackupFileSink fakeSink;

    final dummyTemplate = ExerciseTemplate(
        id: 'fallback',
        name: 'fallback',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.low,
        description: '');

    final dummySet = ExerciseSet(
        id: 'fallback',
        exerciseTemplateId: 'fallback',
        dateTime: DateTime.now(),
        equipmentWeight: 0.0,
        platesWeight: 0.0,
        repetitions: 0);

    final dummyProgram = ExerciseProgram(
        id: 'fallback',
        name: 'fallback',
        sessions: []);

    setUpAll(() {
      registerFallbackValue(dummyTemplate);
      registerFallbackValue(dummySet);
      registerFallbackValue(dummyProgram);
    });

    setUp(() async {
      mockTemplateRepository = MockExerciseTemplateRepository();
      mockSetRepository = MockExerciseSetRepository();
      mockProgramRepository = MockExerciseProgramRepository();
      fakeSink = FakeBackupFileSink();
      viewModel = SettingsViewModel(
        templatesRepository: mockTemplateRepository,
        setsRepository: mockSetRepository,
        programsRepository: mockProgramRepository,
        backupFileSink: fakeSink,
      );
    });

    test('should successfully import valid zip file with templates and sets',
        () async {
      const zipPath = '/picked/backup.zip';
      fakeSink.files[zipPath] = _createValidZipFile();

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.addExercise(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummyTemplate);
      });
      when(() => mockSetRepository.addExercise(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummySet);
      });

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Ok<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.addExercise(any())).called(2);
      verify(() => mockSetRepository.addExercise(any())).called(2);
    });

    test('should successfully import valid zip file with programs', () async {
      const zipPath = '/picked/backup.zip';
      fakeSink.files[zipPath] = _createValidZipFileWithPrograms();

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.addExercise(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummyTemplate);
      });
      when(() => mockSetRepository.addExercise(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummySet);
      });
      when(() => mockProgramRepository.addProgram(any()))
          .thenAnswer((invocation) async {
        return Result.ok(dummyProgram);
      });

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Ok<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.addExercise(any())).called(2);
      verify(() => mockSetRepository.addExercise(any())).called(2);
      verify(() => mockProgramRepository.addProgram(any())).called(1);
    });

    test('should return error when zip file does not exist', () async {
      await viewModel.importDataCommand.execute('/picked/non_existent.zip');

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockProgramRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when zip file is invalid', () async {
      const zipPath = '/picked/invalid.zip';
      fakeSink.files[zipPath] = 'This is not a valid zip file'.codeUnits;

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockProgramRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when clearing templates fails', () async {
      const zipPath = '/picked/backup.zip';
      fakeSink.files[zipPath] = _createValidZipFile();

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.error(
            ExerciseDatabaseException('Failed to clear templates'));
      });

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verify(() => mockTemplateRepository.clearAll()).called(1);
      verify(() => mockSetRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when clearing sets fails', () async {
      const zipPath = '/picked/backup.zip';
      fakeSink.files[zipPath] = _createValidZipFile();

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockTemplateRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.ok(null);
      });
      when(() => mockSetRepository.clearAll()).thenAnswer((invocation) async {
        return Result.error(ExerciseDatabaseException('Failed to clear sets'));
      });

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.clearAll());
      verify(() => mockSetRepository.clearAll()).called(1);
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when clearing programs fails', () async {
      const zipPath = '/picked/backup.zip';
      fakeSink.files[zipPath] = _createValidZipFile();

      when(() => mockProgramRepository.clearAll())
          .thenAnswer((invocation) async {
        return Result.error(
            ExerciseDatabaseException('Failed to clear programs'));
      });

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verify(() => mockProgramRepository.clearAll()).called(1);
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });

    test('should return error when template has invalid enum value', () async {
      const zipPath = '/picked/backup.zip';
      fakeSink.files[zipPath] = _createInvalidEnumZipFile();

      await viewModel.importDataCommand.execute(zipPath);

      expect(viewModel.importDataCommand.result, isA<Error<void>>());
      verifyNever(() => mockProgramRepository.clearAll());
      verifyNever(() => mockTemplateRepository.clearAll());
      verifyNever(() => mockSetRepository.clearAll());
      verifyNever(() => mockTemplateRepository.addExercise(any()));
      verifyNever(() => mockSetRepository.addExercise(any()));
      verifyNever(() => mockProgramRepository.addProgram(any()));
    });
  });

  group('SettingsViewModel exportDataCommand', () {
    late InMemoryExerciseRepository templatesRepository;
    late InMemoryExerciseSetRepository setsRepository;
    late FakeBackupFileSink fakeSink;
    late SettingsViewModel viewModel;

    final template = ExerciseTemplate(
        id: '1',
        name: 'Push-up',
        muscleGroup: MuscleGroup.chest,
        repetitionsRangeTarget: RepetitionsRange.medium,
        description: 'Basic push-up exercise');

    final set = ExerciseSet(
        id: '1',
        exerciseTemplateId: '1',
        dateTime: DateTime.parse('2023-01-01T10:00:00.000Z'),
        equipmentWeight: 0.0,
        platesWeight: 20.0,
        repetitions: 10);

    SettingsViewModel createViewModel(
            InMemoryExerciseRepository templates,
            InMemoryExerciseSetRepository sets) =>
        SettingsViewModel(
          templatesRepository: templates,
          setsRepository: sets,
          programsRepository: InMemoryExerciseProgramRepository(),
          backupFileSink: fakeSink,
        );

    setUp(() async {
      templatesRepository = InMemoryExerciseRepository();
      setsRepository = InMemoryExerciseSetRepository();
      fakeSink = FakeBackupFileSink();
      await templatesRepository.addExercise(template);
      await setsRepository.addExercise(set);
      viewModel = createViewModel(templatesRepository, setsRepository);
    });

    test('should hand a timestamped zip of every table to the sink',
        () async {
      await viewModel.exportDataCommand.execute();

      final result = viewModel.exportDataCommand.result;
      expect(result, isA<Ok<SavedBackup>>());
      final backup = (result as Ok<SavedBackup>).value;
      expect(backup.fileName,
          matches(RegExp(r'^exercise_data_export_\d{14}\.zip$')));
      expect(backup.location, '/downloads folder');

      final archive =
          ZipDecoder().decodeBytes(fakeSink.files[backup.path]!);
      expect(
          archive.files.map((f) => f.name),
          unorderedEquals([
            'exercise_templates.csv',
            'exercise_sets.csv',
            'exercise_programs.csv',
            'exercise_program_sessions.csv',
            'session_exercises.csv',
          ]));
    });

    test('should produce a zip that import reads back', () async {
      await viewModel.exportDataCommand.execute();
      final backup =
          (viewModel.exportDataCommand.result as Ok<SavedBackup>).value;

      final importedTemplates = InMemoryExerciseRepository();
      final importedSets = InMemoryExerciseSetRepository();
      await createViewModel(importedTemplates, importedSets)
          .importDataCommand
          .execute(backup.path!);

      expect((await importedTemplates.getExercises() as Ok).value, [template]);
      expect((await importedSets.getExercises() as Ok).value, [set]);
    });

    test('should return error when the sink fails to save', () async {
      fakeSink.saveError = StateError('disk full');

      await viewModel.exportDataCommand.execute();

      expect(viewModel.exportDataCommand.result, isA<Error<SavedBackup>>());
    });

    test('shareExportCommand should share the backup through the sink',
        () async {
      await viewModel.exportDataCommand.execute();
      final backup =
          (viewModel.exportDataCommand.result as Ok<SavedBackup>).value;

      await viewModel.shareExportCommand.execute(backup);

      expect(viewModel.shareExportCommand.result, isA<Ok<void>>());
      expect(fakeSink.shared, [backup]);
    });

    test('canShareExport should follow the sink', () {
      fakeSink.canShare = false;

      expect(viewModel.canShareExport, isFalse);
    });
  });
}

List<int> _createValidZipFile() {
  final archive = Archive();

  // Create templates using the same format as SettingsViewModel export
  final templates = [
    ExerciseTemplate(
      id: '1',
      name: 'Push-up',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
      description: 'Basic push-up exercise',
    ),
    ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.medium,
      description: null,
    ),
  ];
  final templatesCSV =
      CsvSerializer.toCSV(templates.map((t) => t.toMap()).toList());
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  // Create sets using the same format as SettingsViewModel export
  final sets = [
    ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: DateTime.parse('2023-01-01T10:00:00.000Z'),
      equipmentWeight: 0.0,
      platesWeight: 20.0,
      repetitions: 10,
      completedAt: null,
    ),
    ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      dateTime: DateTime.parse('2023-01-02T11:00:00.000Z'),
      equipmentWeight: 0.0,
      platesWeight: 30.0,
      repetitions: 15,
      completedAt: DateTime.parse('2023-01-02T11:30:00.000Z'),
    ),
  ];
  final setsCSV = CsvSerializer.toCSV(sets.map((s) => s.toMap()).toList());
  archive.addFile(
      ArchiveFile('exercise_sets.csv', setsCSV.length, setsCSV.codeUnits));

  return ZipEncoder().encode(archive);
}

List<int> _createValidZipFileWithPrograms() {
  final archive = Archive();

  // Create templates
  final templates = [
    ExerciseTemplate(
      id: '1',
      name: 'Push-up',
      muscleGroup: MuscleGroup.chest,
      repetitionsRangeTarget: RepetitionsRange.medium,
      description: 'Basic push-up exercise',
    ),
    ExerciseTemplate(
      id: '2',
      name: 'Squat',
      muscleGroup: MuscleGroup.quadriceps,
      repetitionsRangeTarget: RepetitionsRange.medium,
      description: null,
    ),
  ];
  final templatesCSV =
      CsvSerializer.toCSV(templates.map((t) => t.toMap()).toList());
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  // Create sets
  final sets = [
    ExerciseSet(
      id: '1',
      exerciseTemplateId: '1',
      dateTime: DateTime.parse('2023-01-01T10:00:00.000Z'),
      equipmentWeight: 0.0,
      platesWeight: 20.0,
      repetitions: 10,
      completedAt: null,
    ),
    ExerciseSet(
      id: '2',
      exerciseTemplateId: '2',
      dateTime: DateTime.parse('2023-01-02T11:00:00.000Z'),
      equipmentWeight: 0.0,
      platesWeight: 30.0,
      repetitions: 15,
      completedAt: DateTime.parse('2023-01-02T11:30:00.000Z'),
    ),
  ];
  final setsCSV = CsvSerializer.toCSV(sets.map((s) => s.toMap()).toList());
  archive.addFile(
      ArchiveFile('exercise_sets.csv', setsCSV.length, setsCSV.codeUnits));

  // Create programs
  final programsMaps = [
    {'id': '1', 'name': 'Strength Program', 'description': 'A strength training program', 'is_active': '1'},
  ];
  final programsCSV = CsvSerializer.toCSV(programsMaps);
  archive.addFile(ArchiveFile(
      'exercise_programs.csv', programsCSV.length, programsCSV.codeUnits));

  // Create program sessions
  final sessionsMaps = [
    {'id': '10', 'program_id': '1', 'name': 'Day 1 - Upper Body', 'description': 'Upper body workout'},
    {'id': '11', 'program_id': '1', 'name': 'Day 2 - Lower Body', 'description': null},
  ];
  final sessionsCSV = CsvSerializer.toCSV(sessionsMaps);
  archive.addFile(ArchiveFile('exercise_program_sessions.csv',
      sessionsCSV.length, sessionsCSV.codeUnits));

  // Create session exercises links
  final linksMaps = [
    {'session_id': '10', 'exercise_template_id': '1', 'ordering': 0},
    {'session_id': '11', 'exercise_template_id': '2', 'ordering': 0},
  ];
  final linksCSV = CsvSerializer.toCSV(linksMaps);
  archive.addFile(ArchiveFile(
      'session_exercises.csv', linksCSV.length, linksCSV.codeUnits));

  return ZipEncoder().encode(archive);
}

List<int> _createInvalidEnumZipFile() {
  final archive = Archive();

  // Create an invalid template with out-of-range enum value
  final templatesCSV =
      'id,name,muscle_group,repetitions_range,description\n1,Push-up,99999,1,Basic push-up exercise';
  archive.addFile(ArchiveFile(
      'exercise_templates.csv', templatesCSV.length, templatesCSV.codeUnits));

  return ZipEncoder().encode(archive);
}
