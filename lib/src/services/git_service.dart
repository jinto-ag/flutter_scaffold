/// Git service for initializing git in scaffolded projects.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/logger.dart';
import '../utils/process_utils.dart';

/// Service for initializing git in scaffolded projects.
class GitService {
  GitService({ScaffoldLogger? logger, ProcessUtils? processUtils})
    : _logger = logger ?? ScaffoldLogger(),
      _processUtils = processUtils ?? ProcessUtils();

  final ScaffoldLogger _logger;
  final ProcessUtils _processUtils;

  /// Initialize git repository with dev branch and initial commit.
  ///
  /// [projectPath] - Path to the project directory.
  /// [projectName] - Name of the project for commit message.
  /// [dryRun] - If true, only show what would be done.
  Future<bool> initializeGit({
    required String projectPath,
    required String projectName,
    bool dryRun = false,
  }) async {
    if (dryRun) {
      _logger.section('Git initialization (dry-run)...');
      _logger.would('Initialize git repository');
      _logger.would('Create dev branch');
      _logger.would('Create initial commit with conventional format');
      return true;
    }

    _logger.section('Initializing git repository...');

    try {
      // Check if git is already initialized
      final gitDir = Directory(p.join(projectPath, '.git'));
      if (gitDir.existsSync()) {
        _logger.warn('Git already initialized, skipping...');
        return true;
      }

      // Initialize git
      final initResult = await _processUtils.run('git', [
        'init',
      ], workingDirectory: projectPath);

      if (initResult.exitCode != 0) {
        _logger.error('Failed to initialize git: ${initResult.stderr}');
        return false;
      }

      _logger.success('Initialized git repository');

      // Create dev branch
      final branchResult = await _processUtils.run('git', [
        'checkout',
        '-b',
        'dev',
      ], workingDirectory: projectPath);

      if (branchResult.exitCode != 0) {
        _logger.error('Failed to create dev branch: ${branchResult.stderr}');
        return false;
      }

      _logger.success('Created dev branch');

      // Add all files
      final addResult = await _processUtils.run('git', [
        'add',
        '-A',
      ], workingDirectory: projectPath);

      if (addResult.exitCode != 0) {
        _logger.error('Failed to stage files: ${addResult.stderr}');
        return false;
      }

      // Create initial commit with conventional format
      final commitMessage = _buildCommitMessage(projectName);
      final commitResult = await _processUtils.run('git', [
        'commit',
        '-m',
        commitMessage,
      ], workingDirectory: projectPath);

      if (commitResult.exitCode != 0) {
        _logger.error('Failed to create commit: ${commitResult.stderr}');
        return false;
      }

      _logger.success('Created initial commit');

      return true;
    } catch (e) {
      _logger.error('Git initialization failed: $e');
      return false;
    }
  }

  /// Build conventional commit message for initial commit.
  String _buildCommitMessage(String projectName) {
    return '''🎉 feat($projectName): initial project setup

## Summary
- Flutter project scaffolded with clean architecture
- Core structure: errors, theme, extensions, utils
- Routing setup with GoRouter
- State management with Riverpod
- Code generation configured (Freezed, JSON)

## Features
- Home feature module with screens and providers
- Shared providers for app-wide state
- Theme support (light/dark mode)
- Extensible architecture

## Next Steps
- Add more features with: flutter_scaffold add feature <name>
- Run code generation: dart run build_runner build
- Start developing your app!

Generated with flutter_scaffold v0.1.0''';
  }

  /// Check if git is available on the system.
  Future<bool> isGitAvailable() async {
    try {
      final result = await _processUtils.run('git', ['--version']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
}
