# CLAUDE.md

Guidance for working in this repository.

## Project

`exercise_management` — a Flutter (Android) app for managing exercises, workout
sets, training programs, and an opinionated progression system. Data is stored
locally in SQLite (offline-first), with import/export to zip/CSV for backup and
sharing.

- Flutter `3.38.9`, Dart SDK `>=3.10.0 <4.0.0` (pinned via `pubspec.yaml`).
- State management: `provider`. Local DB: `sqflite`. Notifications:
  `flutter_local_notifications` + `timezone`. Prefs: `shared_preferences`.

## Commands

```sh
flutter pub get          # install dependencies
flutter run              # run the app
flutter test             # run all unit + widget tests
flutter test test/unit/core/result_test.dart   # run a single test file
flutter analyze          # static analysis / lint (must be clean)
```

CI (`.github/workflows/flutter-checks.yml`) runs `flutter test` and
`flutter analyze` on every PR to `main`. Both must pass. Match that locally
before pushing.

## Architecture

Three layers under `lib/`, dependencies pointing inward (presentation → data →
core):

- `core/` — framework-agnostic building blocks: `Result`/`Ok`/`Error`,
  `Command`, `BaseException`, enums, services, utilities.
- `data/` — `models/` (plain Dart data classes), `repository/` (abstract
  interface + `sqflite_*` and `in_memory_*` implementations), and `database/`
  (schema creation + versioned migrations).
- `presentation/` — `pages/` (widgets), `view_models/` (`ChangeNotifier`), and
  reusable `widgets/`.

Dependency injection happens in `lib/main.dart` via `MultiProvider`: the
`Database`, each repository, and each view model are wired there. View models
`..execute()` their initial-load command at creation time.

### Guiding principles

- **Program to interfaces.** Depend on abstractions, not concretions.
  Repositories are abstract classes; consumers (view models, other services)
  receive them through constructor parameters and never `new` up a concrete
  impl. Widgets receive view models via `Provider`, not by constructing them.
  This keeps every seam swappable and mockable.
- **Keep logic out of the presentation layer.** Pages and widgets should be
  thin: render state and forward user intent to a view model command. Business
  rules, data transformation, progression algorithms, statistics, and
  persistence belong in `core/`, `data/`, or a view model — never inline in a
  widget's `build`. If you're tempted to compute something in a widget, push it
  down a layer so it can be unit-tested without the widget tree.

### Key patterns — follow these

- **Result type, not exceptions across boundaries.** Repositories and commands
  return `Future<Result<T>>`. Consume with an exhaustive `switch` on
  `Ok<T>()` / `Error()`. Errors carry a `BaseException` subtype.
- **Command pattern for view-model actions.** Expose UI actions as
  `Command0`/`Command1`/... fields (see `core/command.dart`). They guard against
  concurrent execution, track `running`/`completed`/`error`, and
  `notifyListeners`. View models add a listener that re-emits `notifyListeners`,
  and must remove listeners + dispose commands in `dispose()`.
- **Repository interface + two implementations.** Every repository is an
  abstract class with a `sqflite_*` production impl and an `in_memory_*` impl
  used for tests/prototyping. Add both when introducing a new repository.
- **Models** are immutable-ish plain classes with `copyWith`, `toMap`/
  `fromMap` (snake_case DB keys, enums stored as `.index`), and value-based
  `==`/`hashCode`. `Value<T>` wrapper (`core/value.dart`) lets `copyWith`
  distinguish "set to null" from "leave unchanged".
- **Enums** live in `core/enums/` and expose behavior via extensions (e.g.
  `RepetitionsRangeExtension`).

### Database migrations

Schema lives in `data/database/exercise_database_creation.dart`. Migrations are
in `exercise_database_migrations.dart`: bump `latestVersion` and add an entry to
`upgradeSteps` keyed by the target version. `AppDatabaseFactory` enables
`PRAGMA foreign_keys = ON` and runs create/upgrade steps. Never edit an existing
migration step — always add a new version.

## Testing

Tests mirror `lib/` under `test/` (`test/unit/...`, `test/widget/...`). Use
`mocktail` for mocks, `sqflite_common_ffi` for DB tests, and `fake_async`/
`clock` for time-dependent logic (e.g. the rest timer).

Test at the right seam — this is why interfaces matter:

- **Core / data logic** — unit-test directly. It has no Flutter dependency, so
  most of the app's behavior should be verifiable here.
- **View models** — unit-test against the `in_memory_*` repositories (or
  `mocktail` mocks of the abstract repository), asserting on state and command
  `completed`/`error`.
- **Widgets** — widget-test them too. Because pages consume view models through
  `Provider`, wrap the widget under test in a `ChangeNotifierProvider` (or
  `Provider`) supplying a `mocktail` mock of the view model, stub its getters
  and commands, and pump. See `test/widget/presentation/pages/` for the
  pattern. Keeping widgets thin (above) is what makes this cheap — the widget
  test only verifies rendering and intent forwarding, not business rules.

## Conventions

- **Conventional Commits are required** — `release-please` (release-type: dart)
  parses history to bump `version` in `pubspec.yaml` and generate
  `CHANGELOG.md`. Use `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, with
  optional scopes like `feat(timer):`. Do not manually edit the version or
  changelog.
- Releases: merging the release-please PR tags a version, which triggers
  `flutter-build.yml` to build and attach a signed release APK.
- Keep `flutter analyze` clean (lints from `flutter_lints` via
  `analysis_options.yaml`).
