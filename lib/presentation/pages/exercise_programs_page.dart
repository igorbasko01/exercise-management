import 'package:exercise_management/presentation/pages/add_exercise_program_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_programs_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ExerciseProgramsPage extends StatelessWidget {
  const ExerciseProgramsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Programs')),
      body: Consumer<ExerciseProgramsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.fetchPrograms.running) {
            return const Center(child: CircularProgressIndicator());
          }
          if (viewModel.programs.isEmpty) {
            return const Center(child: Text('No training programs found.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: viewModel.programs.length,
            itemBuilder: (context, index) {
              final program = viewModel.programs[index];
              return Card(
                color: program.isActive
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  title: Text(program.name,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(program.description ??
                      '${program.sessions.length} sessions'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (program.isActive)
                        const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.check_circle, color: Colors.green),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            viewModel.setActiveProgram.execute(program);
                          },
                          child: const Text('Activate'),
                        ),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) =>
                                    AddExerciseProgramPage(program: program)));
                          } else if (value == 'delete') {
                            showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                      title: const Text('Delete Program'),
                                      content: const Text(
                                          'Are you sure you want to delete this program?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel')),
                                        TextButton(
                                            onPressed: () {
                                              viewModel.deleteProgram
                                                  .execute(program.id!);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Delete')),
                                      ],
                                    ));
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) =>
                            AddExerciseProgramPage(program: program)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddExerciseProgramPage()));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
