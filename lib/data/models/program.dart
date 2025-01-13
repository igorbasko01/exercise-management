class Program {
  final String id;
  final String name;
  final String? description;
  final List<String> exerciseIds;

  Program({
    required this.id,
    required this.name,
    this.description,
    required this.exerciseIds,
  });
}