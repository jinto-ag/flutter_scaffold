/// Init step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests init command on existing Flutter project.
class InitStep extends E2EStep {
  @override
  String get name => 'init';

  @override
  String get description => 'Init command on existing project';

  @override
  bool get alwaysRun => true;

  @override
  List<String> get dependencies => [
    'lib/src/commands/init_command.dart',
    'lib/src/templates/**/*.template',
  ];

  @override
  List<String> get requiredSteps => ['build_cli'];

  @override
  Future<void> execute(E2ETestContext context) async {
    final projectName = context.uniqueProjectName('e2e_existing');
    final projectPath = '${context.tempPath}/$projectName';

    // Create a standard Flutter project first
    context.logger.info('Creating standard Flutter project...');
    await context.runner.runFlutter([
      'create',
      projectName,
    ], workingDirectory: context.tempPath);

    // Run flutter_scaffold init with various flags
    context.logger.info('Running flutter_scaffold init...');
    await context.runner.runScaffold([
      'init',
      '--force',
      '--no-git',
      '--no-backup',
    ], workingDirectory: projectPath);

    // Verify scaffold structure
    FileAssertions.expectDir('$projectPath/lib/src/core');
    FileAssertions.expectFile('$projectPath/flutter_scaffold');
    FileAssertions.expectFile('$projectPath/.vscode/extensions.json');
  }
}
