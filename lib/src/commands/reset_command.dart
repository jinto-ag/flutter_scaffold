/// Reset command for resetting project or features.
library;

import 'package:args/command_runner.dart';

import '../services/dependency_service.dart';
import '../services/feature_service.dart';
import '../services/scaffold_service.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';

/// Command to reset project or features to initial state.
class ResetCommand extends Command<int> {
  ResetCommand({
    ScaffoldLogger? logger,
    ScaffoldService? scaffoldService,
    FeatureService? featureService,
    DependencyService? dependencyService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _scaffoldService = scaffoldService ?? ScaffoldService(),
       _featureService = featureService ?? FeatureService(),
       _dependencyService = dependencyService ?? DependencyService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    addSubcommand(
      ResetProjectCommand(
        logger: _logger,
        scaffoldService: _scaffoldService,
        featureService: _featureService,
        dependencyService: _dependencyService,
        fileUtils: _fileUtils,
      ),
    );
    addSubcommand(
      ResetFeatureCommand(
        logger: _logger,
        featureService: _featureService,
        fileUtils: _fileUtils,
      ),
    );
  }

  final ScaffoldLogger _logger;
  final ScaffoldService _scaffoldService;
  final FeatureService _featureService;
  final DependencyService _dependencyService;
  final FileUtils _fileUtils;

  @override
  String get name => 'reset';

  @override
  String get description => 'Reset project or feature to initial state';
}

/// Subcommand to reset entire project.
class ResetProjectCommand extends Command<int> {
  ResetProjectCommand({
    ScaffoldLogger? logger,
    ScaffoldService? scaffoldService,
    FeatureService? featureService,
    DependencyService? dependencyService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _scaffoldService = scaffoldService ?? ScaffoldService(),
       _featureService = featureService ?? FeatureService(),
       _dependencyService = dependencyService ?? DependencyService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Skip confirmation prompts',
        negatable: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skip all confirmations (alias for --force)',
        negatable: false,
      )
      ..addFlag(
        'skip-deps',
        help: 'Skip code generation after reset',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview without making changes',
        negatable: false,
      );
  }

  final ScaffoldLogger _logger;
  final ScaffoldService _scaffoldService;
  final FeatureService _featureService;
  final DependencyService _dependencyService;
  final FileUtils _fileUtils;

  @override
  String get name => 'project';

  @override
  String get description => 'Reset entire project scaffold to initial state';

  @override
  Future<int> run() async {
    final args = argResults!;
    final force = args.flag('force') || args.flag('yes');
    final skipDeps = args.flag('skip-deps');
    final dryRun = args.flag('dry-run');

    final projectPath = _fileUtils.currentDirectory;

    // Validate project is scaffolded
    if (!_scaffoldService.isScaffoldedProject(projectPath)) {
      _logger.error('This project was not scaffolded with flutter_scaffold');
      _logger.info('Run "flutter_scaffold scaffold" first to initialize');
      return 1;
    }

    _logger.header('RESETTING ENTIRE PROJECT');

    _logger.error('⚠️  CRITICAL WARNING:');
    _logger.info(
      '  This will COMPLETELY RESET the entire clean architecture scaffold',
    );
    _logger.info('  • Remove ALL files in lib/src/ directory');
    _logger.info('  • Remove ALL features and custom code');
    _logger.info('  • Recreate basic clean architecture structure');
    _logger.error('  THIS IS EXTREMELY DESTRUCTIVE AND CANNOT BE UNDONE');
    _logger.info('');

    if (dryRun) {
      _logger.warn('DRY RUN - no changes will be made');
      _scaffoldService.resetScaffold(projectPath: projectPath, dryRun: true);
      _logger.success('Dry run complete');
      return 0;
    }

    try {
      // Multiple confirmations
      if (!force) {
        final prompt1 = _logger.prompt(
          "Type 'RESET-PROJECT' to confirm project reset",
        );
        if (prompt1 != 'RESET-PROJECT') {
          _logger.info('Project reset cancelled - confirmation not matched');
          return 0;
        }

        final confirmed = _logger.confirm(
          'Are you absolutely sure you want to reset the entire project?',
        );
        if (!confirmed) {
          _logger.info('Project reset cancelled');
          return 0;
        }
      }

      _logger.info('');
      _logger.info('Resetting entire project...');

      // Reset scaffold
      _scaffoldService.resetScaffold(projectPath: projectPath);

      // Recreate scaffold
      _logger.info('');
      _logger.info('Recreating clean architecture structure...');
      _scaffoldService.createScaffold(projectPath: projectPath, force: true);

      // Add home feature
      _logger.info('');
      _logger.info("Adding 'home' feature...");
      _featureService.addFeature(
        projectPath: projectPath,
        featureName: 'home',
        force: true,
        skipVerification: true, // Build runner runs after this
      );

      // Reset main.dart
      final projectName = _fileUtils.getProjectName(projectPath);
      if (projectName != null) {
        _logger.info('');
        _scaffoldService.updateMainDart(
          projectPath: projectPath,
          projectName: projectName,
          force: true,
        );
      }

      // Run code generation
      if (!skipDeps) {
        await _dependencyService.runBuildRunner(projectPath: projectPath);
        await _dependencyService.runAnalyze(projectPath: projectPath);
      } else {
        _logger.info('Skipping code generation (--skip-deps)');
      }

      _logger.divider();
      _logger.success('Project reset complete!');
      _logger.info('');
      _logger.success('✓ All clean architecture content removed');
      _logger.success('✓ Basic structure recreated');
      _logger.success('✓ Home feature added');

      if (!skipDeps) {
        _logger.success('✓ Code generation complete');
        _logger.success('✓ Code analysis passed');
      } else {
        _logger.warn('! Code generation skipped (--skip-deps)');
        _logger.info('');
        _logger.info('Next steps:');
        _logger.info(
          "  Run 'dart run build_runner build --delete-conflicting-outputs'",
        );
      }

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }
}

/// Subcommand to reset a feature.
class ResetFeatureCommand extends Command<int> {
  ResetFeatureCommand({
    ScaffoldLogger? logger,
    FeatureService? featureService,
    FileUtils? fileUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _featureService = featureService ?? FeatureService(),
       _fileUtils = fileUtils ?? const FileUtils() {
    argParser
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Skip confirmation prompts',
        negatable: false,
      )
      ..addFlag(
        'yes',
        abbr: 'y',
        help: 'Skip all confirmations (alias for --force)',
        negatable: false,
      )
      ..addFlag(
        'dry-run',
        help: 'Preview without making changes',
        negatable: false,
      );
  }

  final ScaffoldLogger _logger;
  final FeatureService _featureService;
  final FileUtils _fileUtils;

  @override
  String get name => 'feature';

  @override
  String get description => 'Reset a feature module to initial state';

  @override
  String get invocation => 'flutter_scaffold reset feature <name>';

  @override
  Future<int> run() async {
    final args = argResults!;
    final rest = args.rest;

    if (rest.isEmpty) {
      _logger.error('Feature name is required');
      _logger.info('Usage: $invocation');
      return 1;
    }

    final featureName = rest[0];
    final force = args.flag('force') || args.flag('yes');
    final dryRun = args.flag('dry-run');

    final projectPath = _fileUtils.currentDirectory;

    try {
      _featureService.resetFeature(
        projectPath: projectPath,
        featureName: featureName,
        force: force,
        dryRun: dryRun,
      );

      return 0;
    } catch (e) {
      _logger.error(e.toString());
      return 1;
    }
  }
}
