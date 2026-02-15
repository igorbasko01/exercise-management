import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/value.dart';
import 'package:exercise_management/data/models/exercise_program.dart';
import 'package:exercise_management/data/repository/exercise_program_repository.dart';
import 'package:exercise_management/presentation/view_models/exercise_programs_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExerciseProgramRepository extends Mock
    implements ExerciseProgramRepository {}

void main() {
  group('ExerciseProgramsViewModel', () {
    late MockExerciseProgramRepository mockRepository;
    late ExerciseProgramsViewModel viewModel;

    setUp(() {
      mockRepository = MockExerciseProgramRepository();
      viewModel = ExerciseProgramsViewModel(repository: mockRepository);
      registerFallbackValue(ExerciseProgram(name: 'fallback', sessions: []));
    });

    test('fetchPrograms updates programs list on success', () async {
      final programs = [
        ExerciseProgram(id: '1', name: 'Program 1', sessions: []),
        ExerciseProgram(id: '2', name: 'Program 2', sessions: []),
      ];

      when(() => mockRepository.getPrograms())
          .thenAnswer((_) async => Result.ok(programs));

      await viewModel.fetchPrograms.execute();

      expect(viewModel.programs, equals(programs));
    });

    test('addProgram calls repository and refreshes list', () async {
      final newProgram = ExerciseProgram(name: 'New Program', sessions: []);
      final savedProgram = newProgram.copyWith(id: Value('1'));

      when(() => mockRepository.addProgram(any()))
          .thenAnswer((_) async => Result.ok(savedProgram));
      when(() => mockRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([savedProgram]));

      await viewModel.addProgram.execute(newProgram);

      verify(() => mockRepository.addProgram(newProgram)).called(1);
      verify(() => mockRepository.getPrograms()).called(1);
      expect(viewModel.programs, equals([savedProgram]));
    });

    test('updateProgram calls repository and refreshes list', () async {
      final program = ExerciseProgram(id: '1', name: 'Program', sessions: []);
      final updatedProgram = program.copyWith(name: 'Updated Program');

      when(() => mockRepository.updateProgram(any()))
          .thenAnswer((_) async => Result.ok(updatedProgram));
      when(() => mockRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([updatedProgram]));

      await viewModel.updateProgram.execute(updatedProgram);

      verify(() => mockRepository.updateProgram(updatedProgram)).called(1);
      verify(() => mockRepository.getPrograms()).called(1);
      expect(viewModel.programs, equals([updatedProgram]));
    });

    test('deleteProgram calls repository and updates list', () async {
      final program = ExerciseProgram(id: '1', name: 'Program', sessions: []);
      // Pre-populate viewmodel
      when(() => mockRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([program]));
      await viewModel.fetchPrograms.execute();

      when(() => mockRepository.deleteProgram('1'))
          .thenAnswer((_) async => Result.ok(program));

      await viewModel.deleteProgram.execute('1');

      verify(() => mockRepository.deleteProgram('1')).called(1);
      expect(viewModel.programs, isEmpty);
    });

    test('setActiveProgram activates program and updates repository', () async {
       final program1 = ExerciseProgram(id: '1', name: 'Program 1', sessions: [], isActive: false);
       final program1Active = program1.copyWith(isActive: true);

       when(() => mockRepository.updateProgram(any()))
          .thenAnswer((_) async => Result.ok(program1Active));
       when(() => mockRepository.getPrograms())
          .thenAnswer((_) async => Result.ok([program1Active]));

       await viewModel.setActiveProgram.execute(program1);

       // Verify that updateProgram was called with isActive = true
       final captured = verify(() => mockRepository.updateProgram(captureAny())).captured;
       final updatedArg = captured.first as ExerciseProgram;
       expect(updatedArg.isActive, isTrue);
       expect(updatedArg.id, '1');
    });
  });
}
