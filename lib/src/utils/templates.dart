/// Template system for scaffold file generation.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'string_utils.dart';

/// Exception thrown when a template is not found.
class TemplateNotFoundException implements Exception {
  const TemplateNotFoundException(this.templatePath);

  final String templatePath;

  @override
  String toString() => 'Template not found: $templatePath';
}

/// Context for template variable substitution.
class TemplateContext {
  TemplateContext({
    Map<String, dynamic>? globalVariables,
    Map<String, dynamic>? specificVariables,
  }) : _globalVariables = globalVariables ?? {},
       _specificVariables = specificVariables ?? {};

  final Map<String, dynamic> _globalVariables;
  final Map<String, dynamic> _specificVariables;

  /// Create a TemplateContext from a pubspec.yaml file.
  factory TemplateContext.fromPubspec(String pubspecPath) {
    final file = File(pubspecPath);
    if (!file.existsSync()) {
      return TemplateContext();
    }

    try {
      final yamlContent = file.readAsStringSync();
      final yaml = loadYaml(yamlContent) as YamlMap;

      final globalVars = <String, dynamic>{};

      // Extract project name
      if (yaml['name'] != null) {
        globalVars['projectName'] = yaml['name'].toString();
      }

      // Extract Dart SDK version
      if (yaml['environment'] != null && yaml['environment']['sdk'] != null) {
        globalVars['dartSdkVersion'] = yaml['environment']['sdk'].toString();
      }

      // Extract Flutter SDK version
      if (yaml['dependencies'] != null &&
          yaml['dependencies']['flutter'] != null) {
        final flutterVersion = yaml['dependencies']['flutter'];
        if (flutterVersion is String) {
          globalVars['flutterVersion'] = flutterVersion;
        }
      }

      // Add current year
      globalVars['year'] = DateTime.now().year.toString();

      return TemplateContext(globalVariables: globalVars);
    } catch (e) {
      // Fallback to empty context if parsing fails
      return TemplateContext();
    }
  }

  /// Create a TemplateContext with default global variables.
  factory TemplateContext.withDefaults() {
    final globalVars = <String, dynamic>{
      'year': DateTime.now().year.toString(),
    };
    return TemplateContext(globalVariables: globalVars);
  }

  /// Get all variables (global + specific) merged.
  Map<String, dynamic> get allVariables {
    final merged = Map<String, dynamic>.from(_globalVariables);
    merged.addAll(_specificVariables);
    return merged;
  }

  /// Get global variables only.
  Map<String, dynamic> get globalVariables =>
      Map.unmodifiable(_globalVariables);

  /// Get specific variables only.
  Map<String, dynamic> get specificVariables =>
      Map.unmodifiable(_specificVariables);

  /// Add or update a global variable.
  void setGlobal(String key, dynamic value) {
    _globalVariables[key] = value;
  }

  /// Add or update a specific variable.
  void setSpecific(String key, dynamic value) {
    _specificVariables[key] = value;
  }

  /// Add multiple specific variables at once.
  void setSpecifics(Map<String, dynamic> variables) {
    _specificVariables.addAll(variables);
  }

  /// Get a variable value (specific takes precedence over global).
  dynamic operator [](String key) {
    return _specificVariables[key] ?? _globalVariables[key];
  }

  /// Check if a variable exists.
  bool contains(String key) {
    return _specificVariables.containsKey(key) ||
        _globalVariables.containsKey(key);
  }

  /// Create a new context with additional specific variables.
  TemplateContext withSpecifics(Map<String, dynamic> variables) {
    return TemplateContext(
      globalVariables: _globalVariables,
      specificVariables: Map<String, dynamic>.from(_specificVariables)
        ..addAll(variables),
    );
  }

