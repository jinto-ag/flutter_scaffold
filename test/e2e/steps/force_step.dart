/// Force flag step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests --force flag for overwriting existing files.
class ForceStep extends E2EStep {
  @override
  String get name => 'force_flag';

  @override
  String get description => 'Force flag (overwrite) verification';

  @override
  List<String> get dependencies => [];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'force_test';

    // Create feature
    await context.runScaffoldInProject(['add', 'feature', featureName]);

    FileAssertions.expectDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );

    // Try to create again without --force (should fail)
    try {
      await context.runScaffoldInProject(['add', 'feature', featureName]);
      throw Exception('Duplicate feature without --force should fail');
    } catch (e) {
      if (!e.toString().contains('exit code 1') &&
          !e.toString().contains('Exit Code: 1') &&
          !e.toString().contains('already exists')) {
        rethrow;
      }
    }

    // Create with --force (should succeed)
    await context.runScaffoldInProject([
      'add',
      'feature',
      featureName,
      '--force',
    ]);

    FileAssertions.expectDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );
  }
}
