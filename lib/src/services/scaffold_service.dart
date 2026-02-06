/// Scaffold service for creating project structure.
library;

import '../core/constants.dart';
import '../core/errors.dart';
import '../core/version.dart';
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
       _fileUtils = fileUtils ?? const FileUtils();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;

  /// Create a TemplateRegistry with context from pubspec.yaml.
  TemplateRegistry _createTemplateRegistry(String projectPath) {
    final pubspecPath = _fileUtils.joinPath(projectPath, 'pubspec.yaml');
    final context = TemplateContext.fromPubspec(pubspecPath);
    return TemplateRegistry(context: context);
  }

  /// Check if a project was scaffolded with flutter_scaffold.
  bool isScaffoldedProject(String projectPath) {
    final markerPath = _fileUtils.joinPath(projectPath, scaffoldMarkerDir);
    return _fileUtils.directoryExists(markerPath);
  }

  /// Create the scaffold marker directory with metadata.
  void _createMarkerDirectory(String projectPath, {bool dryRun = false}) {
    final markerPath = _fileUtils.joinPath(projectPath, scaffoldMarkerDir);

    if (dryRun) {
      _logger.would('Create scaffold marker: $scaffoldMarkerDir/');
      return;
    }

    _fileUtils.createDirectory(markerPath);

    // Create config file with metadata
    final configPath = _fileUtils.joinPath(markerPath, 'config.json');
    final projectName = _fileUtils.getProjectName(projectPath) ?? 'unknown';
    final config =
        '''
{
  "scaffolded_at": "${DateTime.now().toIso8601String()}",
  "project_name": "$projectName",
  "flutter_scaffold_version": "$appVersion"
}
''';
    _fileUtils.createFile(configPath, config, force: true);
    _logger.success('Created scaffold marker directory');
  }

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

    // Create context-aware template registry
    final templates = _createTemplateRegistry(projectPath);

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
      final content = templates.getTemplate(file);

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

    // Create git hook files
    _logger.section('Creating git hooks...');
    for (final file in hookFiles) {
      final fullPath = _fileUtils.joinPath(projectPath, file);
      final content = templates.getTemplate(file);

      if (content == null) {
        _logger.warn('No template found for: $file');
        continue;
      }

      if (dryRun) {
        _logger.would('Create hook: $file');
      } else {
        if (_fileUtils.createFile(fullPath, content, force: force)) {
          _logger.created(file);
          filesCreated++;
          // Make hook executable
          _fileUtils.makeExecutable(fullPath);
        } else {
          _logger.skipped(file);
          filesSkipped++;
        }
      }
    }

    // Create test files (project name substitution is now handled by TemplateContext)
    _logger.section('Creating unit tests...');
    for (final file in testFiles) {
      final fullPath = _fileUtils.joinPath(projectPath, file);
      final content = templates.getTemplate(file);

      if (content == null) {
        _logger.warn('No template found for: $file');
        continue;
      }

      if (dryRun) {
        _logger.would('Create test: $file');
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

    // Create scaffold marker directory
    _createMarkerDirectory(projectPath, dryRun: dryRun);

    // Generate VSCode config
    if (!dryRun) {
      _generateVSCodeConfig(projectPath, force: force);
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
  /// [projectName] - Name of the project for package import.
  /// [force] - If true, overwrite even if already updated.
  /// [dryRun] - If true, only show what would be done.
  bool updateMainDart({
    required String projectPath,
    required String projectName,
    bool force = false,
    bool dryRun = false,
  }) {
    final mainPath = _fileUtils.joinPath(projectPath, mainDartPath);

    // Create context-aware template registry with project name
    final templates = _createTemplateRegistry(projectPath);
    final context = templates.context.withSpecifics({
      'projectName': projectName,
    });
    final contextAwareTemplates = TemplateRegistry(context: context);

    // Get template content with variables applied
    final template = contextAwareTemplates.getTemplate(mainDartPath);
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

  /// Generate VSCode extensions configuration.
  void _generateVSCodeConfig(String projectPath, {bool force = false}) {
    final vscodeDir = _fileUtils.joinPath(projectPath, '.vscode');
    final extensionsPath = _fileUtils.joinPath(vscodeDir, 'extensions.json');

    if (!_fileUtils.directoryExists(vscodeDir)) {
      _fileUtils.createDirectory(vscodeDir);
    }

    const configContent = '''
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "jinto-ag.flutter-scaffold"
  ]
}
''';

    if (_fileUtils.createFile(extensionsPath, configContent, force: force)) {
      _logger.info('Created .vscode/extensions.json');
    } else {
      _logger.skipped('.vscode/extensions.json');
    }
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
