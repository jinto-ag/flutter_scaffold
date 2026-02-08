/// Build runner and verification service.
library;

import 'dart:io';

import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/process_utils.dart';

/// Result of build runner execution.
class BuildRunnerResult {
  const BuildRunnerResult({
    required this.success,
    required this.output,
    this.elapsedTime,
  });

  final bool success;
  final String output;
  final Duration? elapsedTime;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Build Runner Result:');
    buffer.writeln('  Success: $success');
    if (elapsedTime != null) {
      buffer.writeln('  Time: ${elapsedTime!.inMilliseconds}ms');
    }
    if (output.isNotEmpty) {
      buffer.writeln('  Output: $output');
    }
    return buffer.toString();
  }
}

/// Result of verification process.
class VerificationResult {
  const VerificationResult({
    required this.success,
    required this.analyzerResult,
    required this.formatResult,
    required this.testResult,
    this.issues = const [],
  });

  final bool success;
  final ProcessResult analyzerResult;
  final ProcessResult? formatResult;
  final ProcessResult? testResult;
  final List<String> issues;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Verification Result:');
    buffer.writeln('  Success: $success');
    buffer.writeln(
      '  Analyzer: ${analyzerResult.exitCode == 0 ? "PASS" : "FAIL"}',
    );
    if (formatResult != null) {
      buffer.writeln(
        '  Format: ${formatResult!.exitCode == 0 ? "PASS" : "FAIL"}',
      );
    }
    if (testResult != null) {
      buffer.writeln('  Tests: ${testResult!.exitCode == 0 ? "PASS" : "FAIL"}');
    }
    if (issues.isNotEmpty) {
      buffer.writeln('  Issues:');
      for (final issue in issues) {
        buffer.writeln('    - $issue');
      }
    }
    return buffer.toString();
  }
}

