/// Base class for E2E test steps.
///
/// Provides a common interface for all test steps.
library;

import 'dart:io';

import 'test_context.dart';

/// Base class for E2E test steps.
///
/// Each step defines its name, dependencies, and execution logic.
abstract class E2EStep {
  /// Unique name for this step.
  String get name;

  /// Human-readable description.
  String get description;

  /// List of glob patterns for files this step depends on.
  ///
  /// Used for cache invalidation.
  /// Example: ['lib/src/templates/**/*.template', 'lib/src/commands/*.dart']
  List<String> get dependencies;

  /// List of step names that must run before this step.
  List<String> get requiredSteps => [];

  /// Whether this step should always run regardless of cache.
  ///
  /// Useful for steps that set up state (like creating a project) needed by others.
  bool get alwaysRun => false;

  /// Execute the test step.
  Future<void> execute(E2ETestContext context);

  /// Get all dependency file paths.
  List<String> getDependencyFiles(String projectRoot) {
    final files = <String>[];
    for (final pattern in dependencies) {
      // Handle glob patterns
      if (pattern.contains('**')) {
        final parts = pattern.split('**/');
        final basePath = parts[0].isEmpty
            ? projectRoot
            : '$projectRoot/${parts[0]}';
        final suffix = parts.length > 1 ? parts[1] : '';
        files.addAll(_findFilesWithSuffix(basePath, suffix));
      } else if (pattern.contains('*')) {
        final parts = pattern.split('*');
        final basePath = '$projectRoot/${parts[0]}';
        final suffix = parts.length > 1 ? parts[1] : '';
        files.addAll(_findFilesWithSuffix(basePath, suffix));
      } else {
        files.add('$projectRoot/$pattern');
      }
    }
    return files;
  }

  List<String> _findFilesWithSuffix(String basePath, String suffix) {
    final files = <String>[];
    final dir = Directory(basePath);
    if (!dir.existsSync()) return files;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith(suffix)) {
        files.add(entity.path);
      }
    }
    return files;
  }
}
