/// Feature management service.
library;

import '../core/constants.dart';
import '../core/errors.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/string_utils.dart';
import '../utils/templates.dart';

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
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _templates = templates ?? const TemplateRegistry();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final TemplateRegistry _templates;

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
  FeatureResult addFeature({
    required String projectPath,
    required String featureName,
    bool force = false,
    bool dryRun = false,
  }) {
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
        'presentation/screens/${normalized}_screen.dart',
        _templates.getFeatureTemplate('screen', normalized),
      ),
      (
        'presentation/providers/${normalized}_providers.dart',
        _templates.getFeatureTemplate('providers', normalized),
      ),
      (
        'domain/entities/${normalized}_entity.dart',
        _templates.getFeatureTemplate('entity', normalized),
      ),
      (
        'domain/repositories/${normalized}_repository.dart',
        _templates.getFeatureTemplate('repository', normalized),
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

    _logger.divider();
    _logger.success("Feature '$normalized' created!");
    _logger.info('  Directories: $dirsCreated');
    _logger.info('  Files: $filesCreated');
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
}
