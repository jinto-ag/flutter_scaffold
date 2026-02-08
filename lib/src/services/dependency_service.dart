/// Dependency management service for Flutter Scaffold CLI.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import '../core/constants.dart';
import '../core/errors.dart';
import '../utils/logger.dart';
import '../utils/process_utils.dart';

/// Feature types that have specific dependency requirements.
enum FeatureType {
  /// Repository pattern with datasources
  repository,

  /// BLoC state management
  bloc,

  /// Model/Entity generation
  model,

  /// Core Riverpod setup
  riverpod,

  /// HTTP/API functionality
  http,

  /// Local storage
  localStorage,
}

/// Dependencies required for each feature type.
const Map<FeatureType, List<String>> featureDependencies = {
  FeatureType.repository: ['http', 'shared_preferences'],
  FeatureType.bloc: ['flutter_bloc', 'equatable'],
  FeatureType.model: ['json_annotation'],
  FeatureType.riverpod: ['flutter_riverpod', 'riverpod_annotation'],
  FeatureType.http: ['http'],
  FeatureType.localStorage: ['shared_preferences'],
};

/// Dev dependencies required for each feature type.
const Map<FeatureType, List<String>> featureDevDependencies = {
  FeatureType.bloc: ['bloc_test'],
  FeatureType.model: ['json_serializable'],
  FeatureType.riverpod: ['riverpod_generator'],
};

/// Result of dependency operations.
class DependencyResult {
  const DependencyResult({
    required this.success,
    this.installed = const [],
    this.skipped = const [],
    this.failed = const [],
    this.message,
  });

  final bool success;
  final List<String> installed;
  final List<String> skipped;
  final List<String> failed;
  final String? message;

