/// Create command for new Flutter projects with scaffold.
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import '../services/dependency_service.dart';
import '../services/feature_service.dart';
import '../services/flutter_service.dart';
import '../services/git_service.dart';
import '../services/scaffold_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to create a new Flutter project with clean architecture scaffold.
class CreateCommand extends Command<int> {
  CreateCommand({
    ScaffoldLogger? logger,
    FlutterService? flutterService,
    ScaffoldService? scaffoldService,
    FeatureService? featureService,
    DependencyService? dependencyService,
    GitService? gitService,
  }) : _logger = logger ?? ScaffoldLogger(),
       _flutterService = flutterService ?? FlutterService(),
       _scaffoldService = scaffoldService ?? ScaffoldService(),
       _featureService = featureService ?? FeatureService(),
       _dependencyService = dependencyService ?? DependencyService(),
       _gitService = gitService ?? GitService() {
    argParser
      ..addOption(
        'org',
        abbr: 'o',
        help: 'Organization name (e.g., com.example)',
        defaultsTo: 'com.example',
      )
      ..addOption('description', abbr: 'd', help: 'Project description')
      ..addOption(
        'platforms',
        abbr: 'p',
        help: 'Platforms to enable (comma-separated)',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing directory',
        negatable: false,
      )
      ..addFlag(
        'skip-deps',
        help: 'Skip dependency installation',
        negatable: false,
      )
      ..addFlag(
        'init-git',
        help: 'Initialize git with dev branch and initial commit',
        defaultsTo: true,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview without creating files',
        negatable: false,
      );
  }

  final ScaffoldLogger _logger;
  final FlutterService _flutterService;
  final ScaffoldService _scaffoldService;
  final FeatureService _featureService;
  final DependencyService _dependencyService;
  final GitService _gitService;

  @override
  String get name => 'create';

  @override
  String get description =>
      'Create a new Flutter project with clean architecture scaffold';

  @override
  String get invocation => 'flutter_scaffold create <project_name> [location]';

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      _logger.error('Project name is required');
      _logger.info('Usage: $invocation');
      return 1;
    }

    final projectName = rest[0];
    final location = rest.length > 1 ? rest[1] : 'cwd';

    final force = args.flag('force');
    final skipDeps = args.flag('skip-deps');
    final dryRun = args.flag('dry-run');
    final org = args.option('org');
    final desc = args.option('description');
    final platformsStr = args.option('platforms');
    final platforms = platformsStr?.split(',').map((s) => s.trim()).toList();

    if (dryRun) {
      _logger.warn('DRY RUN - no changes will be made');
      _logger.info('');
      _logger.would('Create Flutter project: $projectName');
      _logger.would('Location: $location');
      _logger.would('Apply clean architecture scaffold');
      _logger.would('Add home feature');
      if (!skipDeps) {
        _logger.would('Install dependencies');
        _logger.would('Run code generation');
      }
      _logger.info('');
      _logger.success('Dry run complete');
      return 0;
    }

    try {
      // Create Flutter project
      final projectPath = await _flutterService.createProject(
        projectName: projectName,
        location: location,
        org: org,
        description: desc,
        platforms: platforms,
        force: force,
      );

      // Copy scaffold script (for backwards compatibility)
      _copyScaffoldScript(projectPath);

      // Apply scaffold
      _logger.info('');
      _logger.info('Applying clean architecture scaffold...');
      _scaffoldService.createScaffold(projectPath: projectPath, force: force);

      // Add home feature (skip verification - it runs in setupProject after deps)
      _logger.info('');
      _logger.info("Adding 'home' feature...");
      await _featureService.addFeature(
        projectPath: projectPath,
        featureName: 'home',
        force: force,
        skipVerification: true, // Deps not installed yet
      );

      // Install dependencies
      if (!skipDeps) {
        _logger.info('');
        await _dependencyService.setupProject(projectPath: projectPath);
      } else {
        _logger.info('Skipping dependency installation (--skip-deps)');
      }

      // Initialize git if requested
      final initGit = args.flag('init-git');
      if (initGit) {
        _logger.info('');
        await _gitService.initializeGit(
          projectPath: projectPath,
          projectName: projectName,
        );
      }

      // Summary
      _logger.divider();
      _logger.success(
        "Project '$projectName' created with clean architecture!",
      );
      _logger.info('');
      _logger.info('Project Details:');
      _logger.info('  Location: $projectPath');
      _logger.info('  Name: $projectName');
      _logger.info('');

      if (!skipDeps) {
        _logger.success('✓ Dependencies installed');
        _logger.success('✓ Code generation complete');
        _logger.success('✓ Code analysis passed');
        _logger.info('');
        _logger.info('Next steps:');
        _logger.info('  1. cd $projectPath');
        _logger.info('  2. flutter run');
      } else {
        _logger.warn('! Dependencies not installed (--skip-deps)');
        _logger.info('');
        _logger.info('Next steps:');
        _logger.info('  1. cd $projectPath');
        _logger.info('  2. flutter_scaffold --install-deps');
        _logger.info('  3. flutter run');
      }

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }

  void _copyScaffoldScript(String projectPath) {
    final fileUtils = const FileUtils();
    final scriptPath = fileUtils.joinPath(projectPath, 'scaffold.sh');

    // Find the original script
    final currentDir = Directory.current.path;
    final sourcePath = fileUtils.joinPath(currentDir, 'scaffold.sh');

    if (fileUtils.fileExists(sourcePath)) {
      fileUtils.copyFile(sourcePath, scriptPath);
      // Make executable
      Process.runSync('chmod', ['+x', scriptPath]);
      _logger.info('Copied scaffold.sh to project');
    }
  }
}