  /// Create a new context with additional global variables.
  TemplateContext withGlobals(Map<String, dynamic> variables) {
    return TemplateContext(
      globalVariables: Map<String, dynamic>.from(_globalVariables)
        ..addAll(variables),
      specificVariables: _specificVariables,
    );
  }
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
    Map<String, dynamic> variables,
  ) {
    final content = loadTemplate(relativePath);
    if (content == null) return null;

    final processed = _applyLogic(content, variables);
    return _applyVariables(processed, variables);
  }

  /// Load a template, apply variables, throwing if not found.
  String loadAndApplyTemplateOrThrow(
    String relativePath,
    Map<String, dynamic> variables,
  ) {
    final content = loadTemplateOrThrow(relativePath);
    final processed = _applyLogic(content, variables);
    return _applyVariables(processed, variables);
  }

  String _applyLogic(String content, Map<String, dynamic> variables) {
    final lines = content.split('\n');
    final buffer = StringBuffer();
    // Stack of booleans indicating if we are currently "inside" a true block.
    // Top of stack is current scope.
    final stack = <bool>[true];
    // Stack tracking if we have already satisfied a condition in the current if/else chain.
    final satisfiedStack = <bool>[false];

    final ifRegex = RegExp(r'^\s*\{\{\s*if\s+([a-zA-Z0-9_]+)\s*\}\}\s*$');
    final elIfRegex = RegExp(
      r'^\s*\{\{\s*else\s+if\s+([a-zA-Z0-9_]+)\s*\}\}\s*$',
    );
    final elseRegex = RegExp(r'^\s*\{\{\s*else\s*\}\}\s*$');
    final endifRegex = RegExp(r'^\s*\{\{\s*endif\s*\}\}\s*$');

    for (final line in lines) {
      final ifMatch = ifRegex.firstMatch(line);
      if (ifMatch != null) {
        final varName = ifMatch.group(1)!;
        final condition = variables[varName] == true;

        // Push new scope state
        // Only enter if parent scope is active AND condition is true
        final parentActive = stack.last;
        stack.add(parentActive && condition);

        // Track that we satisfied this chain if condition was true (and parent was active)
        satisfiedStack.add(parentActive && condition);
        continue;
      }

      final elIfMatch = elIfRegex.firstMatch(line);
      if (elIfMatch != null) {
        if (stack.length <= 1) {
          // Should check for proper nesting
          // Treating unmatched elseif as text or ignore?
          // Better to throw or ignore. For now, treating as text if stack is empty (root).
          // But stack always has [true].
        }

        final varName = elIfMatch.group(1)!;
        final condition = variables[varName] == true;
        final parentActive = stack[stack.length - 2];
        final chainSatisfied = satisfiedStack.last;

        // We enter this block if:
        // 1. Parent is active
        // 2. Previous blocks in this chain were NOT satisfied
        // 3. Current condition IS true
        final shouldEnter = parentActive && !chainSatisfied && condition;

        stack.removeLast();
        stack.add(shouldEnter);

        if (shouldEnter) {
          satisfiedStack.removeLast();
          satisfiedStack.add(true);
        }
        continue;
      }

      final elseMatch = elseRegex.firstMatch(line);
      if (elseMatch != null) {
        final parentActive = stack[stack.length - 2];
        final chainSatisfied = satisfiedStack.last;

        // Enter else if parent active and nothing else satisfied
        final shouldEnter = parentActive && !chainSatisfied;

        stack.removeLast();
        stack.add(shouldEnter);

        // Mark satisfied (though logic is done)
        satisfiedStack.removeLast();
        satisfiedStack.add(true);
        continue;
      }

      final endifMatch = endifRegex.firstMatch(line);
      if (endifMatch != null) {
        if (stack.length > 1) {
          stack.removeLast();
          satisfiedStack.removeLast();
        }
        continue;
      }

      // If current scope is active, keep the line
      if (stack.last) {
        buffer.writeln(line);
      }
    }

    // Trim the trailing newline added by writeln if the original didn't have one?
    // split('\n') behavior on trailing newline is tricky.
    // For source templates, writeln is usually fine.
    var result = buffer.toString();
    if (!content.endsWith('\n') && result.endsWith('\n')) {
      result = result.substring(0, result.length - 1);
    }
    return result;
  }

  /// Apply variable substitution to template content.
  String _applyVariables(String content, Map<String, dynamic> variables) {
    var result = content;
    for (final entry in variables.entries) {
      if (entry.value is String) {
        result = result.replaceAll('{{${entry.key}}}', entry.value);
      }
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
  TemplateRegistry({TemplateLoader? loader, TemplateContext? context})
    : _loader = loader ?? const TemplateLoader(),
      _context = context ?? TemplateContext.withDefaults();

  final TemplateLoader _loader;
  final TemplateContext _context;

  /// Get the template context.
  TemplateContext get context => _context;

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
    // Git hooks
    '.githooks/pre-commit': 'hooks/pre-commit.template',
    '.githooks/commit-msg': 'hooks/commit-msg.template',
    '.githooks/setup.sh': 'hooks/setup.sh.template',
    // Unit tests
    'test/core/app_theme_test.dart': 'test/app_theme_test.dart.template',
    'test/core/errors_test.dart': 'test/errors_test.dart.template',
    'test/routing_test.dart': 'test/routing_test.dart.template',
    'test/app_test.dart': 'test/app_test.dart.template',
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

    return _loader.loadAndApplyTemplate(templatePath, _context.allVariables);
  }

  /// Get a core template by its output path, throwing if not found.
  String getTemplateOrThrow(String outputPath) {
    final templatePath = _coreTemplates[outputPath];
    if (templatePath == null) {
      throw TemplateNotFoundException(
        'No template mapping for output path: $outputPath',
      );
    }

    return _loader.loadAndApplyTemplateOrThrow(
      templatePath,
      _context.allVariables,
    );
  }

  /// Get a feature template with variable substitution.
  ///
  /// Returns null if template not found.
  String? getFeatureTemplate(String templateType, String featureName) {
    final pascalName = toPascalCase(featureName);

    final specificVariables = {
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalName,
      'featureName': featureName,
      'pascalName': pascalName,
    };

    // Merge specific variables with global context
    final context = _context.withSpecifics(specificVariables);

    final templatePath = 'feature/$templateType.dart.template';
    return _loader.loadAndApplyTemplate(templatePath, context.allVariables);
  }

  /// Get a feature template with variable substitution, throwing if not found.
  String getFeatureTemplateOrThrow(String templateType, String featureName) {
    final pascalName = toPascalCase(featureName);

    final specificVariables = {
      'FEATURE_NAME': featureName,
      'PASCAL_NAME': pascalName,
      'featureName': featureName,
      'pascalName': pascalName,
    };

    // Merge specific variables with global context
    final context = _context.withSpecifics(specificVariables);

    final templatePath = 'feature/$templateType.dart.template';
    return _loader.loadAndApplyTemplateOrThrow(
      templatePath,
      context.allVariables,
    );
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
