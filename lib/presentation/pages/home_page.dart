import 'package:exercise_management/presentation/widgets/average_weekly_statistics_widget.dart';
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
          child: const WeeklyProgressStatisticWidget(),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              border: Border.all()
          ),
          child: const AverageWeeklyStatisticsWidget(),
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