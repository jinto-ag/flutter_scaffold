/// Scaffold service for creating project structure.
library;

import '../core/constants.dart';
import '../core/errors.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/templates.dart';

/// Result of scaffold operation.
class ScaffoldResult {
  const ScaffoldResult({
    required this.dirsCreated,
    required this.filesCreated,
    required this.filesSkipped,
  });

  final int dirsCreated;
  final int filesCreated;
  final int filesSkipped;
}

/// Service for scaffolding Flutter project structure.
class ScaffoldService {
  ScaffoldService({
    ScaffoldLogger? logger,
    FileUtils? fileUtils,
    TemplateRegistry? templates,
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _templates = templates ?? const TemplateRegistry();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final TemplateRegistry _templates;

  /// Create the scaffold structure in the given project directory.
  ///
  /// [projectPath] - Path to the Flutter project root.
  /// [force] - If true, overwrite existing files.
  /// [dryRun] - If true, only show what would be created.
  ScaffoldResult createScaffold({
    required String projectPath,
    bool force = false,
    bool dryRun = false,
  }) {
    // Validate project
    if (!_fileUtils.isFlutterProject(projectPath)) {
      throw ProjectValidationException(
        'Not a Flutter project (no pubspec.yaml) at: $projectPath',
      );
    }

    var dirsCreated = 0;
    var filesCreated = 0;
    var filesSkipped = 0;

    // Create directories
    _logger.section('Creating core directories...');
    for (final dir in coreDirectories) {
      final fullPath = _fileUtils.joinPath(projectPath, dir);

      if (dryRun) {
        if (!_fileUtils.directoryExists(fullPath)) {
          _logger.would('Create directory: $dir');
        }
      } else {
        if (_fileUtils.createDirectory(fullPath)) {
          dirsCreated++;
        }
      }
    }

    // Create files
    _logger.section('Creating core files...');
    for (final file in coreFiles) {
      final fullPath = _fileUtils.joinPath(projectPath, file);
      final content = _templates.getTemplate(file);

      if (content == null) {
        _logger.warn('No template found for: $file');
        continue;
      }

      if (dryRun) {
        if (_fileUtils.fileExists(fullPath) && !force) {
          _logger.skipped(file);
        } else {
          _logger.would('Create file: $file');
        }
      } else {
        if (_fileUtils.createFile(fullPath, content, force: force)) {
          _logger.created(file);
          filesCreated++;
        } else {
          _logger.skipped(file);
          filesSkipped++;
        }
      }
    }

    return ScaffoldResult(
      dirsCreated: dirsCreated,
      filesCreated: filesCreated,
      filesSkipped: filesSkipped,
    );
  }

  /// Verify that all scaffold files and directories exist.
  ///
  /// Returns true if all items exist.
  bool verifyScaffold({required String projectPath}) {
    var allExist = true;

    _logger.section('Directories:');
    for (final dir in coreDirectories) {
      final fullPath = _fileUtils.joinPath(projectPath, dir);
      if (_fileUtils.directoryExists(fullPath)) {
        _logger.success('  ✓ $dir');
      } else {
        _logger.error('  ✗ $dir (missing)');
        allExist = false;
      }
    }

    _logger.section('Files:');
    for (final file in coreFiles) {
      final fullPath = _fileUtils.joinPath(projectPath, file);
      if (_fileUtils.fileExists(fullPath)) {
        _logger.success('  ✓ $file');
      } else {
        _logger.error('  ✗ $file (missing)');
        allExist = false;
      }
    }

    return allExist;
  }

  /// Reset the entire scaffold to initial state.
  ///
  /// WARNING: This is destructive and cannot be undone.
  void resetScaffold({required String projectPath, bool dryRun = false}) {
    final srcPath = _fileUtils.joinPath(projectPath, srcDir);

    if (dryRun) {
      _logger.would('Remove directory: $srcDir/');
      _logger.would('Recreate clean architecture structure');
      return;
    }

    // Remove entire src directory
    if (_fileUtils.directoryExists(srcPath)) {
      _fileUtils.deleteDirectory(srcPath);
      _logger.success('Removed existing clean architecture structure');
    }
  }

  /// Update main.dart to use the generated App widget with ProviderScope.
  ///
  /// [projectPath] - Path to the Flutter project root.
  /// [force] - If true, overwrite even if already updated.
  /// [dryRun] - If true, only show what would be done.
  bool updateMainDart({
    required String projectPath,
    bool force = false,
    bool dryRun = false,
  }) {
    final mainPath = _fileUtils.joinPath(projectPath, mainDartPath);

    // Get template content
    final template = _templates.getTemplate(mainDartPath);
    if (template == null) {
      _logger.warn('No template found for main.dart');
      return false;
    }

    if (dryRun) {
      _logger.would('Update main.dart with ProviderScope');
      return true;
    }

    // Check if already updated (simple check for ProviderScope)
    if (_fileUtils.fileExists(mainPath) && !force) {
      final content = _readFile(mainPath);
      if (content != null && content.contains('ProviderScope')) {
        _logger.skipped('main.dart (already using ProviderScope)');
        return false;
      }
    }

    // Write the updated main.dart
    if (_fileUtils.createFile(mainPath, template, force: true)) {
      _logger.success('Updated main.dart with ProviderScope');
      return true;
    }

    return false;
  }

  /// Read file content safely.
  String? _readFile(String path) {
    try {
      return _fileUtils.fileExists(path) ? _fileUtils.readFile(path) : null;
    } catch (e) {
      return null;
    }
  }
}
