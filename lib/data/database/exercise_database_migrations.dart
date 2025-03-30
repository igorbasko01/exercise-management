import 'package:exercise_management/data/database/database_migrations.dart';
import 'package:sqflite/sqflite.dart';

class ExerciseDatabaseMigrations extends DatabaseMigrations {
  @override
  int get latestVersion => 1;

  @override
  Map<int, Future<void> Function(Database db)> get upgradeSteps => {};
}
