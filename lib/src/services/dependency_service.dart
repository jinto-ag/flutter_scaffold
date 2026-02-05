/// Dependency and code generation service.
library;

import '../core/constants.dart';
import '../core/errors.dart';
import '../utils/logger.dart';
import '../utils/process_utils.dart';

/// Service for managing dependencies and code generation.
class DependencyService {
  DependencyService({ScaffoldLogger? logger, ProcessUtils? processUtils})
    : _logger = logger ?? ScaffoldLogger(),
      _processUtils = processUtils ?? ProcessUtils();

  final ScaffoldLogger _logger;
  final ProcessUtils _processUtils;

  /// Install all required dependencies.
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

  /// Run flutter analyze to verify code.
  Future<bool> runAnalyze({
    required String projectPath,
    bool showOutput = true,
  }) async {
    _logger.info('');
    _logger.info('Verifying code with flutter analyze...');
    _logger.info('');

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

  /// Install dependencies and run code generation.
  Future<void> setupProject({
    required String projectPath,
    bool showOutput = true,
  }) async {
    await installDependencies(projectPath: projectPath, showOutput: showOutput);
    await runBuildRunner(projectPath: projectPath, showOutput: showOutput);
    await runAnalyze(projectPath: projectPath, showOutput: showOutput);
  }
}
