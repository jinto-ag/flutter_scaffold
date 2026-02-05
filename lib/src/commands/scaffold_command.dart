/// Scaffold command for existing Flutter projects.
library;

import 'package:args/command_runner.dart';

import '../services/dependency_service.dart';
import '../services/feature_service.dart';
import '../services/git_service.dart';
import '../services/scaffold_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to apply scaffold to an existing Flutter project.
class ScaffoldCommand extends Command<int> {
  ScaffoldCommand({
    ScaffoldLogger? logger,
    ScaffoldService? scaffoldService,
    FeatureService? featureService,
    DependencyService? dependencyService,
    GitService? gitService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _scaffoldService = scaffoldService ?? ScaffoldService(),
       _featureService = featureService ?? FeatureService(),
       _dependencyService = dependencyService ?? DependencyService(),
       _gitService = gitService ?? GitService(),
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
        help: 'Preview without creating files',
        negatable: false,
      );
  }

  final ScaffoldLogger _logger;
  final ScaffoldService _scaffoldService;
  final FeatureService _featureService;
  final DependencyService _dependencyService;
  final GitService _gitService;
  final FileUtils _fileUtils;

  @override
  String get name => 'scaffold';

  @override
  String get description =>
      'Apply clean architecture scaffold to existing Flutter project';

  @override
  Future<int> run() async {
    final args = argResults!;
    final force = args.flag('force');
    final installDeps = args.flag('install-deps');
    final initGit = args.flag('init-git');
    final verify = args.flag('verify');
    final dryRun = args.flag('dry-run');

    final projectPath = _fileUtils.currentDirectory;
    final projectName = _fileUtils.basename(projectPath);

    _logger.header('Flutter Clean Architecture Scaffold');

    if (dryRun) {
      _logger.warn('DRY RUN - no changes will be made');
    }
    if (force) {
      _logger.warn('FORCE - existing files will be overwritten');
    }

    try {
      // Create scaffold
      _scaffoldService.createScaffold(
        projectPath: projectPath,
        force: force,
        dryRun: dryRun,
      );

      // Add home feature
      if (!dryRun) {
        _logger.info('');
        _logger.info("Adding 'home' feature...");
        _featureService.addFeature(
          projectPath: projectPath,
          featureName: 'home',
          force: force,
        );

        // Update main.dart to use the App widget
        _logger.info('');
        _scaffoldService.updateMainDart(
          projectPath: projectPath,
          projectName: projectName,
          force: force,
          dryRun: dryRun,
        );
      }

      _logger.divider();

      if (dryRun) {
        _logger.success('Dry run complete');
      } else {
        _logger.success('Scaffold complete!');
      }

      // Install deps if requested
      if (installDeps && !dryRun) {
        _logger.info('');
        await _dependencyService.setupProject(projectPath: projectPath);
      }

      // Initialize git if requested
      if (initGit && !dryRun) {
        _logger.info('');
        await _gitService.initializeGit(
          projectPath: projectPath,
          projectName: projectName,
          dryRun: dryRun,
        );
      }

      // Verify if requested
      if (verify && !dryRun) {
        _logger.info('');
        _scaffoldService.verifyScaffold(projectPath: projectPath);
      }

      // Next steps
      _logger.info('');
      _logger.info('Next steps:');
      if (!installDeps) {
        _logger.info(
          "  1. Run 'flutter_scaffold --install-deps' to add dependencies",
        );
      }
      _logger.info('  2. Implement app.dart with MaterialApp.router');
      _logger.info('  3. Add your features in lib/src/features/');

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }
}
