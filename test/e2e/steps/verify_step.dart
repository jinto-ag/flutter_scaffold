/// Verify step for E2E tests.
library;

import '../step_base.dart';
import '../test_context.dart';

/// Step that verifies the generated project with flutter analyze and test.
class VerifyStep extends E2EStep {
  @override
  String get name => 'verification';

  @override
  String get description => 'Verification (analyze & test)';

  @override
  List<String> get dependencies => [];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    context.logger.info('Verifying ${context.projectPath}...');

    // Run flutter pub get
    await context.logCommand(
      stepName: 'verification',
      commandName: 'flutter_pub_get',
      description: 'Run flutter pub get',
      args: ['flutter', 'pub', 'get'],
      useScaffold: false,
    );

    // Run flutter analyze
    await context.logCommand(
      stepName: 'verification',
      commandName: 'flutter_analyze',
      description: 'Run flutter analyze',
      args: ['flutter', 'analyze', 'lib', 'test'],
      useScaffold: false,
    );

    // Run flutter test
    await context.logCommand(
      stepName: 'verification',
      commandName: 'flutter_test',
      description: 'Run flutter test',
      args: ['flutter', 'test'],
      useScaffold: false,
    );
  }
}