/// Service for running build runner and code verification.
class BuildRunnerService {
  BuildRunnerService({
    ScaffoldLogger? logger,
    FileUtils? fileUtils,
    ProcessUtils? processUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _processUtils = processUtils ?? ProcessUtils();

  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final ProcessUtils _processUtils;

  /// Check if build runner is needed for the project.
  bool needsBuildRunner(String projectPath) {
    final pubspecPath = _fileUtils.joinPath(projectPath, 'pubspec.yaml');
    if (!_fileUtils.fileExists(pubspecPath)) {
      return false;
    }

    try {
      final content = _fileUtils.readFile(pubspecPath);

      // Check for common build runner dependencies
      final buildRunnerPatterns = [
        r'build_runner:',
        r'json_annotation:',
        r'freezed_annotation:',
        r'injectable_annotation:',
        r'copy_with_extension_gen:',
      ];

      for (final pattern in buildRunnerPatterns) {
        if (RegExp(pattern).hasMatch(content)) {
          return true;
        }
      }

      // Check for build.yaml file
      final buildYamlPath = _fileUtils.joinPath(projectPath, 'build.yaml');
      if (_fileUtils.fileExists(buildYamlPath)) {
        return true;
      }

      return false;
    } catch (e) {
      _logger.warn('Could not check build runner requirements: $e');
      return false;
    }
  }

  /// Run build runner if needed.
  Future<BuildRunnerResult> runBuildRunner(
    String projectPath, {
    bool deleteConflictingOutputs = false,
  }) async {
    if (!needsBuildRunner(projectPath)) {
      _logger.info('Build runner not needed for this project');
      return const BuildRunnerResult(
        success: true,
        output: 'Build runner not needed',
      );
    }

    _logger.section('Running build runner...');

    final stopwatch = Stopwatch()..start();

    try {
      final args = <String>['run', 'build_runner', 'build'];
      if (deleteConflictingOutputs) {
        args.add('--delete-conflicting-outputs');
      }

      final result = await _processUtils.dart(
        args,
        workingDirectory: projectPath,
      );

      stopwatch.stop();

      if (result.exitCode == 0) {
        _logger.success('Build runner completed successfully');
        return BuildRunnerResult(
          success: true,
          output: result.stdout,
          elapsedTime: stopwatch.elapsed,
        );
      } else {
        _logger.error('Build runner failed');
        _logger.info('Output: ${result.stdout}');
        _logger.info('Error: ${result.stderr}');
        return BuildRunnerResult(
          success: false,
          output: '${result.stdout}\n${result.stderr}',
          elapsedTime: stopwatch.elapsed,
        );
      }
    } catch (e) {
      stopwatch.stop();
      _logger.error('Build runner execution failed: $e');
      return BuildRunnerResult(
        success: false,
        output: e.toString(),
        elapsedTime: stopwatch.elapsed,
      );
    }
  }

  /// Run code verification: dart fix → dart format → flutter analyze.
  Future<VerificationResult> verifyCode(String projectPath) async {
    _logger.section('Verifying code...');

    final issues = <String>[];
    ProcessResult? fixResult;
    ProcessResult? formatResult;
    ProcessResult? analyzeResult;

    // Step 1: dart fix --apply
    try {
      _logger.info('Running dart fix --apply...');
      fixResult = await _processUtils.dart([
        'fix',
        '--apply',
      ], workingDirectory: projectPath);

      if (fixResult.exitCode == 0) {
        _logger.success('Applied automatic fixes');
      } else {
        _logger.warn('dart fix encountered issues');
      }
    } catch (e) {
      _logger.warn('Could not run dart fix: $e');
    }

    // Step 2: dart format
    try {
      _logger.info('Running dart format...');
      formatResult = await _processUtils.dart([
        'format',
        '.',
      ], workingDirectory: projectPath);

      if (formatResult.exitCode == 0) {
        _logger.success('Code formatted');
      } else {
        issues.add('Code formatting issues found');
        _logger.warn('Formatting issues detected');
      }
    } catch (e) {
      _logger.warn('Could not run format: $e');
    }

    // Step 3: flutter analyze (final verification)
    _logger.info('Running flutter analyze...');
    analyzeResult = await _processUtils.dart([
      'analyze',
    ], workingDirectory: projectPath);

    if (analyzeResult.exitCode != 0) {
      issues.add('Analysis issues found');
      _logger.warn('Analysis issues detected');
    } else {
      _logger.success('Analysis passed');
    }

    // Run tests (if test directory exists)
    ProcessResult? testResult;
    final testDir = _fileUtils.joinPath(projectPath, 'test');
    if (_fileUtils.directoryExists(testDir)) {
      try {
        _logger.info('Running tests...');
        testResult = await _processUtils.dart([
          'test',
        ], workingDirectory: projectPath);

        if (testResult.exitCode != 0) {
          issues.add('Test failures detected');
          _logger.warn('Test failures detected');
        } else {
          _logger.success('All tests passed');
        }
      } catch (e) {
        _logger.warn('Could not run tests: $e');
      }
    }

    final success =
        analyzeResult.exitCode == 0 &&
        (formatResult?.exitCode ?? 0) == 0 &&
        (testResult?.exitCode ?? 0) == 0;

    if (success) {
      _logger.success('All verification checks passed');
    } else {
      _logger.warn('Some verification checks failed');
    }

    return VerificationResult(
      success: success,
      analyzerResult: analyzeResult,
      formatResult: formatResult,
      testResult: testResult,
      issues: issues,
    );
  }

  /// Check if pubspec.yaml has been modified and needs pub get.
  bool needsPubGet(String projectPath) {
    final pubspecLockPath = _fileUtils.joinPath(projectPath, 'pubspec.lock');
    final pubspecPath = _fileUtils.joinPath(projectPath, 'pubspec.yaml');

    if (!_fileUtils.fileExists(pubspecLockPath)) {
      return true;
    }

    if (!_fileUtils.fileExists(pubspecPath)) {
      return false;
    }

    try {
      final pubspecModified = _fileUtils
          .listFiles(pubspecPath)
          .whereType<File>()
          .firstOrNull
          ?.lastModifiedSync();

      final lockModified = _fileUtils
          .listFiles(pubspecLockPath)
          .whereType<File>()
          .firstOrNull
          ?.lastModifiedSync();

      if (pubspecModified != null && lockModified != null) {
        return pubspecModified.isAfter(lockModified);
      }
    } catch (e) {
      _logger.warn('Could not check pubspec modification: $e');
    }

    return false;
  }

  /// Run pub get if needed.
  Future<bool> runPubGet(String projectPath) async {
    if (!needsPubGet(projectPath)) {
      return true;
    }

    _logger.info('Running pub get...');

    try {
      final result = await _processUtils.dart([
        'pub',
        'get',
      ], workingDirectory: projectPath);

      if (result.exitCode == 0) {
        _logger.success('Dependencies updated');
        return true;
      } else {
        _logger.error('Failed to update dependencies');
        _logger.info('Output: ${result.stdout}');
        _logger.info('Error: ${result.stderr}');
        return false;
      }
    } catch (e) {
      _logger.error('Pub get execution failed: $e');
      return false;
    }
  }
}
