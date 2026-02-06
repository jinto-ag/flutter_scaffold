/// Sandbox service for safe, verified command execution.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/logger.dart';

/// Result of a sandboxed operation.
sealed class SandboxResult {
  const SandboxResult();
}

/// Sandbox operation succeeded.
class SandboxSuccess extends SandboxResult {
  const SandboxSuccess({required this.changedFiles, required this.sandboxPath});

  /// Files that were changed during the operation.
  final List<String> changedFiles;

  /// Path to the sandbox (for inspection before cleanup).
  final String sandboxPath;
}

/// Sandbox operation failed.
class SandboxFailure extends SandboxResult {
  const SandboxFailure({required this.error, required this.sandboxPath});

  /// Error that occurred.
  final String error;

  /// Path to the sandbox (for debugging).
  final String sandboxPath;
}

/// Service for sandboxed verification of operations.
///
/// This service copies a project to a temporary directory, executes
/// an operation there, and only applies changes if verification passes.
class SandboxService {
  SandboxService({ScaffoldLogger? logger})
    : _logger = logger ?? ScaffoldLogger();

  final ScaffoldLogger _logger;

  /// Create a sandbox copy of the project.
  ///
  /// Returns the path to the sandbox directory.
  Future<String> createSandbox(String projectPath) async {
    final projectName = p.basename(projectPath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sandboxName = '${projectName}_sandbox_$timestamp';
    final sandboxPath = p.join(Directory.systemTemp.path, sandboxName);

    _logger.info('Creating sandbox at $sandboxPath...');

    final sandboxDir = Directory(sandboxPath);
    if (sandboxDir.existsSync()) {
      sandboxDir.deleteSync(recursive: true);
    }
    sandboxDir.createSync(recursive: true);

    // Copy project to sandbox
    await _copyDirectory(projectPath, sandboxPath);

    _logger.success('Sandbox created');
    return sandboxPath;
  }

  /// Execute an operation in a sandbox with verification.
  ///
  /// [projectPath] - Original project path.
  /// [operation] - The operation to execute (receives sandbox path).
  /// [verifySuccess] - Verification function (receives sandbox path).
  /// [applyOnSuccess] - Whether to apply changes back on success.
  Future<SandboxResult> executeWithVerification({
    required String projectPath,
    required Future<void> Function(String sandboxPath) operation,
    required Future<bool> Function(String sandboxPath) verifySuccess,
    bool applyOnSuccess = true,
  }) async {
    final sandboxPath = await createSandbox(projectPath);

    try {
      _logger.section('Executing in sandbox...');

      // Execute the operation in sandbox
      await operation(sandboxPath);

      // Verify success
      _logger.info('Verifying...');
      final success = await verifySuccess(sandboxPath);

      if (!success) {
        _logger.error('Verification failed');
        return SandboxFailure(
          error: 'Verification failed in sandbox',
          sandboxPath: sandboxPath,
        );
      }

      _logger.success('Verification passed');

      // Collect changed files for reporting
      final changedFiles = await _getChangedFiles(projectPath, sandboxPath);

      // Apply changes back if requested
      if (applyOnSuccess) {
        _logger.info('Applying changes to project...');
        await _applyChanges(projectPath, sandboxPath, changedFiles);
        _logger.success('Changes applied (${changedFiles.length} files)');
      }

      return SandboxSuccess(
        changedFiles: changedFiles,
        sandboxPath: sandboxPath,
      );
    } catch (e) {
      _logger.error('Sandbox execution failed: $e');
      return SandboxFailure(error: e.toString(), sandboxPath: sandboxPath);
    }
  }

  /// Clean up a sandbox directory.
  void cleanup(String sandboxPath) {
    final dir = Directory(sandboxPath);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
      _logger.info('Sandbox cleaned up');
    }
  }

  /// Copy a directory recursively.
  Future<void> _copyDirectory(String source, String dest) async {
    final sourceDir = Directory(source);

    await for (final entity in sourceDir.list(recursive: true)) {
      // Skip .git and build directories for speed
      if (entity.path.contains('.git') ||
          entity.path.contains('build/') ||
          entity.path.contains('.dart_tool/')) {
        continue;
      }

      final relativePath = p.relative(entity.path, from: source);
      final destPath = p.join(dest, relativePath);

      if (entity is File) {
        final destFile = File(destPath);
        destFile.parent.createSync(recursive: true);
        await entity.copy(destPath);
      } else if (entity is Directory) {
        Directory(destPath).createSync(recursive: true);
      }
    }
  }

  /// Get list of files that changed between project and sandbox.
  Future<List<String>> _getChangedFiles(
    String projectPath,
    String sandboxPath,
  ) async {
    final changedFiles = <String>[];
    final sandboxDir = Directory(sandboxPath);

    await for (final entity in sandboxDir.list(recursive: true)) {
      if (entity is! File) continue;

      // Skip .git and build directories
      if (entity.path.contains('.git') ||
          entity.path.contains('build/') ||
          entity.path.contains('.dart_tool/')) {
        continue;
      }

      final relativePath = p.relative(entity.path, from: sandboxPath);
      final originalPath = p.join(projectPath, relativePath);
      final originalFile = File(originalPath);

      // New file or modified file
      if (!originalFile.existsSync()) {
        changedFiles.add(relativePath);
      } else {
        final originalContent = await originalFile.readAsString();
        final sandboxContent = await entity.readAsString();
        if (originalContent != sandboxContent) {
          changedFiles.add(relativePath);
        }
      }
    }

    return changedFiles;
  }

  /// Apply changes from sandbox back to the original project.
  Future<void> _applyChanges(
    String projectPath,
    String sandboxPath,
    List<String> changedFiles,
  ) async {
    for (final relativePath in changedFiles) {
      final sandboxFile = File(p.join(sandboxPath, relativePath));
      final destFile = File(p.join(projectPath, relativePath));

      if (sandboxFile.existsSync()) {
        destFile.parent.createSync(recursive: true);
        await sandboxFile.copy(destFile.path);
      }
    }
  }

  /// Run flutter analyze in sandbox to verify code quality.
  Future<bool> verifyWithFlutterAnalyze(String sandboxPath) async {
    try {
      final result = await Process.run('flutter', [
        'analyze',
        '--no-fatal-infos',
      ], workingDirectory: sandboxPath);
      return result.exitCode == 0;
    } catch (e) {
      _logger.warn('Flutter analyze failed: $e');
      return false;
    }
  }
}
