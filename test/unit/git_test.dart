/// Unit tests for GitService.
library;

import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:test/test.dart';

void main() {
  group('GitService', () {
    late GitService gitService;
    late Directory tempDir;

    setUp(() {
      gitService = GitService();
      tempDir = Directory.systemTemp.createTempSync('git_service_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('isGitAvailable returns true when git is installed', () async {
      final available = await gitService.isGitAvailable();
      expect(available, isTrue);
    });

    test('initializeGit creates .git directory', () async {
      // Create a minimal project structure
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync('name: test_project\n');

      final result = await gitService.initializeGit(
        projectPath: tempDir.path,
        projectName: 'test_project',
      );

      expect(result, isTrue);
      expect(Directory('${tempDir.path}/.git').existsSync(), isTrue);
    });

    test('initializeGit creates dev branch', () async {
      // Create a minimal project structure
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync('name: test_project\n');

      await gitService.initializeGit(
        projectPath: tempDir.path,
        projectName: 'test_project',
      );

      // Check current branch
      final result = Process.runSync('git', [
        'branch',
        '--show-current',
      ], workingDirectory: tempDir.path);

      expect(result.stdout.toString().trim(), equals('dev'));
    });

    test('initializeGit creates commit with conventional format', () async {
      // Create a minimal project structure
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync('name: my_app\n');

      await gitService.initializeGit(
        projectPath: tempDir.path,
        projectName: 'my_app',
      );

      // Check commit message
      final result = Process.runSync('git', [
        'log',
        '--oneline',
        '-1',
      ], workingDirectory: tempDir.path);

      final commitMessage = result.stdout.toString();
      expect(commitMessage, contains('🎉 feat(my_app)'));
      expect(commitMessage, contains('initial project setup'));
    });

    test('initializeGit skips if git already initialized', () async {
      // Create a minimal project structure
      final pubspec = File('${tempDir.path}/pubspec.yaml');
      pubspec.writeAsStringSync('name: test_project\n');

      // Initialize git manually first
      Process.runSync('git', ['init'], workingDirectory: tempDir.path);

      final result = await gitService.initializeGit(
        projectPath: tempDir.path,
        projectName: 'test_project',
      );

      // Should return true but skip initialization
      expect(result, isTrue);
    });

    test('initializeGit dry run does not create .git', () async {
      final result = await gitService.initializeGit(
        projectPath: tempDir.path,
        projectName: 'test_project',
        dryRun: true,
      );

      expect(result, isTrue);
      expect(Directory('${tempDir.path}/.git').existsSync(), isFalse);
    });
  });

  group('GitService commit message', () {
    test('commit message includes project name as scope', () async {
      final gitService = GitService();
      final tempDir = Directory.systemTemp.createTempSync('git_msg_test_');

      try {
        final pubspec = File('${tempDir.path}/pubspec.yaml');
        pubspec.writeAsStringSync('name: my_awesome_app\n');

        await gitService.initializeGit(
          projectPath: tempDir.path,
          projectName: 'my_awesome_app',
        );

        final result = Process.runSync('git', [
          'log',
          '--format=%B',
          '-1',
        ], workingDirectory: tempDir.path);

        final fullMessage = result.stdout.toString();
        expect(fullMessage, contains('feat(my_awesome_app)'));
        expect(fullMessage, contains('Flutter project scaffolded'));
        expect(fullMessage, contains('flutter_scaffold'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
