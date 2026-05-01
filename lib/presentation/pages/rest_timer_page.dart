import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/rest_timer_view_model.dart';

class RestTimerPage extends StatelessWidget {
  const RestTimerPage({super.key});

  final List<int> _durationOptions = const [30, 60, 90, 120];

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RestTimerViewModel>();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              viewModel.isRunning ? 'Time Remaining' : 'Select Rest Time',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            Text(
              _formatTime(viewModel.remainingSeconds),
              style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            if (!viewModel.isRunning)
              Wrap(
                spacing: 10,
                children: _durationOptions.map((duration) {
                  return ChoiceChip(
                    label: Text('${duration}s'),
                    selected: viewModel.selectedDuration == duration,
                    onSelected: (selected) {
                      if (selected) {
                        viewModel.setSelectedDuration(duration);
                      }
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: viewModel.isRunning 
                  ? () => viewModel.stopTimer() 
                  : () => viewModel.startTimer(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                backgroundColor: viewModel.isRunning
                    ? Theme.of(context).colorScheme.errorContainer
                    : Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Text(
                viewModel.isRunning ? 'Stop Timer' : 'Start Timer',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
