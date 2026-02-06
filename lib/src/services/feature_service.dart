/// Feature management service.
library;

import '../core/constants.dart';
import '../core/errors.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';
import '../utils/templates.dart';
import 'build_runner_service.dart';

/// Information about a feature.
class FeatureInfo {
  const FeatureInfo({
    required this.name,
    required this.path,
    required this.fileCount,
    required this.dirCount,
    required this.size,
    required this.components,
  });

  final String name;
  final String path;
  final int fileCount;
  final int dirCount;
  final String size;
  final List<String> components;
}

/// Result of feature operation.
class FeatureResult {
  const FeatureResult({required this.dirsCreated, required this.filesCreated});

  final int dirsCreated;
  final int filesCreated;
}

/// Service for managing feature modules.
class FeatureService {
  FeatureService({
    ScaffoldLogger? logger,
    FileUtils? fileUtils,
    TemplateRegistry? templates,
    BuildRunnerService? buildRunnerService,
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _buildRunnerService = buildRunnerService ?? BuildRunnerService();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final BuildRunnerService _buildRunnerService;

  /// Create a TemplateRegistry with context from pubspec.yaml.
  TemplateRegistry _createTemplateRegistry(String projectPath) {
    final pubspecPath = _fileUtils.joinPath(projectPath, 'pubspec.yaml');
    final context = TemplateContext.fromPubspec(pubspecPath);
    return TemplateRegistry(context: context);
  }

  /// Get the features directory path.
  String _featuresPath(String projectPath) =>
      _fileUtils.joinPath(projectPath, srcDir, 'features');

  /// Get the path to a specific feature.
  String _featurePath(String projectPath, String featureName) =>
      _fileUtils.joinPath(_featuresPath(projectPath), featureName);

  /// Check if a feature exists.
  bool featureExists(String projectPath, String featureName) {
    return _fileUtils.directoryExists(_featurePath(projectPath, featureName));
  }

  /// List all features in the project.
  List<String> listFeatures(String projectPath) {
    final featuresPath = _featuresPath(projectPath);
    if (!_fileUtils.directoryExists(featuresPath)) {
      return [];
    }
    return _fileUtils.listSubdirectories(featuresPath);
  }

  /// Get detailed information about all features.
  List<FeatureInfo> getFeatureInfos(String projectPath) {
    final features = listFeatures(projectPath);
    return features.map((name) => getFeatureInfo(projectPath, name)).toList();
  }

  /// Get detailed information about a feature.
  FeatureInfo getFeatureInfo(String projectPath, String featureName) {
    final path = _featurePath(projectPath, featureName);
    final components = <String>[];

    // Check for key files
    if (_fileUtils.fileExists(
      _fileUtils.joinPath(
        path,
        'presentation/screens/${featureName}_screen.dart',
      ),
    )) {
      components.add('screen');
    }
    if (_fileUtils.fileExists(
      _fileUtils.joinPath(
        path,
        'presentation/providers/${featureName}_providers.dart',
      ),
    )) {
      components.add('providers');
    }
    if (_fileUtils.fileExists(
      _fileUtils.joinPath(path, 'domain/entities/${featureName}_entity.dart'),
    )) {
      components.add('entity');
    }
    if (_fileUtils.fileExists(
      _fileUtils.joinPath(
        path,
        'domain/repositories/${featureName}_repository.dart',
      ),
    )) {
      components.add('repository');
    }

    return FeatureInfo(
      name: featureName,
      path: path,
      fileCount: _fileUtils.countFiles(path),
      dirCount: _fileUtils.countDirectories(path),
      size: _fileUtils.getDirectorySize(path),
      components: components,
    );
  }

  /// Add a new feature module.
  Future<FeatureResult> addFeature({
    required String projectPath,
    required String featureName,
    bool force = false,
    bool dryRun = false,
    String? screenName,
  }) async {
    // Normalize the feature name
    final normalized = normalizeFeatureName(featureName);
    final featurePath = _featurePath(projectPath, normalized);

    // Check if exists
    if (featureExists(projectPath, normalized) && !force) {
      throw FeatureException(
        "Feature '$normalized' already exists at $featurePath\n"
        'Use --force to overwrite',
      );
    }

    // Create context-aware template registry
    final templates = _createTemplateRegistry(projectPath);

    var dirsCreated = 0;
    var filesCreated = 0;

    // Create directories
    _logger.section('Creating directories...');
    for (final dir in featureDirectories) {
      final fullPath = _fileUtils.joinPath(featurePath, dir);

      if (dryRun) {
        _logger.would('Create directory: $dir');
      } else {
        if (_fileUtils.createDirectory(fullPath)) {
          dirsCreated++;
        }
      }
    }

    // Create files
    _logger.section('Creating files...');
    final files = [
      (
        'presentation/screens/${screenName ?? normalized}_screen.dart',
        screenName != null
            ? templates.getScreenTemplate(screenName, normalized)
            : templates.getFeatureTemplate('screen', normalized),
      ),
      (
        'presentation/providers/${normalized}_providers.dart',
        templates.getFeatureTemplate('providers', normalized),
      ),
      (
        'domain/entities/${normalized}_entity.dart',
        templates.getFeatureTemplate('entity', normalized),
      ),
      (
        'domain/repositories/${normalized}_repository.dart',
        templates.getFeatureTemplate('repository', normalized),
      ),
    ];

    for (final (relativePath, content) in files) {
      if (content == null) continue;

      final fullPath = _fileUtils.joinPath(featurePath, relativePath);

      if (dryRun) {
        _logger.would('Create file: $relativePath');
      } else {
        if (_fileUtils.createFile(fullPath, content, force: force)) {
          _logger.created(relativePath);
          filesCreated++;
        } else {
          _logger.skipped(relativePath);
        }
      }
    }

    // Update routes if screen is specified
    if (screenName != null && !dryRun) {
      _updateRoutes(projectPath, screenName, normalized);
    }

    if (!dryRun) {
      // Run pub get if needed
      await _buildRunnerService.runPubGet(projectPath);

      // Run build runner if needed
      final buildResult = await _buildRunnerService.runBuildRunner(projectPath);
      if (!buildResult.success) {
        _logger.warn('Build runner completed with issues');
      }

      // Run verification
      final verificationResult = await _buildRunnerService.verifyCode(
        projectPath,
      );
      if (!verificationResult.success) {
        _logger.warn('Code verification found issues');
        if (verificationResult.issues.isNotEmpty) {
          for (final issue in verificationResult.issues) {
            _logger.warn('  • $issue');
          }
        }
      }
    }

    _logger.divider();
    _logger.success("Feature '$normalized' created!");
    _logger.info('  Directories: $dirsCreated');
    _logger.info('  Files: $filesCreated');
    if (screenName != null) {
      _logger.info('  Screen: $screenName');
      _logger.info('  Route: /$screenName');
    }
    _logger.info('');
    _logger.info('Feature structure:');
    _logger.info('  $featurePath/');
    _logger.info('  ├── data/{datasources, models, repositories}/');
    _logger.info('  ├── domain/{entities, repositories, usecases}/');
    _logger.info('  └── presentation/{providers, screens, widgets}/');

    return FeatureResult(dirsCreated: dirsCreated, filesCreated: filesCreated);
  }

  /// Remove a feature module.
  void removeFeature({
    required String projectPath,
    required String featureName,
    bool force = false,
    bool dryRun = false,
  }) {
    final normalized = normalizeFeatureName(featureName);
    final featurePath = _featurePath(projectPath, normalized);

    if (!featureExists(projectPath, normalized)) {
      throw FeatureException(
        "Feature '$normalized' does not exist at $featurePath",
      );
    }

    if (dryRun) {
      _logger.would('Remove directory: $featurePath/');
      return;
    }

    // Delete the feature directory
    _fileUtils.deleteDirectory(featurePath);
    _logger.success("Feature '$normalized' removed!");
  }

  /// Reset a feature to its initial state.
  void resetFeature({
    required String projectPath,
    required String featureName,
    bool force = false,
    bool dryRun = false,
  }) {
    final normalized = normalizeFeatureName(featureName);
    final featurePath = _featurePath(projectPath, normalized);

    if (!featureExists(projectPath, normalized)) {
      throw FeatureException(
        "Feature '$normalized' does not exist at $featurePath",
      );
    }

    final info = getFeatureInfo(projectPath, normalized);

    _logger.header('RESETTING Feature: $normalized');

    _logger.warn('This will COMPLETELY RESET the feature:');
    _logger.info('  • Remove ALL custom files and content');
    _logger.info('  • Remove the entire feature directory: $featurePath/');
    _logger.info('  • Recreate basic feature structure');

    _logger.info('');
    _logger.info('Current feature contains:');
    _logger.info('  • ${info.fileCount} files');
    _logger.info('  • ${info.dirCount} directories');

    if (dryRun) {
      _logger.would('Remove directory: $featurePath/');
      _logger.would('Recreate basic feature structure');
      return;
    }

    // Remove and recreate
    _fileUtils.deleteDirectory(featurePath);
    _logger.success('Removed existing feature directory');

    _logger.info('');
    _logger.info('Recreating basic feature structure...');
    addFeature(projectPath: projectPath, featureName: normalized, force: true);

    _logger.divider();
    _logger.success("Feature '$normalized' reset complete!");
    _logger.info('');
    _logger.success('✓ All custom content removed');
    _logger.success('✓ Basic structure recreated');
  }

  /// Update routes to include the new screen.
  void _updateRoutes(
    String projectPath,
    String screenName,
    String featureName,
  ) {
    final routesPath = _fileUtils.joinPath(
      projectPath,
      srcDir,
      'routing',
      'routes.dart',
    );
    final routerPath = _fileUtils.joinPath(
      projectPath,
      srcDir,
      'routing',
      'app_router.dart',
    );

    try {
      // Update routes.dart
      if (_fileUtils.fileExists(routesPath)) {
        _updateRoutesFile(routesPath, screenName);
        _logger.success('Updated routes.dart');
      }

      // Update app_router.dart
      if (_fileUtils.fileExists(routerPath)) {
        _updateRouterFile(routerPath, screenName, featureName);
        _logger.success('Updated app_router.dart');
      }
    } catch (e) {
      _logger.warn('Could not update routes: $e');
    }
  }

  /// Update the routes.dart file with new route definitions.
  void _updateRoutesFile(String routesPath, String screenName) {
    final content = _fileUtils.readFile(routesPath);

    // Add new route name and path
    final routeNameLine =
        "  static const String ${screenName}Name = '$screenName';";
    final routePathLine = "  static const String $screenName = '/$screenName';";

    // Find where to insert (before the closing brace of the class)
    final lines = content.split('\n');
    final insertIndex = lines.indexWhere((line) => line.contains('}')) - 1;

    if (insertIndex > 0) {
      lines.insert(insertIndex, routeNameLine);
      lines.insert(insertIndex + 1, routePathLine);

      final updatedContent = lines.join('\n');
      _fileUtils.writeFile(routesPath, updatedContent);
    }
  }

  /// Update the app_router.dart file with new route registration.
  void _updateRouterFile(
    String routerPath,
    String screenName,
    String featureName,
  ) {
    final content = _fileUtils.readFile(routerPath);

    final pascalScreenName = toPascalCase(screenName);

    // Add import
    final importLine =
        "import '../features/$featureName/presentation/screens/${screenName}_screen.dart';";

    // Add route configuration
    final routeConfig =
        '''      GoRoute(
        path: Routes.$screenName,
        name: Routes.${screenName}Name,
        builder: (context, state) => const ${pascalScreenName}Screen(),
      ),''';

    var updatedContent = content;

    // Add import after existing imports
    if (!content.contains(importLine)) {
      final importInsertPoint = content.lastIndexOf("import 'routes.dart';");
      if (importInsertPoint != -1) {
        updatedContent =
            '${updatedContent.substring(0, importInsertPoint)}$importLine\n${updatedContent.substring(importInsertPoint)}';
      }
    }

    // Add route to the routes array
    if (!content.contains("path: Routes.$screenName")) {
      final routesArrayStart = updatedContent.indexOf('routes: [');
      if (routesArrayStart != -1) {
        final routesArrayEnd = updatedContent.indexOf('],', routesArrayStart);
        if (routesArrayEnd != -1) {
          updatedContent =
              '${updatedContent.substring(0, routesArrayEnd)},\n$routeConfig${updatedContent.substring(routesArrayEnd)}';
        }
      }
    }

    if (updatedContent != content) {
      _fileUtils.writeFile(routerPath, updatedContent);
    }
  }
}
