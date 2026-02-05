#!/usr/bin/env dart

// ignore_for_file: avoid_print
/// E2E Test Script for flutter_scaffold
///
/// This script performs end-to-end testing by:
/// 1. Creating a new Flutter project in system temp
/// 2. Applying scaffold
/// 3. Running all tests
/// 4. Cleaning up
///
/// Usage: dart run scripts/e2e_test.dart [--keep] [--verbose]
///   --keep     Keep the generated project after test (for debugging)
///   --verbose  Show detailed output during test
library;

import 'dart:io';

// ANSI color codes
const _red = '\x1B[31m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _blue = '\x1B[34m';
const _reset = '\x1B[0m';

void main(List<String> args) async {
  final keepProject = args.contains('--keep');
  final verbose = args.contains('--verbose');

  // Create temp directory using Dart's system temp
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final projectName = 'e2e_test_app_$timestamp';
  final tempDir = Directory.systemTemp;
  final projectPath = '${tempDir.path}${Platform.pathSeparator}$projectName';
  final logFile = File('${Directory.current.path}/e2e_test.log');

  print('');
  print('════════════════════════════════════════════════════════════');
  print('  Flutter Scaffold E2E Test');
  print('════════════════════════════════════════════════════════════');
  print('');

  // Clear log file
  logFile.writeAsStringSync(
    'E2E Test Log - ${DateTime.now()}\n'
    'Project: $projectPath\n'
    '────────────────────────────────────────\n\n',
  );

  void log(String message) {
    print('$_blue[E2E]$_reset $message');
    logFile.writeAsStringSync('$message\n', mode: FileMode.append);
  }

  void logSuccess(String message) {
    print('$_green[E2E]$_reset ✓ $message');
    logFile.writeAsStringSync('✓ $message\n', mode: FileMode.append);
  }

  void logError(String message) {
    print('$_red[E2E]$_reset ✗ $message');
    logFile.writeAsStringSync('✗ $message\n', mode: FileMode.append);
  }

  void logWarn(String message) {
    print('$_yellow[E2E]$_reset ⚠ $message');
    logFile.writeAsStringSync('⚠ $message\n', mode: FileMode.append);
  }

  Future<void> cleanup() async {
    if (!keepProject) {
      log('Cleaning up $projectPath...');
      final dir = Directory(projectPath);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      logSuccess('Cleanup complete');
    } else {
      logWarn('Project kept at: $projectPath');
    }
  }

  Future<ProcessResult> runProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool showOutput = false,
  }) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );

    final output = '${result.stdout}\n${result.stderr}';
    logFile.writeAsStringSync(output, mode: FileMode.append);

    if (verbose || showOutput) {
      print(output);
    }

    return result;
  }

  try {
    // Step 1: Build and activate the CLI
    log('Building flutter_scaffold CLI...');

    // Clear cached snapshot
    final snapshotDir = Directory('.dart_tool/pub/bin/flutter_scaffold');
    if (snapshotDir.existsSync()) {
      snapshotDir.deleteSync(recursive: true);
    }

    final activateResult = await runProcess('dart', [
      'pub',
      'global',
      'activate',
      '--source',
      'path',
      '.',
    ]);
    if (activateResult.exitCode != 0) {
      logError('Failed to activate CLI');
      exit(1);
    }
    logSuccess('CLI built and activated');

    // Step 2: Create and scaffold the project
    log('Creating project: $projectName');
    logFile.writeAsStringSync('\nCreating project...\n', mode: FileMode.append);

    final createResult = await runProcess('flutter_scaffold', [
      'create',
      projectName,
      tempDir.path,
    ]);
    if (createResult.exitCode != 0) {
      logError('Failed to create project');
      print('');
      print('See log for details: ${logFile.path}');
      await cleanup();
      exit(1);
    }
    logSuccess('Project created and scaffolded');

    // Step 3: Run Flutter analyze
    log('Running flutter analyze...');
    logFile.writeAsStringSync(
      '\nRunning flutter analyze...\n',
      mode: FileMode.append,
    );

    final analyzeResult = await runProcess('flutter', [
      'analyze',
    ], workingDirectory: projectPath);
    if (analyzeResult.exitCode != 0) {
      logError('Flutter analyze failed');
      print('');
      print('See log for details: ${logFile.path}');
      await cleanup();
      exit(1);
    }
    logSuccess('Flutter analyze passed');

    // Step 4: Run Flutter tests
    log('Running flutter test...');
    logFile.writeAsStringSync(
      '\nRunning flutter test...\n',
      mode: FileMode.append,
    );

    final testResult = await runProcess('flutter', [
      'test',
      '--reporter',
      'compact',
    ], workingDirectory: projectPath);
    if (testResult.exitCode != 0) {
      logError('Tests failed');
      print('');
      print('See log for details: ${logFile.path}');
      await cleanup();
      exit(1);
    }
    logSuccess('All tests passed');

    // Step 5: Summary
    print('');
    print('════════════════════════════════════════════════════════════');
    print('  ${_green}E2E Test PASSED$_reset');
    print('════════════════════════════════════════════════════════════');
    print('');
    print('Log file: ${logFile.path}');

    if (keepProject) {
      print('Project kept at: $projectPath');
    }

    await cleanup();
    exit(0);
  } catch (e, stackTrace) {
    logError('Unexpected error: $e');
    logFile.writeAsStringSync(
      '\nStack trace:\n$stackTrace\n',
      mode: FileMode.append,
    );
    print('');
    print('See log for details: ${logFile.path}');
    await cleanup();
    exit(1);
  }
}
