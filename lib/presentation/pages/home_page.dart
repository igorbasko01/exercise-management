import 'package:exercise_management/presentation/widgets/weekly_progress_statistic_widget.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      primary: false,
      padding: const EdgeInsets.all(20),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      crossAxisCount: 2,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: WeeklyProgressStatisticWidget(),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const Center(child: Text('Another Statistic')),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const Center(child: Text('More Stats')),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const Center(child: Text('Even More Stats')),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const Center(child: Text('Stats')),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const Center(child: Text('Last Stats')),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const Center(child: Text('Additional Stats')),
        )
      ],
    );
  }
}