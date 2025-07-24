import 'package:exercise_management/data/database/database_factory.dart';
import 'package:exercise_management/data/database/exercise_database_migrations.dart';
import 'package:exercise_management/data/repository/exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/exercise_set_repository.dart';
import 'package:exercise_management/data/repository/exercise_template_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_presentation_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_set_repository.dart';
import 'package:exercise_management/data/repository/in_memory_exercise_template_repository.dart';
import 'package:exercise_management/data/repository/sqflite_exercise_template_repository.dart';
import 'package:exercise_management/presentation/pages/exercise_sets_page.dart';
import 'package:exercise_management/presentation/pages/exercise_templates_page.dart';
import 'package:exercise_management/presentation/pages/home_page.dart';
import 'package:exercise_management/presentation/view_models/exercise_sets_view_model.dart';
import 'package:exercise_management/presentation/view_models/exercise_templates_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import 'data/database/exercise_database_creation.dart';

Future<String> getDatabasePath() async {
  final databasesPath = await getDatabasesPath();
  return join(databasesPath, 'exercise_management.db');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final path = await getDatabasePath();
  final database = await AppDatabaseFactory.createDatabase(
      path, createStatements, ExerciseDatabaseMigrations());

  runApp(MultiProvider(
    providers: [
      Provider<Database>.value(value: database),
      Provider<ExerciseTemplateRepository>(
          create: (_) => SqfliteExerciseTemplateRepository(database),
      ),
      Provider<ExerciseSetRepository>(
        create: (context) => InMemoryExerciseSetRepository(),
      ),
      ProxyProvider2<ExerciseSetRepository, ExerciseTemplateRepository,
          ExerciseSetPresentationRepository>(
        update: (_, exerciseSetRepository, exerciseTemplateRepository, __) =>
            InMemoryExerciseSetPresentationRepository(
                exerciseSetRepository:
                    exerciseSetRepository as InMemoryExerciseSetRepository,
                exerciseTemplateRepository:
                    exerciseTemplateRepository as SqfliteExerciseTemplateRepository),
      ),
      ChangeNotifierProvider(
          create: (context) => ExerciseTemplatesViewModel(
              exerciseTemplateRepository: context.read())
            ..fetchExerciseTemplates.execute()),
      ChangeNotifierProvider(
          create: (context) => ExerciseSetsViewModel(
              exerciseSetRepository: context.read(),
              exerciseSetPresentationRepository: context.read())
            ..fetchExerciseSets.execute())
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exercise Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Exercise Management'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const ExerciseSetsPage(),
    const ExerciseTemplatesPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center), label: 'Sets'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_books), label: 'Exercises'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
