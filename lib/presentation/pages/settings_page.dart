import 'package:exercise_management/core/result.dart';
import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isExportDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<SettingsViewModel>()
          .exportDataCommand
          .addListener(_onExportCommandChanged);
    });
  }

  @override
  void dispose() {
    context
        .read<SettingsViewModel>()
        .exportDataCommand
        .removeListener(_onExportCommandChanged);
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
      _handleExportResult(command.result as Result<String>?);
    }
  }

  void _showInProgressDialog(String message) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
                content: Row(children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text(message)
            ])));
  }

  void _handleExportResult(Result<String>? result) {
    if (result == null) return;

    if (result is Ok<String>) {
      final filePath = (result as Ok).value;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Data exported successfully.'),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _shareFile(filePath),
          )));
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error exporting data: ${(result as Error).error}')));
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await SharePlus.instance.share(ShareParams(
          files: [XFile(filePath)],
          subject: 'Exercise Data Export',
          text: 'Here is my exercise data backup file.'));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error sharing file: $e')));
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
                onPressed: null,
                icon: const Icon(Icons.upload),
                label: const Text('Import Data')),
          ]));
    });
  }
}
