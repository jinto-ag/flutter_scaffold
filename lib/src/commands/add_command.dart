/// Add command for adding features.
library;

import 'package:args/command_runner.dart';

import '../services/feature_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to add a new feature module.
class AddCommand extends Command<int> {
  AddCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    addSubcommand(
      AddFeatureCommand(
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
  String get name => 'add';

  @override
  String get description => 'Add new modules to the project';
}

/// Subcommand to add a feature.
class AddFeatureCommand extends Command<int> {
  AddFeatureCommand({
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
        help: 'Overwrite existing feature',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview without creating files',
        negatable: false,
      );
  }

  final ScaffoldLogger _logger;
  final FeatureService _featureService;
  final FileUtils _fileUtils;

  @override
  String get name => 'feature';

  @override
  String get description => 'Add a new feature module';

  @override
  String get invocation => 'flutter_scaffold add feature <name>';

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
    final force = args.flag('force');
    final dryRun = args.flag('dry-run');

    final projectPath = _fileUtils.currentDirectory;

    _logger.header('Adding Feature: $featureName');

    try {
      _featureService.addFeature(
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
