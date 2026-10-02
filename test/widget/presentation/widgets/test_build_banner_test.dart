import 'package:exercise_management/core/build_info.dart';
import 'package:exercise_management/presentation/widgets/test_build_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bannerKey = Key('testBuildBanner');

  group('TestBuildBanner', () {
    testWidgets('shows a TEST banner when isTestBuild is true',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TestBuildBanner(
          buildInfo: const BuildInfo(isTestBuild: true, buildLabel: 'pr94'),
          child: const Text('content'),
        ),
      ));

      expect(find.byKey(bannerKey), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
      final banner = tester.widget<Banner>(find.byKey(bannerKey));
      expect(banner.message, 'TEST pr94');
    });

    testWidgets('falls back to a plain TEST label when buildLabel is empty',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: TestBuildBanner(
          buildInfo: const BuildInfo(isTestBuild: true),
          child: const Text('content'),
        ),
      ));

      final banner = tester.widget<Banner>(find.byKey(bannerKey));
      expect(banner.message, 'TEST');
    });

    testWidgets('renders no banner when isTestBuild is false',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TestBuildBanner(
          buildInfo: BuildInfo(),
          child: Text('content'),
        ),
      ));

      expect(find.byKey(bannerKey), findsNothing);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
