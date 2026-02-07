/// Init command for applying scaffold to existing Flutter projects.
library;

import 'package:args/command_runner.dart';

import '../services/backup_service.dart';
import '../services/config_service.dart';
import '../services/dependency_service.dart';
import '../services/distribution_service.dart';
import '../services/feature_service.dart';
import '../services/git_service.dart';
import '../services/history_service.dart';
import '../services/sandbox_service.dart';
import '../services/scaffold_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to initialize clean architecture scaffold in an existing Flutter project.
///
/// This is the recommended command for adding scaffold to existing projects.
/// It includes safety features like automated backups and sandboxed verification.
class InitCommand extends Command<int> {
  InitCommand({
    ScaffoldLogger? logger,
    ConfigService? configService,
    ScaffoldService? scaffoldService,
    FeatureService? featureService,
    DependencyService? dependencyService,
    GitService? gitService,
    BackupService? backupService,
    HistoryService? historyService,
    SandboxService? sandboxService,
    DistributionService? distributionService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _configService = configService ?? const ConfigService(),
       _scaffoldService = scaffoldService ?? ScaffoldService(),
       _featureService = featureService ?? FeatureService(),
       _dependencyService = dependencyService ?? DependencyService(),
       _gitService = gitService ?? GitService(),
       _backupService = backupService ?? BackupService(),
       _historyService = historyService ?? HistoryService(),
       _sandboxService = sandboxService ?? SandboxService(),
       _distributionService = distributionService ?? DistributionService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing files',
        negatable: false,
      )
      ..addFlag(
        'install-deps',
        help: 'Install dependencies after scaffolding',
        negatable: false,
      )
      ..addFlag(
        'init-git',
        help: 'Initialize git with dev branch and initial commit',
        defaultsTo: true,
      )
      ..addFlag(
        'verify',
        help: 'Verify scaffold structure after creation',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview changes using sandboxed verification',
        negatable: false,
      )
      ..addFlag(
        'no-sandbox',
        help: 'Skip sandboxed verification (faster, less safe)',
        negatable: false,
      )
      ..addFlag(
        'no-backup',
        help: 'Skip automated backup (not recommended)',
        negatable: false,
      )
      ..addFlag(
        'no-git',
        help: 'Skip auto-commit after successful operation',
        negatable: false,
      )
      ..addOption(
        'state-management',
        allowed: ['riverpod', 'bloc', 'provider', 'none'],
        help: 'State management solution to use',
      )
      ..addOption(
        'routing',
        allowed: ['go_router', 'auto_route', 'none'],
        help: 'Routing solution to use',
      )
      ..addOption(
        'data-class',
        allowed: ['freezed', 'json_serializable', 'none'],
        help: 'Data class generation to use',
      )
      ..addFlag('lint', help: 'Enable linting', defaultsTo: true);
  }

  final ScaffoldLogger _logger;
  final ConfigService _configService;
  final ScaffoldService _scaffoldService;
  final FeatureService _featureService;
  final DependencyService _dependencyService;
  final GitService _gitService;
  final BackupService _backupService;
  final HistoryService _historyService;
  final SandboxService _sandboxService;
  final DistributionService _distributionService;
  final FileUtils _fileUtils;

  @override
  String get name => 'init';

  @override
  String get description =>
      'Initialize clean architecture scaffold in an existing Flutter project';

