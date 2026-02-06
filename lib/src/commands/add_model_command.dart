/// Add model command for adding data models to features.
library;

import 'package:args/command_runner.dart';

import '../services/model_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to add a model to an existing feature.
class AddModelCommand extends Command<int> {
  AddModelCommand({
    ScaffoldLogger? logger,
    ModelService? modelService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _modelService = modelService ?? ModelService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing model',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview without creating files',
        negatable: false,
      )
      ..addFlag(
        'json-serializable',
        help: 'Use JSON serialization',
        negatable: false,
      )
      ..addFlag(
        'freezed',
        help: 'Use Freezed for immutable classes',
        negatable: false,
      )
      ..addMultiOption(
        'field',
        help: 'Model fields (e.g., "id:int", "name:String")',
        valueHelp: 'type:name',
      );
  }

  final ScaffoldLogger _logger;
  final ModelService _modelService;
  final FileUtils _fileUtils;

  @override
  String get name => 'model';

  @override
  String get description => 'Add a data model to a feature';

  @override
  String get invocation => 'flutter_scaffold add model <feature> <model>';

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.length < 2) {
      _logger.error('Feature name and model name are required');
      _logger.info('Usage: $invocation');
      _logger.info('');
      _logger.info('Examples:');
      _logger.info('  flutter_scaffold add model user profile');
      _logger.info(
        '  flutter_scaffold add model user user --json-serializable',
      );
      _logger.info('  flutter_scaffold add model user user --freezed');
      _logger.info(
        '  flutter_scaffold add model user user --field "id:int" --field "name:String" --field "email:String"',
      );
      return 1;
    }

    final featureName = rest[0];
    final modelName = rest[1];
    final force = args.flag('force');
    final dryRun = args.flag('dry-run');
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

    final projectPath = _fileUtils.currentDirectory;

    _logger.header('Adding Model: $modelName to Feature: $featureName');

    try {
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

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }
}
