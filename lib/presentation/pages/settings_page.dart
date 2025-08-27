import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.save_alt),
              label: const Text('Export Data')
          ),
          ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.upload),
              label: const Text('Import Data')
          ),
        ]
      )
    );
  }
}