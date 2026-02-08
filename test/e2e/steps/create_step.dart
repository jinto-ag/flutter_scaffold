/// Create project step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that creates a new Flutter project using flutter_scaffold.
class CreateStep extends E2EStep {
  @override
  String get name => 'create';

  @override
  String get description => 'Creating new project';

  @override
  bool get alwaysRun => true;

  @override
  List<String> get dependencies => [
    'lib/src/commands/create_command.dart',
    'lib/src/templates/**/*.template',
    'lib/src/services/*.dart',
  ];

  @override
  List<String> get requiredSteps => ['build_cli'];

  @override
  Future<void> execute(E2ETestContext context) async {
    final projectName = context.uniqueProjectName('e2e_project');
    final projectPath = '${context.tempPath}/$projectName';

    await context.runner.runScaffold(['create', projectName, context.tempPath]);

    context.projectPath = projectPath;

    // Verify project structure
    FileAssertions.expectFile('$projectPath/pubspec.yaml');
    FileAssertions.expectFile('$projectPath/lib/main.dart');
    FileAssertions.expectDir('$projectPath/lib/src/core');
  }
}
