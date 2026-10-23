import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/core/services/backup_file_sink.dart';
import 'package:exercise_management/presentation/pages/exercise_programs_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExportDialogShowing = false;
  late final SettingsViewModel _settingsViewModel;

  @override
  void initState() {
    super.initState();
    _settingsViewModel = context.read<SettingsViewModel>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _settingsViewModel.exportDataCommand.addListener(_onExportCommandChanged);
      _settingsViewModel.importDataCommand.addListener(_onImportCommandChanged);
    });
  }

  @override
  void dispose() {
    _settingsViewModel.exportDataCommand
        .removeListener(_onExportCommandChanged);
    _settingsViewModel.importDataCommand
        .removeListener(_onImportCommandChanged);
    super.dispose();
  }

  void _onExportCommandChanged() {
    final command = context.read<SettingsViewModel>().exportDataCommand;

    if (command.running && !_isExportDialogShowing) {
      _isExportDialogShowing = true;
      _showInProgressDialog('Exporting data...');
    } else if (!command.running && _isExportDialogShowing) {
      _isExportDialogShowing = false;
      Navigator.of(context).pop();
      _handleExportResult(command.result as Result<SavedBackup>?);
    }
  }

  void _onImportCommandChanged() {
    final command = context.read<SettingsViewModel>().importDataCommand;

    if (command.running) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Importing data...')));
    } else if (command.error) {
      final result = command.result;
      if (result is Error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error importing data: ${result.error}')));
      }
    } else if (command.result is Ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully.')));
      context
          .read<ExerciseTemplatesViewModel>()
          .fetchExerciseTemplates
          .execute();
      context.read<ExerciseSetsViewModel>().fetchExerciseSets.execute();
    }
  }

  void _showInProgressDialog(String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                content: Row(children: [
              CircularProgressIndicator(
                semanticsLabel: 'Exporting data',
              ),
              SizedBox(width: 16),
              Text(message)
            ])));
  }

  void _handleExportResult(Result<SavedBackup>? result) {
    if (result == null) return;

    if (result is Ok<SavedBackup>) {
      final backup = result.value;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data exported successfully to ${backup.location}.'),
          action: _settingsViewModel.canShareExport
              ? SnackBarAction(
                  label: 'Share',
                  onPressed: () => _shareBackup(backup),
                )
              : null));
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error exporting data: ${(result as Error).error}')));
    }
  }

  Future<void> _shareBackup(SavedBackup backup) async {
    final command = _settingsViewModel.shareExportCommand;
    await command.execute(backup);
    final result = command.result;
    if (mounted && result is Error) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error.message)));
    }
  }

  Future<void> _importData() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Importing data from $filePath')));
          await context
              .read<SettingsViewModel>()
              .importDataCommand
              .execute(filePath);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(builder: (context, viewModel, child) {
      return Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ElevatedButton.icon(
                onPressed: () => viewModel.exportDataCommand.execute(),
                icon: const Icon(Icons.save_alt),
                label: const Text('Export Data')),
            ElevatedButton.icon(
                onPressed: _importData,
                icon: const Icon(Icons.upload),
                label: const Text('Import Data')),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const ExerciseProgramsPage()));
                },
                icon: const Icon(Icons.fitness_center),
                label: const Text('Training Programs')),
          ]));
    });
  }
}
