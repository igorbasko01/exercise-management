import 'package:exercise_management/core/build_info.dart';
import 'package:flutter/material.dart';

/// Wraps [child] with a corner ribbon when [buildInfo] marks a test build.
class TestBuildBanner extends StatelessWidget {
  const TestBuildBanner({
    super.key,
    required this.buildInfo,
    required this.child,
  });

  final BuildInfo buildInfo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!buildInfo.isTestBuild) {
      return child;
    }

    final message =
        buildInfo.buildLabel.isEmpty ? 'TEST' : 'TEST ${buildInfo.buildLabel}';

    return Banner(
      key: const Key('testBuildBanner'),
      location: BannerLocation.topEnd,
      message: message,
      color: Colors.red,
      child: child,
    );
  }
}