  @override
  Future<int> run() async {
    final args = argResults!;
    final force = args.flag('force');
    final installDeps = args.flag('install-deps');
    final initGit = args.flag('init-git');
    final verify = args.flag('verify');
    final dryRun = args.flag('dry-run');
    final noSandbox = args.flag('no-sandbox');
    final noBackup = args.flag('no-backup');
    final noGit = args.flag('no-git');

    final projectPath = _fileUtils.currentDirectory;
    final projectName = _fileUtils.basename(projectPath);

    // Load configuration
    final config = _configService.loadConfig(projectPath: projectPath);

    // Resolve stack preferences (Flag > Config > Default)
    // Note: Config object already handles (Local > Global > Default)
    final stateManagement =
        args['state-management'] as String? ?? config.stateManagement;
    final routing = args['routing'] as String? ?? config.routing;
    final dataClass = args['data-class'] as String? ?? config.dataClass;
    final linting = args.wasParsed('lint') ? args.flag('lint') : config.linting;

    _logger.header('Flutter Clean Architecture Scaffold');
    _logger.info('Stack Configuration:');
    _logger.info('  State Management: $stateManagement');
    _logger.info('  Routing: $routing');
    _logger.info('  Data Class: $dataClass');
    _logger.info('  Linting: $linting');
    _logger.info('');

    if (dryRun) {
      _logger.warn('DRY RUN - changes will be verified in sandbox');
    }
    if (force) {
      _logger.warn('FORCE - existing files will be overwritten');
    }

    try {
      // Use sandboxed verification for dry-run (unless --no-sandbox)
      if (dryRun && !noSandbox) {
        return await _runWithSandbox(projectPath, projectName, force);
      }

      // Create backup before making changes (unless --no-backup)
      String? backupId;
      if (!noBackup) {
        final existingFiles = _getExistingScaffoldFiles(projectPath);
        if (existingFiles.isNotEmpty) {
          final backup = await _backupService.backup(
            projectPath: projectPath,
            paths: existingFiles,
            operationName: 'init',
          );
          backupId = backup.backupId;
        }
      }

      // Execute scaffold
      final filesCreated = await _executeScaffold(
        projectPath: projectPath,
        projectName: projectName,
        force: force,
      );

      // Record in history
      await _historyService.record(
        projectPath: projectPath,
        operation: 'init',
        description: 'Initialized clean architecture scaffold',
        filesAffected: filesCreated,
        backupId: backupId,
      );

      _logger.divider();
      _logger.success('Scaffold complete!');

      // Install deps if requested
      if (installDeps) {
        _logger.info('');
        await _dependencyService.setupProject(projectPath: projectPath);
      }

      // Initialize git if requested
      if (initGit) {
        _logger.info('');
        await _gitService.initializeGit(
          projectPath: projectPath,
          projectName: projectName,
          dryRun: false,
        );
      }

      // Auto-commit if not disabled
      if (!noGit && !initGit) {
        await _autoCommit(projectPath);
      }

      // Verify if requested
      if (verify) {
        _logger.info('');
        _scaffoldService.verifyScaffold(projectPath: projectPath);
      }

      // Next steps
      _printNextSteps(installDeps);

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }

  /// Run the scaffold in a sandbox for verification.
  Future<int> _runWithSandbox(
    String projectPath,
    String projectName,
    bool force,
  ) async {
    final result = await _sandboxService.executeWithVerification(
      projectPath: projectPath,
      operation: (sandboxPath) async {
        await _executeScaffold(
          projectPath: sandboxPath,
          projectName: projectName,
          force: force,
        );
      },
      verifySuccess: (sandboxPath) async {
        // Verify by checking structure exists
        return _scaffoldService.verifyScaffold(projectPath: sandboxPath);
      },
      applyOnSuccess: false, // Dry-run only
    );

    switch (result) {
      case SandboxSuccess(:final changedFiles, :final sandboxPath):
        _logger.divider();
        _logger.success('Dry run verification passed');
        _logger.info('');
        _logger.info('Files that would be created/modified:');
        for (final file in changedFiles.take(20)) {
          _logger.info('  + $file');
        }
        if (changedFiles.length > 20) {
          _logger.info('  ... and ${changedFiles.length - 20} more');
        }
        _logger.info('');
        _logger.info('Run without --dry-run to apply these changes.');
        _sandboxService.cleanup(sandboxPath);
        return 0;

      case SandboxFailure(:final error, :final sandboxPath):
        _logger.divider();
        _logger.error('Dry run verification failed: $error');
        _logger.info('');
        _logger.info('Sandbox preserved at: $sandboxPath');
        _logger.info('Inspect and debug, then run:');
        _logger.info('  rm -rf $sandboxPath');
        return 1;
    }
  }

  /// Execute the scaffold operation.
  Future<List<String>> _executeScaffold({
    required String projectPath,
    required String projectName,
    required bool force,
  }) async {
    final filesCreated = <String>[];

    // Create scaffold
    _scaffoldService.createScaffold(
      projectPath: projectPath,
      force: force,
      dryRun: false,
    );
    filesCreated.add('lib/src/core/');
    filesCreated.add('lib/src/shared/');

    // Add home feature
    _logger.info('');
    _logger.info("Adding 'home' feature...");
    try {
      await _featureService.addFeature(
        projectPath: projectPath,
        featureName: 'home',
        force: force,
      );
      filesCreated.add('lib/src/features/home/');
    } catch (e) {
      if (e.toString().contains('already exists')) {
        _logger.warn("Feature 'home' already exists (skipping)");
      } else {
        rethrow;
      }
    }

    // Update main.dart to use the App widget
    _logger.info('');
    _scaffoldService.updateMainDart(
      projectPath: projectPath,
      projectName: projectName,
      force: force,
      dryRun: false,
    );
    filesCreated.add('lib/main.dart');

    // Bundle artifacts
    _logger.info('');
    await _bundleArtifacts(projectPath);
    filesCreated.add('.flutter_scaffold/dist/');
    filesCreated.add('flutter_scaffold');

    return filesCreated;
  }

  /// Bundle CLI artifacts and wrapper script
  Future<void> _bundleArtifacts(String projectPath) async {
    _logger.info("Bundling CLI artifacts...");
    await _distributionService.bundleArtifacts(targetDir: projectPath);
    await _distributionService.generateWrapper(targetDir: projectPath);
  }

  /// Get list of existing scaffold files that may need backup.
  List<String> _getExistingScaffoldFiles(String projectPath) {
    final paths = <String>[];
    final srcPath = _fileUtils.joinPath(projectPath, 'lib', 'src');

    if (_fileUtils.directoryExists(srcPath)) {
      paths.add('lib/src');
    }

    final mainPath = _fileUtils.joinPath(projectPath, 'lib', 'main.dart');
    if (_fileUtils.fileExists(mainPath)) {
      paths.add('lib/main.dart');
    }

    return paths;
  }

  /// Auto-commit changes using conventional commit format.
  Future<void> _autoCommit(String projectPath) async {
    final gitDir = _fileUtils.joinPath(projectPath, '.git');
    if (!_fileUtils.directoryExists(gitDir)) {
      return; // Not a git repo
    }

    await _gitService.commitChanges(
      projectPath: projectPath,
      type: 'feat',
      scope: 'scaffold',
      message: 'initialize clean architecture scaffold',
      emoji: '🏗️',
    );
  }

  void _printNextSteps(bool installDeps) {
    _logger.info('');
    _logger.info('Next steps:');
    if (!installDeps) {
      _logger.info(
        "  1. Run 'flutter_scaffold --install-deps' to add dependencies",
      );
    }
    _logger.info('  2. Implement app.dart with MaterialApp.router');
    _logger.info('  3. Add your features in lib/src/features/');
  }
}
