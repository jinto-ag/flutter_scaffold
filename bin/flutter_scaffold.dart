import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:flutter_scaffold/flutter_scaffold.dart';

/// Main entry point for the Flutter Scaffold CLI.
Future<void> main(List<String> arguments) async {
  final logger = ScaffoldLogger();

  // Create command runner
  final runner = CommandRunner<int>(executableName, description)
    ..addCommand(CreateCommand())
    ..addCommand(InitCommand())
    ..addCommand(AddCommand())
    ..addCommand(RemoveCommand())
    ..addCommand(ResetCommand())
    ..addCommand(InfoCommand())
    ..addCommand(ConfigCommand());

  // Add global options
  runner.argParser
    ..addFlag('version', abbr: 'v', help: 'Print the version', negatable: false)
    ..addFlag(
      'install-deps',
      help: 'Install dependencies (for use in existing projects)',
      negatable: false,
    )
    ..addFlag('verify', help: 'Verify scaffold structure', negatable: false);

  try {
    // Handle version flag
    if (arguments.contains('-v') || arguments.contains('--version')) {
      logger.info('flutter_scaffold version $appVersion');
      exit(0);
    }

    // Handle global flags when run without a command
    if (arguments.isEmpty || arguments.every((arg) => arg.startsWith('-'))) {
      final args = runner.argParser.parse(arguments);

      // Handle --install-deps
      if (args.flag('install-deps')) {
        final projectPath = const FileUtils().currentDirectory;
        final dependencyService = DependencyService();

        logger.header('Installing Dependencies');
        await dependencyService.setupProject(projectPath: projectPath);
        exit(0);
      }

      // Handle --verify
      if (args.flag('verify')) {
        final projectPath = const FileUtils().currentDirectory;
        final scaffoldService = ScaffoldService();

        logger.header('Verifying Scaffold Structure');
        final valid = scaffoldService.verifyScaffold(projectPath: projectPath);
        exit(valid ? 0 : 1);
      }

      // No command provided - run scaffold by default
      if (arguments.isEmpty) {
        logger.header('Flutter Clean Architecture Scaffold v$appVersion');
        logger.info('');
        logger.info('Usage: $executableName <command> [arguments]');
        logger.info('');
        logger.info('Available commands:');
        logger.info('  create    Create a new Flutter project with scaffold');
        logger.info('  init      Initialize scaffold in existing project');
        logger.info('  add       Add new modules (e.g., add feature <name>)');
        logger.info('  remove    Remove modules (e.g., remove feature <name>)');
        logger.info('  reset     Reset project or feature to initial state');
        logger.info('  info      Display project features information');
        logger.info('  config    Manage configuration (init, show)');
        logger.info('');
        logger.info('Global options:');
        logger.info('  --version, -v     Print the version');
        logger.info('  --install-deps    Install dependencies');
        logger.info('  --verify          Verify scaffold structure');
        logger.info('  --help, -h        Show help');
        logger.info('');
        logger.info(
          "Run '$executableName help <command>' for more information.",
        );
        exit(0);
      }
    }

    // Run the command
    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (e) {
    logger.error(e.message);
    logger.info('');
    logger.info(e.usage);
    exit(64);
  } catch (e) {
    logger.error(e.toString());
    exit(1);
  }
}
