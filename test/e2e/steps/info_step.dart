/// Info step for E2E tests.
library;

import '../step_base.dart';
import '../test_context.dart';

/// Step that tests info, version, and verify commands.
class InfoStep extends E2EStep {
  @override
  String get name => 'info';

  @override
  String get description => 'Info, version, and verify commands';

  @override
  List<String> get dependencies => ['lib/src/commands/info_command.dart'];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    // Test info command
    await context.logCommand(
      stepName: 'info',
      commandName: 'info_command',
      description: 'Display project features information',
      args: ['info'],
    );

    // Test --version flag
    await context.logCommand(
      stepName: 'info',
      commandName: 'version_flag',
      description: 'Show CLI version',
      args: ['--version'],
      workingDirectory: context.tempPath,
    );

    // Test --verify flag
    await context.logCommand(
      stepName: 'info',
      commandName: 'verify_flag',
      description: 'Verify scaffold structure',
      args: ['--verify'],
    );
  }
}
