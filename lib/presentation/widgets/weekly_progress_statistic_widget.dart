import 'package:flutter/cupertino.dart';

class WeeklyProgressStatisticWidget extends StatelessWidget {
  static const List<String> _days = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat'
  ];

  // TODO: Replace with data from view model
  final List<bool> _daysExercised = const [
    true, false, true, true, false, true, false
  ];

  const WeeklyProgressStatisticWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Weekly Progress'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _days
              .sublist(0, 5)
              .asMap()
              .entries
              .map((entry) => _DayIndicator(
                    day: entry.value,
                    exercised: _daysExercised[entry.key],
                  ))
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _days
              .sublist(5)
              .asMap()
              .entries
              .map((entry) => _DayIndicator(
                    day: entry.value,
                    exercised: _daysExercised[entry.key + 5],
                  ))
              .toList(),
        ),
        const SizedBox(height: 15),
        Text('${_daysExercised.where((e) => e).length}', style: const TextStyle(fontSize: 38),),
      ],
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String day;
  final bool exercised;

  const _DayIndicator({
    required this.day,
    required this.exercised,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: exercised
                ? CupertinoColors.activeGreen
                : CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
