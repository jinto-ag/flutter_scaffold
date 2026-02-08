/// Config step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests config commands.
class ConfigStep extends E2EStep {
  @override
  String get name => 'config';

  @override
  String get description => 'Config command (init/show/set)';

  @override
  List<String> get dependencies => ['lib/src/commands/config_command.dart'];

  @override
  List<String> get requiredSteps => ['build_cli'];

  @override
  Future<void> execute(E2ETestContext context) async {
    // Test 1: Show config (default)
    await context.logCommand(
      stepName: 'config',
      commandName: 'show_config_default',
      description: 'Show default configuration',
      args: ['config', 'show'],
      workingDirectory: context.tempPath,
    );

    // Test 2: Config init
    await context.logCommand(
      stepName: 'config',
      commandName: 'config_init',
      description: 'Initialize local config file',
      args: ['config', 'init', '--force'],
      workingDirectory: context.tempPath,
    );

    // Verify config file created
    FileAssertions.expectFile('${context.tempPath}/flutter_scaffold.yaml');

    // Test 3: Show config after init
    await context.logCommand(
      stepName: 'config',
      commandName: 'show_config_after_init',
      description: 'Show configuration after init',
      args: ['config', 'show'],
      workingDirectory: context.tempPath,
    );
  }
}
