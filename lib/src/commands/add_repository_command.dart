/// Add repository command for generating repository interfaces and implementations.
library;

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../services/dependency_service.dart';
import '../services/feature_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';
import '../utils/templates.dart';

/// Helper to extract project name from pubspec.yaml
String _getProjectName(String projectPath) {
  final context = TemplateContext.fromPubspec(
    p.join(projectPath, 'pubspec.yaml'),
  );
  return context['projectName'] as String? ?? 'app';
}

/// Subcommand to add a repository to a feature.
class AddRepositoryCommand extends Command<int> {
  AddRepositoryCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
    DependencyService? dependencyService,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _dependencyService = dependencyService ?? DependencyService() {
    argParser
      ..addOption(
        'feature',
        abbr: 'f',
        help: 'Target feature for the repository (required)',
        valueHelp: 'feature-name',
        mandatory: true,
      )
      ..addFlag(
        'include-datasources',
        help: 'Also generate remote and local datasource files',
        negatable: false,
      )
      ..addFlag(
        'remote-only',
        help: 'Only include remote datasource (no local caching)',
        negatable: false,
      )
      ..addFlag(
        'local-only',
        help: 'Only include local datasource (offline-first)',
        negatable: false,
      )
      ..addFlag(
        'include-mapper',
        help: 'Also generate a mapper class for entity/model conversion',
        negatable: false,
      )
      ..addFlag(
        'force',
        help: 'Overwrite existing repository files',
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
  final DependencyService _dependencyService;

  @override
  String get name => 'repository';

  @override
  String get description =>
      'Add a repository with optional datasources to a feature';

  @override
  String get invocation =>
      'flutter_scaffold add repository <name> --feature <feature> [--include-datasources]';

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      _logger.error('Repository name is required');
      _logger.info('Usage: $invocation');
      return 1;
    }

    final repositoryName = rest[0];
    final featureName = args.option('feature')!;
    final includeDatasources = args.flag('include-datasources');
    final remoteOnly = args.flag('remote-only');
    final localOnly = args.flag('local-only');
    final includeMapper = args.flag('include-mapper');
    final force = args.flag('force');
    final dryRun = args.flag('dry-run');

    // Validate flags
    if (remoteOnly && localOnly) {
      _logger.error('Cannot use both --remote-only and --local-only');
      return 1;
    }

    final projectPath = _fileUtils.currentDirectory;

    _logger.header('Adding Repository: $repositoryName to $featureName');

    try {
      // Check if feature exists
      if (!_featureService.featureExists(projectPath, featureName)) {
        _logger.error('Feature "$featureName" does not exist');
        _logger.info(
          'Create it first with: flutter_scaffold add feature $featureName',
        );
        return 1;
      }

      // Determine which datasources to include
      final hasRemote = includeDatasources && !localOnly;
      final hasLocal = includeDatasources && !remoteOnly;

      // Generate repository interface
      await _generateRepositoryInterface(
        projectPath: projectPath,
        featureName: featureName,
        repositoryName: repositoryName,
        force: force,
        dryRun: dryRun,
      );

      // Generate repository implementation
      await _generateRepositoryImpl(
        projectPath: projectPath,
        featureName: featureName,
        repositoryName: repositoryName,
        hasRemote: hasRemote,
        hasLocal: hasLocal,
        force: force,
        dryRun: dryRun,
      );

      // Generate datasources if requested
      if (hasRemote) {
        await _generateRemoteDatasource(
          projectPath: projectPath,
          featureName: featureName,
          repositoryName: repositoryName,
          force: force,
          dryRun: dryRun,
        );
      }

      if (hasLocal) {
        await _generateLocalDatasource(
          projectPath: projectPath,
          featureName: featureName,
          repositoryName: repositoryName,
          force: force,
          dryRun: dryRun,
        );
      }

      // Add required dependencies for datasources
      if (!dryRun && (hasRemote || hasLocal)) {
        _logger.info('Installing datasource dependencies...');
        final result = await _dependencyService.ensureFeatureDependencies(
          featureType: FeatureType.repository,
          projectPath: projectPath,
          showOutput: false,
        );
        if (!result.success) {
          _logger.warn(
            'Failed to add dependencies: ${result.failed.join(", ")}',
          );
        }
      }

      // Generate mapper if requested
      if (includeMapper) {
        await _generateMapper(
          projectPath: projectPath,
          featureName: featureName,
          repositoryName: repositoryName,
          force: force,
          dryRun: dryRun,
        );
      }

      _logger.success('Repository "$repositoryName" created successfully');
      if (!dryRun) {
        _logger.info('');
        _logger.info('Generated files:');
        _logger.info(
          '  • domain/repositories/${toSnakeCase(repositoryName)}_repository.dart',
        );
        _logger.info(
          '  • data/repositories/${toSnakeCase(repositoryName)}_repository_impl.dart',
        );
        if (hasRemote) {
          _logger.info(
            '  • data/datasources/${toSnakeCase(repositoryName)}_remote_datasource.dart',
          );
        }
        if (hasLocal) {
          _logger.info(
            '  • data/datasources/${toSnakeCase(repositoryName)}_local_datasource.dart',
          );
        }
        if (includeMapper) {
          _logger.info(
            '  • data/mappers/${toSnakeCase(repositoryName)}_mapper.dart',
          );
        }
        _logger.info('');
        _logger.info('Next steps:');
        _logger.info('  1. Register the repository with your DI container');
        _logger.info('  2. Implement any custom business methods');
      }

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }

  Future<void> _generateRepositoryInterface({
    required String projectPath,
    required String featureName,
    required String repositoryName,
    required bool force,
    required bool dryRun,
  }) async {
    final pascalName = toPascalCase(repositoryName);
    final snakeName = toSnakeCase(repositoryName);

    final repoDir = p.join(
      projectPath,
      'lib',
      'src',
      'features',
      featureName,
      'domain',
      'repositories',
    );
    final repoFile = p.join(repoDir, '${snakeName}_repository.dart');

    if (_fileUtils.fileExists(repoFile) && !force) {
      _logger.warn('Repository interface already exists, skipping');
      return;
    }

    if (dryRun) {
      _logger.info('[dry-run] Would create: $repoFile');
      return;
    }

    _fileUtils.createDirectory(repoDir);

    final loader = const TemplateLoader();
    final variables = {
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalName,
      'REPOSITORY_NAME': snakeName,
      'PASCAL_REPOSITORY_NAME': pascalName,
      'ENTITY_NAME': snakeName,
      'PASCAL_ENTITY_NAME': pascalName,
      'HAS_ENTITY': false, // Entity not auto-generated with repository
    };

    final content = loader.loadAndApplyTemplateOrThrow(
      'feature/repository.dart.template',
      variables,
    );

    _fileUtils.writeFile(repoFile, content);
    _logger.created(repoFile);
  }

  Future<void> _generateRepositoryImpl({
    required String projectPath,
    required String featureName,
    required String repositoryName,
    required bool hasRemote,
    required bool hasLocal,
    required bool force,
    required bool dryRun,
  }) async {
    final pascalName = toPascalCase(repositoryName);
    final snakeName = toSnakeCase(repositoryName);

    final implDir = p.join(
      projectPath,
      'lib',
      'src',
      'features',
      featureName,
      'data',
      'repositories',
    );
    final implFile = p.join(implDir, '${snakeName}_repository_impl.dart');

    if (_fileUtils.fileExists(implFile) && !force) {
      _logger.warn('Repository implementation already exists, skipping');
      return;
    }

    if (dryRun) {
      _logger.info('[dry-run] Would create: $implFile');
      return;
    }

    _fileUtils.createDirectory(implDir);

    final loader = const TemplateLoader();
    final projectName = _getProjectName(projectPath);
    final variables = {
      'projectName': projectName,
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalName,
      'REPOSITORY_NAME': snakeName,
      'PASCAL_REPOSITORY_NAME': pascalName,
      'ENTITY_NAME': snakeName,
      'PASCAL_ENTITY_NAME': pascalName,
      'HAS_ENTITY': false, // Entity not auto-generated with repository
      'HAS_REMOTE_DATASOURCE': hasRemote,
      'HAS_LOCAL_DATASOURCE': hasLocal,
      'HAS_NO_DATASOURCE': !hasRemote && !hasLocal,
    };

    final content = loader.loadAndApplyTemplateOrThrow(
      'feature/repository_impl.dart.template',
      variables,
    );

    _fileUtils.writeFile(implFile, content);
    _logger.created(implFile);
  }

  Future<void> _generateRemoteDatasource({
    required String projectPath,
    required String featureName,
    required String repositoryName,
    required bool force,
    required bool dryRun,
  }) async {
    final pascalName = toPascalCase(repositoryName);
    final snakeName = toSnakeCase(repositoryName);

    final dsDir = p.join(
      projectPath,
      'lib',
      'src',
      'features',
      featureName,
      'data',
      'datasources',
    );
    final dsFile = p.join(dsDir, '${snakeName}_remote_datasource.dart');

    if (_fileUtils.fileExists(dsFile) && !force) {
      _logger.warn('Remote datasource already exists, skipping');
      return;
    }

    if (dryRun) {
      _logger.info('[dry-run] Would create: $dsFile');
      return;
    }

    _fileUtils.createDirectory(dsDir);

    final loader = const TemplateLoader();
    final projectName = _getProjectName(projectPath);
    final variables = {
      'projectName': projectName,
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalName,
      'REPOSITORY_NAME': snakeName,
      'ENTITY_NAME': snakeName,
      'PASCAL_ENTITY_NAME': pascalName,
      'HAS_ENTITY': false,
    };

    final content = loader.loadAndApplyTemplateOrThrow(
      'feature/remote_datasource.dart.template',
      variables,
    );

    _fileUtils.writeFile(dsFile, content);
    _logger.created(dsFile);
  }

  Future<void> _generateLocalDatasource({
    required String projectPath,
    required String featureName,
    required String repositoryName,
    required bool force,
    required bool dryRun,
  }) async {
    final pascalName = toPascalCase(repositoryName);
    final snakeName = toSnakeCase(repositoryName);

    final dsDir = p.join(
      projectPath,
      'lib',
      'src',
      'features',
      featureName,
      'data',
      'datasources',
    );
    final dsFile = p.join(dsDir, '${snakeName}_local_datasource.dart');

    if (_fileUtils.fileExists(dsFile) && !force) {
      _logger.warn('Local datasource already exists, skipping');
      return;
    }

    if (dryRun) {
      _logger.info('[dry-run] Would create: $dsFile');
      return;
    }

    _fileUtils.createDirectory(dsDir);

    final loader = const TemplateLoader();
    final projectName = _getProjectName(projectPath);
    final variables = {
      'projectName': projectName,
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalName,
      'REPOSITORY_NAME': snakeName,
      'ENTITY_NAME': snakeName,
      'PASCAL_ENTITY_NAME': pascalName,
      'HAS_ENTITY': false,
    };

    final content = loader.loadAndApplyTemplateOrThrow(
      'feature/local_datasource.dart.template',
      variables,
    );

    _fileUtils.writeFile(dsFile, content);
    _logger.created(dsFile);
  }

  Future<void> _generateMapper({
    required String projectPath,
    required String featureName,
    required String repositoryName,
    required bool force,
    required bool dryRun,
  }) async {
    final pascalName = toPascalCase(repositoryName);
    final snakeName = toSnakeCase(repositoryName);

    final mapperDir = p.join(
      projectPath,
      'lib',
      'src',
      'features',
      featureName,
      'data',
      'mappers',
    );
    final mapperFile = p.join(mapperDir, '${snakeName}_mapper.dart');

    if (_fileUtils.fileExists(mapperFile) && !force) {
      _logger.warn('Mapper already exists, skipping');
      return;
    }

    if (dryRun) {
      _logger.info('[dry-run] Would create: $mapperFile');
      return;
    }

    _fileUtils.createDirectory(mapperDir);

    final loader = const TemplateLoader();
    final variables = {'FEATURE_NAME': snakeName, 'PASCAL_NAME': pascalName};

    final content = loader.loadAndApplyTemplateOrThrow(
      'feature/mapper.dart.template',
      variables,
    );

    _fileUtils.writeFile(mapperFile, content);
    _logger.created(mapperFile);
  }
}
