/// Configuration service for loading flutter_scaffold.yaml.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Configuration loaded from flutter_scaffold.yaml.
class ScaffoldConfig {
  const ScaffoldConfig({
    this.defaultOrg = 'com.example',
    this.defaultBranch = 'dev',
    this.initGit = true,
    this.installDeps = true,
    this.platforms,
    this.customDependencies,
    this.customDevDependencies,
    this.featureComponents,
  });

  /// Default organization for new projects.
  final String defaultOrg;

  /// Default git branch name.
  final String defaultBranch;

  /// Whether to initialize git by default.
  final bool initGit;

  /// Whether to install dependencies by default.
  final bool installDeps;

  /// Platforms to enable by default.
  final List<String>? platforms;

  /// Additional dependencies to install.
  final List<String>? customDependencies;

  /// Additional dev dependencies to install.
  final List<String>? customDevDependencies;

  /// Feature components to generate.
  final List<String>? featureComponents;

  /// Create config from YAML map.
  factory ScaffoldConfig.fromMap(Map<String, dynamic> map) {
    return ScaffoldConfig(
      defaultOrg: map['default_org'] as String? ?? 'com.example',
      defaultBranch: map['default_branch'] as String? ?? 'dev',
      initGit: map['init_git'] as bool? ?? true,
      installDeps: map['install_deps'] as bool? ?? true,
      platforms: _parseList(map['platforms']),
      customDependencies: _parseList(map['dependencies']),
      customDevDependencies: _parseList(map['dev_dependencies']),
      featureComponents: _parseList(map['feature_components']),
    );
  }

  static List<String>? _parseList(dynamic value) {
    if (value == null) return null;
    if (value is List) return value.map((e) => e.toString()).toList();
    return null;
  }
}

/// Service for loading and managing scaffold configuration.
class ConfigService {
  const ConfigService();

  /// Config file name.
  static const String configFileName = 'flutter_scaffold.yaml';

  /// Load configuration from project directory or user home.
  ///
  /// Priority: project config > user home config > defaults
  ScaffoldConfig loadConfig({String? projectPath}) {
    // Try project-level config first
    if (projectPath != null) {
      final projectConfig = _loadConfigFile(
        p.join(projectPath, configFileName),
      );
      if (projectConfig != null) return projectConfig;
    }

    // Try user home config
    final homeDir = Platform.environment['HOME'] ?? '';
    if (homeDir.isNotEmpty) {
      final homeConfig = _loadConfigFile(
        p.join(homeDir, '.config', 'flutter_scaffold', configFileName),
      );
      if (homeConfig != null) return homeConfig;
    }

    // Return defaults
    return const ScaffoldConfig();
  }

  /// Load config from a specific file path.
  ScaffoldConfig? _loadConfigFile(String path) {
    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final content = file.readAsStringSync();
      final map = _parseYaml(content);
      return ScaffoldConfig.fromMap(map);
    } catch (e) {
      return null;
    }
  }

  /// Simple YAML parser for flat key-value pairs.
  Map<String, dynamic> _parseYaml(String content) {
    final result = <String, dynamic>{};
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final colonIndex = trimmed.indexOf(':');
      if (colonIndex == -1) continue;

      final key = trimmed.substring(0, colonIndex).trim();
      var value = trimmed.substring(colonIndex + 1).trim();

      // Handle boolean
      if (value == 'true') {
        result[key] = true;
      } else if (value == 'false') {
        result[key] = false;
      }
      // Handle list (starts with [ or multi-line)
      else if (value.startsWith('[') && value.endsWith(']')) {
        final listContent = value.substring(1, value.length - 1);
        result[key] = listContent.split(',').map((e) => e.trim()).toList();
      }
      // Handle string
      else if (value.isNotEmpty) {
        result[key] = value;
      }
    }

    return result;
  }

  /// Check if config file exists.
  bool configExists({String? projectPath}) {
    if (projectPath != null) {
      if (File(p.join(projectPath, configFileName)).existsSync()) return true;
    }

    final homeDir = Platform.environment['HOME'] ?? '';
    if (homeDir.isNotEmpty) {
      final homePath = p.join(
        homeDir,
        '.config',
        'flutter_scaffold',
        configFileName,
      );
      if (File(homePath).existsSync()) return true;
    }

    return false;
  }

  /// Generate a sample config file content.
  String generateSampleConfig() {
    return '''# Flutter Scaffold Configuration
# Place this file at:
#   - Project root: flutter_scaffold.yaml
#   - User home: ~/.config/flutter_scaffold/flutter_scaffold.yaml

# Default organization for new projects
default_org: com.example

# Default git branch name
default_branch: dev

# Initialize git by default
init_git: true

# Install dependencies by default
install_deps: true

# Platforms to enable (comma-separated or list)
# platforms: [android, ios, web]

# Additional dependencies to install
# dependencies: [http, shared_preferences]

# Additional dev dependencies
# dev_dependencies: [mocktail]

# Feature components to generate
# feature_components: [screen, providers, entity, repository]
''';
  }
}
