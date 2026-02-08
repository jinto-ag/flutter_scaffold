/// Reset step for E2E tests.
library;

import 'dart:io';

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests reset commands.
class ResetStep extends E2EStep {
  @override
  String get name => 'reset';

  @override
  String get description => 'Reset feature/project commands';

  @override
  List<String> get dependencies => ['lib/src/commands/reset_command.dart'];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'reset_test';

    // Create feature for reset testing
    await context.logCommand(
      stepName: 'reset',
      commandName: 'create_test_feature',
      description: 'Create feature for reset testing',
      args: ['add', 'feature', featureName, '--force'],
    );

    FileAssertions.expectDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );

    // Test reset feature --dry-run
    await context.logCommand(
      stepName: 'reset',
      commandName: 'reset_feature_dry_run',
      description: 'Reset feature dry-run',
      args: ['reset', 'feature', featureName, '--dry-run'],
    );

    // Feature should still exist after dry-run
    FileAssertions.expectDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );

    // Add some content to the feature to verify reset works
    final screenFile = File(
      '${context.projectPath}/lib/src/features/$featureName/presentation/screens/${featureName}_screen.dart',
    );
    final originalContent = screenFile.readAsStringSync();
    screenFile.writeAsStringSync(
      '$originalContent\n// Modified for reset test',
    );

    // Test reset feature --force
    await context.logCommand(
      stepName: 'reset',
      commandName: 'reset_feature_force',
      description: 'Reset feature with force',
      args: ['reset', 'feature', featureName, '--force'],
    );

    // Verify content was reset
    final resetContent = screenFile.readAsStringSync();
    if (resetContent.contains('// Modified for reset test')) {
      throw Exception('Reset should have reverted the file changes');
    }

    // Test reset project --dry-run (non-destructive)
    await context.logCommand(
      stepName: 'reset',
      commandName: 'reset_project_dry_run',
      description: 'Reset project dry-run (preview only)',
      args: ['reset', 'project', '--dry-run'],
    );

    // Project should still have features after dry-run
    FileAssertions.expectDir(
      '${context.projectPath}/lib/src/features/$featureName',
    );
  }
}
