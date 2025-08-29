import 'package:exercise_management/presentation/view_models/settings_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
            padding: const EdgeInsets.all(16.0),
            child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Export Data')),
              ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.upload),
                  label: const Text('Import Data')),
            ]));
      }
    );
  }
}
