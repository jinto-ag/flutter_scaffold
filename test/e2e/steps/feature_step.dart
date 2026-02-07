/// Feature step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests feature add/remove commands.
class FeatureStep extends E2EStep {
  @override
  String get name => 'features';

  @override
  String get description => 'Feature management (add/remove)';

  @override
  List<String> get dependencies => [
    'lib/src/commands/add_feature_command.dart',
    'lib/src/commands/remove_feature_command.dart',
    'lib/src/templates/feature/**/*.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'test_feat';

    // Add Feature
    await context.runScaffoldInProject(['add', 'feature', featureName]);

    FileAssertions.expectDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );
    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/presentation/screens/${featureName}_screen.dart',
    );

    // Add Duplicate (should fail)
    try {
      await context.runScaffoldInProject(['add', 'feature', featureName]);
      throw Exception('Duplicate feature addition should have failed');
    } catch (e) {
      if (!e.toString().contains('exit code 1') &&
          !e.toString().contains('Exit Code: 1')) {
        rethrow;
      }
    }

    // Remove Feature
    await context.runScaffoldInProject([
      'remove',
      'feature',
      featureName,
      '--force',
    ]);

    FileAssertions.expectNoDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );
  }
}
