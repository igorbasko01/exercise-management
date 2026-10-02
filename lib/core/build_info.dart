/// Compile-time build metadata, set via `--dart-define` at build time.
///
/// `flutter-build-test.yml` passes `TEST_BUILD=true` and `BUILD_NAME`;
/// `flutter-build.yml` (production) leaves both unset, so they default to
/// `false` and empty.
class BuildInfo {
  const BuildInfo({
    this.isTestBuild = const bool.fromEnvironment('TEST_BUILD'),
    this.buildLabel = const String.fromEnvironment('BUILD_NAME'),
  });

  final bool isTestBuild;
  final String buildLabel;
}
