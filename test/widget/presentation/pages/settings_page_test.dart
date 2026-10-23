import 'package:exercise_management/core/command.dart';
import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/backup_file_sink.dart';
import 'package:exercise_management/presentation/pages/settings_page.dart';
import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

class MockSettingsViewModel extends Mock implements SettingsViewModel {}

void main() {
  const backup = SavedBackup(
      fileName: 'exercise_data_export_20260101000000.zip',
      location: '/storage/emulated/0/Download folder',
      path: '/storage/emulated/0/Download/exercise_data_export_20260101000000.zip');

  late MockSettingsViewModel viewModel;
  late List<SavedBackup> sharedBackups;

  setUp(() {
    viewModel = MockSettingsViewModel();
    sharedBackups = [];
    when(() => viewModel.exportDataCommand)
        .thenReturn(Command0(() async => Result.ok(backup)));
    when(() => viewModel.importDataCommand)
        .thenReturn(Command1((String _) async => Result.ok(null)));
    when(() => viewModel.shareExportCommand)
        .thenReturn(Command1((SavedBackup b) async {
      sharedBackups.add(b);
      return Result.ok(null);
    }));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<SettingsViewModel>.value(
          value: viewModel,
          child: const SettingsPage(),
        ),
      ),
    );
  }

  Future<void> exportData(WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();
    await tester.tap(find.text('Export Data'));
    await tester.pumpAndSettle();
  }

  testWidgets('export shows where the backup landed and offers Share',
      (tester) async {
    when(() => viewModel.canShareExport).thenReturn(true);

    await exportData(tester);

    expect(
        find.text(
            'Data exported successfully to /storage/emulated/0/Download folder.'),
        findsOneWidget);

    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(sharedBackups, [backup]);
  });

  testWidgets('export does not offer Share when the platform cannot share',
      (tester) async {
    when(() => viewModel.canShareExport).thenReturn(false);

    await exportData(tester);

    expect(
        find.text(
            'Data exported successfully to /storage/emulated/0/Download folder.'),
        findsOneWidget);
    expect(find.text('Share'), findsNothing);
  });

  testWidgets('a failed share shows the error once', (tester) async {
    when(() => viewModel.canShareExport).thenReturn(true);
    when(() => viewModel.shareExportCommand).thenReturn(Command1(
        (SavedBackup _) async =>
            Result.error(ExportException('Error sharing file: boom'))));

    await exportData(tester);
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    expect(find.text('Error sharing file: boom'), findsOneWidget);
  });
}
