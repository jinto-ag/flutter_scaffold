/// Config command for managing flutter_scaffold.yaml.
library;

import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import '../services/config_service.dart';
import '../utils/logger.dart';

/// Command to manage scaffold configuration.
class ConfigCommand extends Command<int> {
  ConfigCommand({ScaffoldLogger? logger, ConfigService? configService})
    : _logger = logger ?? ScaffoldLogger(),
      _configService = configService ?? const ConfigService() {
    addSubcommand(_ConfigInitCommand(logger: _logger));
    addSubcommand(
      _ConfigShowCommand(logger: _logger, configService: _configService),
    );
  }

  final ScaffoldLogger _logger;
  final ConfigService _configService;

  @override
  String get name => 'config';

  @override
  String get description => 'Manage scaffold configuration';
}

/// Subcommand to initialize config file.
class _ConfigInitCommand extends Command<int> {
  _ConfigInitCommand({ScaffoldLogger? logger})
    : _logger = logger ?? ScaffoldLogger() {
    argParser.addFlag(
      'global',
      abbr: 'g',
      help: 'Create config in user home (~/.config/flutter_scaffold/)',
      negatable: false,
    );
    argParser.addFlag(
      'force',
      abbr: 'f',
      help: 'Overwrite existing config file',
      negatable: false,
    );
  }

  final ScaffoldLogger _logger;

  @override
  String get name => 'init';

  @override
  String get description => 'Create a sample flutter_scaffold.yaml config file';

  @override
  Future<int> run() async {
    final args = argResults!;
    final global = args.flag('global');
    final force = args.flag('force');

    final configService = const ConfigService();
    final content = configService.generateSampleConfig();

    String configPath;
    if (global) {
      final homeDir = Platform.environment['HOME'] ?? '';
      if (homeDir.isEmpty) {
        _logger.error('Could not determine home directory');
        return 1;
      }
      configPath = p.join(
        homeDir,
        '.config',
        'flutter_scaffold',
        ConfigService.configFileName,
      );
    } else {
      configPath = ConfigService.configFileName;
    }

    final file = File(configPath);

    if (file.existsSync() && !force) {
      _logger.error('Config file already exists: $configPath');
      _logger.info('Use --force to overwrite');
      return 1;
    }

    // Create parent directories if needed
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    file.writeAsStringSync(content);
    _logger.success('Created config file: $configPath');
    _logger.info('');
    _logger.info('Edit this file to customize scaffold behavior:');
    _logger.info('  - default_org: Organization for new projects');
    _logger.info('  - default_branch: Git branch name');
    _logger.info('  - init_git: Auto-initialize git');
    _logger.info('  - platforms: Default platforms to enable');

    return 0;
  }
}

/// Subcommand to show current config.
class _ConfigShowCommand extends Command<int> {
  _ConfigShowCommand({ScaffoldLogger? logger, ConfigService? configService})
    : _logger = logger ?? ScaffoldLogger(),
      _configService = configService ?? const ConfigService();

  final ScaffoldLogger _logger;
  final ConfigService _configService;

  @override
  String get name => 'show';

  @override
  String get description => 'Show current configuration';

  @override
  Future<int> run() async {
    final config = _configService.loadConfig(
      projectPath: Directory.current.path,
    );

    _logger.header('Current Configuration');
    _logger.info('');
    _logger.info('default_org: ${config.defaultOrg}');
    _logger.info('default_branch: ${config.defaultBranch}');
    _logger.info('init_git: ${config.initGit}');
    _logger.info('install_deps: ${config.installDeps}');
    _logger.info('state_management: ${config.stateManagement}');
    _logger.info('routing: ${config.routing}');
    _logger.info('data_class: ${config.dataClass}');
    _logger.info('linting: ${config.linting}');

    if (config.templatePaths != null && config.templatePaths!.isNotEmpty) {
      _logger.info('template_paths:');
      config.templatePaths!.forEach((k, v) {
        _logger.info('  $k: $v');
      });
    }

    if (config.platforms != null) {
      _logger.info('platforms: ${config.platforms!.join(', ')}');
    }
    if (config.customDependencies != null) {
      _logger.info('dependencies: ${config.customDependencies!.join(', ')}');
    }
    if (config.customDevDependencies != null) {
      _logger.info(
        'dev_dependencies: ${config.customDevDependencies!.join(', ')}',
      );
    }

    _logger.info('');

    if (_configService.configExists(projectPath: Directory.current.path)) {
      _logger.success('✓ Config file found');
    } else {
      _logger.info('No config file found (using defaults)');
      _logger.info("Run 'flutter_scaffold config init' to create one");
    }

    return 0;
  }
}
