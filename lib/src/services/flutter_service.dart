/// Flutter project creation service.
library;

import '../core/errors.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/process_utils.dart';
import '../utils/string_utils.dart';

/// Service for creating new Flutter projects.
class FlutterService {
  FlutterService({
    ScaffoldLogger? logger,
    FileUtils? fileUtils,
    ProcessUtils? processUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _processUtils = processUtils ?? ProcessUtils();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final ProcessUtils _processUtils;

  /// Create a new Flutter project.
  Future<String> createProject({
    required String projectName,
    required String location,
    String? org,
    String? description,
    List<String>? platforms,
    List<String> extraArgs = const [],
    bool force = false,
    bool showOutput = true,
  }) async {
    // Validate project name
    final normalized = normalizeProjectName(projectName);

    // Resolve project path
    final projectPath = _resolveProjectPath(normalized, location);

    // Check if exists
    if (_fileUtils.directoryExists(projectPath) && !force) {
      throw ProjectValidationException(
        "Directory '$projectPath' already exists\n"
        'Use --force to overwrite',
      );
    }

    // Remove if force
    if (_fileUtils.directoryExists(projectPath) && force) {
      _logger.warn("Removing existing directory '$projectPath'...");
      _fileUtils.deleteDirectory(projectPath);
    }

    // Ensure parent exists
    final parentDir = _fileUtils.dirname(projectPath);
    if (!_fileUtils.directoryExists(parentDir)) {
      _fileUtils.createDirectory(parentDir);
      _logger.info('Created parent directory: $parentDir');
    }

    _logger.header('Creating Flutter Project: $normalized');
    _logger.info('Location: $projectPath');
    _logger.info('');

    // Create Flutter project
    _logger.info('Creating Flutter project...');
    final result = await _processUtils.createProject(
      projectPath,
      org: org ?? 'com.example',
      description: description,
      platforms: platforms,
      extraArgs: extraArgs,
      showOutput: showOutput,
    );

    if (!result.success) {
      throw ProcessException(
        'Failed to create Flutter project',
        exitCode: result.exitCode,
      );
    }

    _logger.success('Flutter project created successfully!');
    return projectPath;
  }

  /// Resolve the project path based on location.
  String _resolveProjectPath(String projectName, String location) {
    final cwd = _fileUtils.currentDirectory;

    if (location.isEmpty || location == 'cwd' || location == './') {
      return _fileUtils.joinPath(cwd, projectName);
    }

    if (location == '..') {
      return _fileUtils.joinPath(cwd, '..', projectName);
    }

    if (location.startsWith('../')) {
      // Relative parent path - location may or may not include project name
      if (location.endsWith(projectName)) {
        return _fileUtils.normalize(_fileUtils.joinPath(cwd, location));
      }
      return _fileUtils.normalize(
        _fileUtils.joinPath(cwd, location, projectName),
      );
    }

    if (location.startsWith('./')) {
      // Relative current path
      return _fileUtils.normalize(
        _fileUtils.joinPath(cwd, location.substring(2), projectName),
      );
    }

    if (location.startsWith('/')) {
      // Absolute path - append project name
      return _fileUtils.joinPath(location, projectName);
    }

    // Relative path
    return _fileUtils.normalize(
      _fileUtils.joinPath(cwd, location, projectName),
    );
  }

  /// Check if Flutter is installed and available.
  Future<bool> isFlutterInstalled() async {
    try {
      final result = await _processUtils.flutter([
        '--version',
      ], showOutput: false);
      return result.success;
    } catch (e) {
      return false;
    }
  }
}
