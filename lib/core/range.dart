class Range {
  final int min;
  final int max;

  Range(this.min, this.max);

  @override
  String toString() {
    return '$min to $max';
  }
}