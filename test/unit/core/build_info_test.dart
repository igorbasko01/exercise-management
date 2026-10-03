import 'package:exercise_management/core/build_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuildInfo', () {
    test('defaults to a non-test build with no label', () {
      const buildInfo = BuildInfo();

      expect(buildInfo.isTestBuild, isFalse);
      expect(buildInfo.buildLabel, isEmpty);
    });

    test('accepts explicit values', () {
      const buildInfo = BuildInfo(isTestBuild: true, buildLabel: '1.4.0-pr94.57');

      expect(buildInfo.isTestBuild, isTrue);
      expect(buildInfo.buildLabel, '1.4.0-pr94.57');
    });
  });
}