  @override
  String toString() {
    final buffer = StringBuffer('DependencyResult(');
    buffer.write('success: $success');
    if (installed.isNotEmpty) buffer.write(', installed: $installed');
    if (skipped.isNotEmpty) buffer.write(', skipped: $skipped');
    if (failed.isNotEmpty) buffer.write(', failed: $failed');
    if (message != null) buffer.write(', message: $message');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Result of verification operations.
class VerificationResult {
  const VerificationResult({
    required this.success,
    this.fixApplied = false,
    this.formatApplied = false,
    this.analyzeIssues = 0,
    this.issues = const [],
  });

  final bool success;
  final bool fixApplied;
  final bool formatApplied;
  final int analyzeIssues;
  final List<String> issues;

  @override
  String toString() {
    return 'VerificationResult(success: $success, issues: ${issues.length})';
  }
}

/// Production-grade service for managing project dependencies.
///
/// Provides:
/// - Feature-specific dependency tracking
/// - Conditional installation (only missing packages)
/// - Verification with dart fix → dart format → flutter analyze
class DependencyService {
  DependencyService({ScaffoldLogger? logger, ProcessUtils? processUtils})
    : _logger = logger ?? ScaffoldLogger(),
      _processUtils = processUtils ?? ProcessUtils();

  final ScaffoldLogger _logger;
  final ProcessUtils _processUtils;

  // ─────────────────────────────────────────────────────────────────────────
  // Package Installation
  // ─────────────────────────────────────────────────────────────────────────

  /// Check if a package is installed in the project's pubspec.yaml.
  bool isPackageInstalled(String package, String projectPath) {
    final pubspecPath = p.join(projectPath, 'pubspec.yaml');
    final pubspecFile = File(pubspecPath);

    if (!pubspecFile.existsSync()) {
      return false;
    }

    try {
      final content = pubspecFile.readAsStringSync();
      final yaml = loadYaml(content) as YamlMap;

      // Check dependencies
      final deps = yaml['dependencies'] as YamlMap?;
      if (deps != null && deps.containsKey(package)) {
        return true;
      }

      // Check dev_dependencies
      final devDeps = yaml['dev_dependencies'] as YamlMap?;
      if (devDeps != null && devDeps.containsKey(package)) {
        return true;
      }

      return false;
    } catch (e) {
      _logger.warn('Error reading pubspec.yaml: $e');
      return false;
    }
  }

  /// Get list of missing packages from the given list.
  List<String> getMissingPackages(List<String> packages, String projectPath) {
    return packages
        .where((pkg) => !isPackageInstalled(pkg, projectPath))
        .toList();
  }

  /// Ensure dependencies are installed, installing only missing ones.
  ///
  /// Returns a [DependencyResult] with details of what was installed/skipped.
  Future<DependencyResult> ensureDependencies({
    required List<String> packages,
    required String projectPath,
    bool isDev = false,
    bool showOutput = true,
  }) async {
    final missing = getMissingPackages(packages, projectPath);
    final skipped = packages.where((pkg) => !missing.contains(pkg)).toList();

    if (missing.isEmpty) {
      _logger.info(
        '  All ${isDev ? "dev " : ""}dependencies already installed',
      );
      return DependencyResult(success: true, installed: [], skipped: skipped);
    }

    _logger.info(
      '  Installing ${missing.length} missing ${isDev ? "dev " : ""}packages: ${missing.join(", ")}',
    );

    final result = await _processUtils.pubAdd(
      missing,
      workingDirectory: projectPath,
      isDev: isDev,
      showOutput: showOutput,
    );

    if (!result.success) {
      return DependencyResult(
        success: false,
        installed: [],
        skipped: skipped,
        failed: missing,
        message: 'Failed to install packages',
      );
    }

    return DependencyResult(
      success: true,
      installed: missing,
      skipped: skipped,
    );
  }

  /// Get required dependencies for a feature type.
  List<String> getDependenciesForFeature(FeatureType featureType) {
    return featureDependencies[featureType] ?? [];
  }

  /// Get required dev dependencies for a feature type.
  List<String> getDevDependenciesForFeature(FeatureType featureType) {
    return featureDevDependencies[featureType] ?? [];
  }

  /// Ensure all dependencies for a feature type are installed.
  Future<DependencyResult> ensureFeatureDependencies({
    required FeatureType featureType,
    required String projectPath,
    bool showOutput = true,
  }) async {
    final deps = getDependenciesForFeature(featureType);
    final devDeps = getDevDependenciesForFeature(featureType);

    final installedAll = <String>[];
    final skippedAll = <String>[];
    final failedAll = <String>[];

    if (deps.isNotEmpty) {
      final result = await ensureDependencies(
        packages: deps,
        projectPath: projectPath,
        showOutput: showOutput,
      );
      installedAll.addAll(result.installed);
      skippedAll.addAll(result.skipped);
      failedAll.addAll(result.failed);

      if (!result.success) {
        return DependencyResult(
          success: false,
          installed: installedAll,
          skipped: skippedAll,
          failed: failedAll,
        );
      }
    }

    if (devDeps.isNotEmpty) {
      final result = await ensureDependencies(
        packages: devDeps,
        projectPath: projectPath,
        isDev: true,
        showOutput: showOutput,
      );
      installedAll.addAll(result.installed);
      skippedAll.addAll(result.skipped);
      failedAll.addAll(result.failed);

      if (!result.success) {
        return DependencyResult(
          success: false,
          installed: installedAll,
          skipped: skippedAll,
          failed: failedAll,
        );
      }
    }

    return DependencyResult(
      success: true,
      installed: installedAll,
      skipped: skippedAll,
    );
  }

  /// Install all core dependencies for a new project.
  Future<void> installDependencies({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.section('Installing dependencies...');

    // Add core dependencies
    _logger.info('Adding core dependencies...');
    var result = await _processUtils.pubAdd(
      coreDependencies,
      workingDirectory: projectPath,
      showOutput: showOutput,
    );

    if (!result.success) {
      throw ProcessException(
        'Failed to install core dependencies',
        exitCode: result.exitCode,
      );
    }

    // Add dev dependencies
    _logger.info('');
    _logger.info('Adding dev dependencies...');
    result = await _processUtils.pubAdd(
      devDependencies,
      workingDirectory: projectPath,
      isDev: true,
      showOutput: showOutput,
    );

    if (!result.success) {
      throw ProcessException(
        'Failed to install dev dependencies',
        exitCode: result.exitCode,
      );
    }

    // Run pub get
    _logger.info('');
    _logger.info('Resolving dependencies...');
    result = await _processUtils.pubGet(
      workingDirectory: projectPath,
      showOutput: showOutput,
    );

    if (!result.success) {
      throw ProcessException(
        'Failed to resolve dependencies',
        exitCode: result.exitCode,
      );
    }

    _logger.success('Dependencies installed!');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Code Generation
  // ─────────────────────────────────────────────────────────────────────────

  /// Run build_runner to generate code.
  Future<bool> runBuildRunner({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.info('');
    _logger.info('Running build_runner to generate code...');
    _logger.info('');

    final result = await _processUtils.buildRunner(
      workingDirectory: projectPath,
      showOutput: showOutput,
    );

    if (result.success) {
      _logger.success('Generated code successfully!');
      return true;
    } else {
      _logger.warn(
        "build_runner failed - you may need to run 'flutter pub get' first",
      );
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Verification: dart fix → dart format → flutter analyze
  // ─────────────────────────────────────────────────────────────────────────

  /// Run dart fix --apply to automatically fix issues.
  Future<bool> runDartFix({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.info('Running dart fix --apply...');

    final result = await _processUtils.dart([
      'fix',
      '--apply',
    ], workingDirectory: projectPath);

    if (result.exitCode == 0) {
      _logger.success('Applied automatic fixes');
      return true;
    } else {
      _logger.warn('dart fix encountered issues');
      return false;
    }
  }

  /// Run dart format to format code.
  Future<bool> runDartFormat({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.info('Running dart format...');

    final result = await _processUtils.dart([
      'format',
      '.',
    ], workingDirectory: projectPath);

    if (result.exitCode == 0) {
      _logger.success('Code formatted');
      return true;
    } else {
      _logger.warn('dart format encountered issues');
      return false;
    }
  }

  /// Run flutter analyze to verify code.
  Future<bool> runAnalyze({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.info('Running flutter analyze...');

    final result = await _processUtils.analyze(
      workingDirectory: projectPath,
      showOutput: showOutput,
    );

    if (result.success) {
      _logger.success('Code analysis passed - no issues found!');
      return true;
    } else {
      _logger.warn('flutter analyze found issues - please review and fix');
      return false;
    }
  }

  /// Run complete verification sequence: dart fix → dart format → flutter analyze.
  Future<VerificationResult> runVerification({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.section('Running verification...');

    final issues = <String>[];

    // Step 1: dart fix --apply
    final fixSuccess = await runDartFix(
      projectPath: projectPath,
      showOutput: showOutput,
    );

    // Step 2: dart format
    final formatSuccess = await runDartFormat(
      projectPath: projectPath,
      showOutput: showOutput,
    );
    if (!formatSuccess) {
      issues.add('Formatting issues detected');
    }

    // Step 3: flutter analyze
    final analyzeSuccess = await runAnalyze(
      projectPath: projectPath,
      showOutput: showOutput,
    );
    if (!analyzeSuccess) {
      issues.add('Analysis issues detected');
    }

    final success = analyzeSuccess; // Final analysis is what matters

    if (success) {
      _logger.success('All verification checks passed!');
    } else {
      _logger.warn('Verification found issues');
    }

    return VerificationResult(
      success: success,
      fixApplied: fixSuccess,
      formatApplied: formatSuccess,
      issues: issues,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Full Setup
  // ─────────────────────────────────────────────────────────────────────────

  /// Install dependencies and run code generation.
  Future<void> setupProject({
    required String projectPath,
    bool showOutput = true,
  }) async {
    await installDependencies(projectPath: projectPath, showOutput: showOutput);
    await runBuildRunner(projectPath: projectPath, showOutput: showOutput);
    await runVerification(projectPath: projectPath, showOutput: showOutput);
  }
}
