/// Add command for adding features, models, repositories, and use cases.
library;

import 'package:args/command_runner.dart';

import '../services/feature_service.dart';
import '../services/model_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import 'add_model_command.dart';
import 'add_repository_command.dart';
import 'add_usecase_command.dart';

/// Command to add new modules to the project.
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
    addSubcommand(AddModelCommand(logger: _logger, fileUtils: _fileUtils));
    addSubcommand(
      AddRepositoryCommand(
        logger: _logger,
        featureService: _featureService,
        fileUtils: _fileUtils,
      ),
    );
    addSubcommand(
      AddUsecaseCommand(
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
    ModelService? modelService,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _modelService = modelService ?? ModelService() {
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
      )
      ..addOption(
        'screen',
        help: 'Create a screen for the feature (e.g., about, profile)',
        valueHelp: 'screen-name',
      )
      ..addOption(
        'model',
        help: 'Create a model along with the feature (e.g., user, profile)',
        valueHelp: 'model-name',
      )
      ..addFlag(
        'json-serializable',
        help: 'Use JSON serialization for the model',
        negatable: false,
      )
      ..addFlag('freezed', help: 'Use Freezed for the model', negatable: false)
      ..addMultiOption(
        'field',
        help: 'Model fields (e.g., "id:int", "name:String")',
        valueHelp: 'type:name',
      );
  }

  final ScaffoldLogger _logger;
  final FeatureService _featureService;
  final FileUtils _fileUtils;
  final ModelService _modelService;

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
    final screenName = args.option('screen');
    final modelName = args.option('model');
    final useJsonSerializable = args.flag('json-serializable');
    final useFreezed = args.flag('freezed');
    final fields = args.multiOption('field');

    // Validate options
    if (useJsonSerializable && useFreezed) {
      _logger.error(
        'Cannot use both --json-serializable and --freezed together',
      );
      return 1;
    }

    if ((useJsonSerializable || useFreezed) && modelName == null) {
      _logger.error('--json-serializable or --freezed requires --model option');
      return 1;
    }

    if (fields.isNotEmpty && modelName == null) {
      _logger.error('--field option requires --model option');
      return 1;
    }

    final projectPath = _fileUtils.currentDirectory;

    _logger.header('Adding Feature: $featureName');

    try {
      await _featureService.addFeature(
        projectPath: projectPath,
        featureName: featureName,
        force: force,
        dryRun: dryRun,
        screenName: screenName,
      );

      // Create model if specified
      if (modelName != null && !dryRun) {
        _logger.section('Creating model: $modelName');
        await _modelService.addModel(
          projectPath: projectPath,
          featureName: featureName,
          modelName: modelName,
          fields: fields,
          useJsonSerializable: useJsonSerializable,
          useFreezed: useFreezed,
          force: force,
          dryRun: dryRun,
        );
      }

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }
}
