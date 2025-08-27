import 'package:flutter/cupertino.dart';

class WeeklyProgressStatisticWidget extends StatelessWidget {
  static const List<String> weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu'];
  static const List<String> weekendDays = ['Fri', 'Sat'];

  const WeeklyProgressStatisticWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Weekly Progress'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map((day) => Column(
                    children: [Text(day)],
                  ))
              .toList(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekendDays
              .map((day) => Column(
                    children: [Text(day)],
                  ))
              .toList(),
        ),
      ],
    );
  }
}
