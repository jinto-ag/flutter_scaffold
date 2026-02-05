/// Template system for scaffold file generation.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'string_utils.dart';

/// Exception thrown when a template is not found.
class TemplateNotFoundException implements Exception {
  const TemplateNotFoundException(this.templatePath);

  final String templatePath;

  @override
  String toString() => 'Template not found: $templatePath';
}

/// Template loading utilities.
class TemplateLoader {
  const TemplateLoader({this.templatesPath});

  /// Path to templates directory. If null, uses package path.
  final String? templatesPath;

  /// Get the templates directory path.
  String getTemplatesDirectory() {
    if (templatesPath != null) {
      return templatesPath!;
    }

    // Find package root from current script
    final scriptPath = Platform.script.toFilePath();
    final packageRoot = _findPackageRoot(scriptPath);

    if (packageRoot != null) {
      return p.join(packageRoot, 'lib', 'src', 'templates');
    }

    // Fallback: try current directory
    final cwd = Directory.current.path;
    final templatesDir = p.join(cwd, 'lib', 'src', 'templates');
    if (Directory(templatesDir).existsSync()) {
      return templatesDir;
    }

    throw StateError(
      'Could not find templates directory. '
      'Ensure you are running from the package root or templates are installed.',
    );
  }

  /// Find package root by looking for pubspec.yaml
  String? _findPackageRoot(String startPath) {
    var current = Directory(startPath).parent;

    for (var i = 0; i < 10; i++) {
      final pubspec = File(p.join(current.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        return current.path;
      }
      if (current.path == current.parent.path) break;
      current = current.parent;
    }

    return null;
  }

  /// Load a template from file.
  ///
  /// Returns null if template file doesn't exist.
  String? loadTemplate(String relativePath) {
    final templatesDir = getTemplatesDirectory();
    final templatePath = p.join(templatesDir, relativePath);
    final file = File(templatePath);

    if (file.existsSync()) {
      return file.readAsStringSync();
    }

    return null;
  }

  /// Load a template from file, throwing if not found.
  String loadTemplateOrThrow(String relativePath) {
    final content = loadTemplate(relativePath);
    if (content == null) {
      throw TemplateNotFoundException(relativePath);
    }
    return content;
  }

  /// Load a template and apply variable substitution.
  String? loadAndApplyTemplate(
    String relativePath,
    Map<String, String> variables,
  ) {
    final content = loadTemplate(relativePath);
    if (content == null) return null;

    return _applyVariables(content, variables);
  }

  /// Load a template, apply variables, throwing if not found.
  String loadAndApplyTemplateOrThrow(
    String relativePath,
    Map<String, String> variables,
  ) {
    final content = loadTemplateOrThrow(relativePath);
    return _applyVariables(content, variables);
  }

  /// Apply variable substitution to template content.
  String _applyVariables(String content, Map<String, String> variables) {
    var result = content;
    for (final entry in variables.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// List all template files in a directory.
  List<String> listTemplates(String subDirectory) {
    final templatesDir = getTemplatesDirectory();
    final dir = Directory(p.join(templatesDir, subDirectory));

    if (!dir.existsSync()) return [];

    return dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.template'))
        .map((f) => p.basename(f.path))
        .toList();
  }

  /// Check if templates directory exists and contains expected files.
  bool validateTemplatesExist() {
    try {
      final dir = getTemplatesDirectory();
      final coreDir = Directory(p.join(dir, 'core'));
      final featureDir = Directory(p.join(dir, 'feature'));

      return coreDir.existsSync() && featureDir.existsSync();
    } catch (e) {
      return false;
    }
  }
}

/// Template registry for accessing all scaffold templates.
class TemplateRegistry {
  const TemplateRegistry({TemplateLoader? loader})
    : _loader = loader ?? const TemplateLoader();

  final TemplateLoader _loader;

  /// Template path mappings for core files.
  static const _coreTemplates = {
    'lib/main.dart': 'core/main.dart.template',
    'lib/src/app.dart': 'core/app.dart.template',
    'lib/src/core/errors/exceptions.dart': 'core/exceptions.dart.template',
    'lib/src/core/errors/failures.dart': 'core/failures.dart.template',
    'lib/src/core/extensions/context_extensions.dart':
        'core/context_extensions.dart.template',
    'lib/src/core/theme/app_theme.dart': 'core/app_theme.dart.template',
    'lib/src/core/utils/logger.dart': 'core/logger.dart.template',
    'lib/src/routing/app_router.dart': 'routing/app_router.dart.template',
    'lib/src/routing/routes.dart': 'routing/routes.dart.template',
    'lib/src/shared/providers/shared_providers.dart':
        'shared/shared_providers.dart.template',
  };

  /// Feature template types.
  static const featureTemplateTypes = [
    'screen',
    'providers',
    'entity',
    'repository',
  ];

  /// Get a core template by its output path.
  ///
  /// Returns null if no template mapping exists or template file not found.
  String? getTemplate(String outputPath) {
    final templatePath = _coreTemplates[outputPath];
    if (templatePath == null) {
      return null;
    }

    return _loader.loadTemplate(templatePath);
  }

  /// Get a core template by its output path, throwing if not found.
  String getTemplateOrThrow(String outputPath) {
    final templatePath = _coreTemplates[outputPath];
    if (templatePath == null) {
      throw TemplateNotFoundException(
        'No template mapping for output path: $outputPath',
      );
    }

    return _loader.loadTemplateOrThrow(templatePath);
  }

  /// Get a feature template with variable substitution.
  ///
  /// Returns null if template not found.
  String? getFeatureTemplate(String templateType, String featureName) {
    final pascalName = toPascalCase(featureName);

    final variables = {'FEATURE_NAME': featureName, 'PASCAL_NAME': pascalName};

    final templatePath = 'feature/$templateType.dart.template';
    return _loader.loadAndApplyTemplate(templatePath, variables);
  }

  /// Get a feature template with variable substitution, throwing if not found.
  String getFeatureTemplateOrThrow(String templateType, String featureName) {
    final pascalName = toPascalCase(featureName);

    final variables = {'FEATURE_NAME': featureName, 'PASCAL_NAME': pascalName};

    final templatePath = 'feature/$templateType.dart.template';
    return _loader.loadAndApplyTemplateOrThrow(templatePath, variables);
  }

  /// Validate that all required templates exist.
  bool validateAllTemplatesExist() {
    // Check core templates
    for (final entry in _coreTemplates.entries) {
      final content = _loader.loadTemplate(entry.value);
      if (content == null) {
        return false;
      }
    }

    // Check feature templates
    for (final type in featureTemplateTypes) {
      final content = _loader.loadTemplate('feature/$type.dart.template');
      if (content == null) {
        return false;
      }
    }

    return true;
  }

  /// Get a list of all output paths that have template mappings.
  List<String> get allOutputPaths => _coreTemplates.keys.toList();
}
