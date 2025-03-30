import 'package:exercise_management/data/database/database_factory.dart';
import 'package:exercise_management/data/database/database_migrations.dart';
import 'package:exercise_management/data/database/exercise_database_creation.dart';
import 'package:exercise_management/data/database/exercise_database_migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseMigrations mockDatabaseMigrations;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    mockDatabaseMigrations = ExerciseDatabaseMigrations();
  });

  test('should execute all createStatements withouth errors', () async {
    final database = await AppDatabaseFactory.createDatabase(
        inMemoryDatabasePath, createStatements, mockDatabaseMigrations);
    final tables = await database
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
    final tableNames = tables.map((row) => row['name']).toList();
    expect(tableNames, containsAll(['exercise_templates', 'exercise_sets']));
    await database.close();
  });
}
