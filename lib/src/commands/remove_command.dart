/// Remove command for removing features.
library;

import 'package:args/command_runner.dart';

import '../services/feature_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to remove modules from the project.
class RemoveCommand extends Command<int> {
  RemoveCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    addSubcommand(
      RemoveFeatureCommand(
        logger: _logger,
        featureService: _featureService,
        fileUtils: _fileUtils,
      ),
    );
  }

  final ScaffoldLogger _logger;
  final FeatureService _featureService;
  final FileUtils _fileUtils;

  @override
  String get name => 'remove';

  @override
  String get description => 'Remove modules from the project';
}

/// Subcommand to remove a feature.
class RemoveFeatureCommand extends Command<int> {
  RemoveFeatureCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Skip confirmation prompt',
        negatable: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skip all confirmations (alias for --force)',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview without deleting files',
        negatable: false,
      );
  }

  final ScaffoldLogger _logger;
  final FeatureService _featureService;
  final FileUtils _fileUtils;

  @override
  String get name => 'feature';

  @override
  String get description => 'Remove a feature module';

  @override
  String get invocation => 'flutter_scaffold remove feature <name>';

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      _logger.error('Feature name is required');
      _logger.info('Usage: $invocation');
      return 1;
    }

    final featureName = rest[0];
    final force = args.flag('force') || args.flag('yes');
    final dryRun = args.flag('dry-run');

    final projectPath = _fileUtils.currentDirectory;

    _logger.header('Removing Feature: $featureName');

    try {
      // Confirm deletion
      if (!force && !dryRun) {
        final confirmed = _logger.confirm(
          'Are you sure you want to remove feature "$featureName"?',
        );
        if (!confirmed) {
          _logger.info('Cancelled');
          return 0;
        }
      }

      _featureService.removeFeature(
        projectPath: projectPath,
        featureName: featureName,
        force: force,
        dryRun: dryRun,
      );

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }
}
