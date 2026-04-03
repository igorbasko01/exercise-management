enum ProgressionType { standard, positiveOnly }

extension ProgressionTypeExtension on ProgressionType {
  String get displayName {
    switch (this) {
      case ProgressionType.standard:
        return 'Standard';
      case ProgressionType.positiveOnly:
        return 'Positive Only';
    }
  }
}
