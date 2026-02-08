/// Help step for E2E tests.
library;

import '../step_base.dart';
import '../test_context.dart';

/// Step that tests help commands.
class HelpStep extends E2EStep {
  @override
  String get name => 'help';

  @override
  String get description => 'Help commands for all subcommands';

  @override
  List<String> get dependencies => [];

  @override
  List<String> get requiredSteps => ['build_cli'];

  @override
  Future<void> execute(E2ETestContext context) async {
    // Test main --help
    await context.logCommand(
      stepName: 'help',
      commandName: 'main_help',
      description: 'Main help output',
      args: ['--help'],
      workingDirectory: context.tempPath,
    );

    // Test help add
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_add',
      description: 'Help: add command',
      args: ['help', 'add'],
      workingDirectory: context.tempPath,
    );

    // Test help add feature
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_add_feature',
      description: 'Help: add feature',
      args: ['help', 'add', 'feature'],
      workingDirectory: context.tempPath,
    );

    // Test help add model
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_add_model',
      description: 'Help: add model',
      args: ['help', 'add', 'model'],
      workingDirectory: context.tempPath,
    );

    // Test help add repository
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_add_repository',
      description: 'Help: add repository',
      args: ['help', 'add', 'repository'],
      workingDirectory: context.tempPath,
    );

    // Test help add usecase
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_add_usecase',
      description: 'Help: add usecase',
      args: ['help', 'add', 'usecase'],
      workingDirectory: context.tempPath,
    );

    // Test help remove
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_remove',
      description: 'Help: remove command',
      args: ['help', 'remove'],
      workingDirectory: context.tempPath,
    );

    // Test help reset
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_reset',
      description: 'Help: reset command',
      args: ['help', 'reset'],
      workingDirectory: context.tempPath,
    );

    // Test help config
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_config',
      description: 'Help: config command',
      args: ['help', 'config'],
      workingDirectory: context.tempPath,
    );

    // Test help upgrade
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_upgrade',
      description: 'Help: upgrade command',
      args: ['help', 'upgrade'],
      workingDirectory: context.tempPath,
    );

    // Test help info
    await context.logCommand(
      stepName: 'help',
      commandName: 'help_info',
      description: 'Help: info command',
      args: ['help', 'info'],
      workingDirectory: context.tempPath,
    );
  }
}
