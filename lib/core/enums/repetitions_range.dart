import 'package:exercise_management/core/range.dart';

enum RepetitionsRange { high, medium, low }

extension RepetitionsRangeExtension on RepetitionsRange {
  Range get range {
    switch (this) {
      case RepetitionsRange.high:
        return Range(10, 15);
      case RepetitionsRange.medium:
        return Range(6, 9);
      case RepetitionsRange.low:
        return Range(1, 5);
    }
  }
}
