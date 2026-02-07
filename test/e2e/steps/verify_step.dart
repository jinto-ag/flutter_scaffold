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

    await context.runInProject('flutter', ['pub', 'get']);
    await context.runInProject('flutter', ['analyze']);
    await context.runInProject('flutter', ['test']);
  }
}
