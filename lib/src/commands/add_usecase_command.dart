/// Add usecase command for generating use case classes.
library;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../services/feature_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';
import '../utils/templates.dart';

/// Subcommand to add a use case to a feature.
class AddUsecaseCommand extends Command<int> {
  AddUsecaseCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature for the use case (required)',
        valueHelp: 'feature-name',
        mandatory: true,
      )
      ..addFlag(
        'with-params',
        help: 'Generate a Params class for the use case',
        negatable: true,
        defaultsTo: true,
      )
      ..addOption(
        'return-type',
        help: 'Return type of the use case',
        valueHelp: 'type',
        defaultsTo: 'void',
      )
      ..addOption(
        'description',
        abbr: 'd',
        help: 'Description of what the use case does',
        valueHelp: 'description',
      )
      ..addFlag('force', help: 'Overwrite existing use case', negatable: false)
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
  String get name => 'usecase';

  @override
  String get description => 'Add a new use case to a feature';

  @override
  String get invocation =>
      'flutter_scaffold add usecase <name> --feature <feature>';

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      _logger.error('Use case name is required');
      _logger.info('Usage: $invocation');
      return 1;
    }

    final usecaseName = rest[0];
    final featureName = args.option('feature')!;
    final withParams = args.flag('with-params');
    final returnType = args.option('return-type') ?? 'void';
    final description = args.option('description') ?? 'performing an operation';
    final force = args.flag('force');
    final dryRun = args.flag('dry-run');

    final projectPath = _fileUtils.currentDirectory;

    _logger.header('Adding Use Case: $usecaseName to $featureName');

    try {
      // Check if feature exists
      if (!_featureService.featureExists(projectPath, featureName)) {
        _logger.error('Feature "$featureName" does not exist');
        _logger.info(
          'Create it first with: flutter_scaffold add feature $featureName',
        );
        return 1;
      }

      // Generate the use case file
      final result = await _addUsecase(
        projectPath: projectPath,
        featureName: featureName,
        usecaseName: usecaseName,
        withParams: withParams,
        returnType: returnType,
        description: description,
        force: force,
        dryRun: dryRun,
      );

      if (result) {
        _logger.success('Use case "$usecaseName" created successfully');
        if (!dryRun) {
          _logger.info('');
          _logger.info('Next steps:');
          _logger.info('  1. Implement the business logic in _execute()');
          if (withParams) {
            _logger.info(
              '  2. Add parameters to ${toPascalCase(usecaseName)}Params',
            );
          }
          _logger.info('  3. Register the use case with your DI container');
        }
        return 0;
      } else {
        return 1;
      }
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }

  Future<bool> _addUsecase({
    required String projectPath,
    required String featureName,
    required String usecaseName,
    required bool withParams,
    required String returnType,
    required String description,
    required bool force,
    required bool dryRun,
  }) async {
    final pascalFeatureName = toPascalCase(featureName);
    final pascalUsecaseName = toPascalCase(usecaseName);
    final snakeUsecaseName = toSnakeCase(usecaseName);

    // Determine output path
    final usecasesDir = p.join(
      projectPath,
      'lib',
      'src',
      'features',
      featureName,
      'domain',
      'usecases',
    );
    final usecaseFile = p.join(usecasesDir, '${snakeUsecaseName}_usecase.dart');

    // Check if file exists
    if (_fileUtils.fileExists(usecaseFile) && !force) {
      _logger.error('Use case "$usecaseName" already exists');
      _logger.info('Use --force to overwrite');
      return false;
    }

    if (dryRun) {
      _logger.info('[dry-run] Would create: $usecaseFile');
      return true;
    }

    // Create usecases directory if needed
    _fileUtils.createDirectory(usecasesDir);

    // Load and render template
    final loader = const TemplateLoader();
    final variables = {
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalFeatureName,
      'USECASE_NAME': snakeUsecaseName,
      'PASCAL_USECASE_NAME': pascalUsecaseName,
      'USECASE_DESCRIPTION': description,
      'RETURN_TYPE': returnType,
      'HAS_PARAMS': withParams,
    };

    final content = loader.loadAndApplyTemplateOrThrow(
      'feature/usecase.dart.template',
      variables,
    );

    // Write file
    _fileUtils.writeFile(usecaseFile, content);
    _logger.created(usecaseFile);

    return true;
  }
}
