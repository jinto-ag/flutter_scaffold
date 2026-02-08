#!/usr/bin/env dart

/// Legacy E2E test script wrapper.
///
/// This script maintains backward compatibility by delegating to the
/// new modular E2E framework at test/e2e/e2e_runner.dart.
///
/// Usage: dart run scripts/e2e_test.dart [options]
///
/// For the new modular framework, use:
///   dart run test/e2e/e2e_runner.dart [options]
library;

import 'dart:io';

void main(List<String> args) async {
  // Forward to the new E2E runner
  final projectRoot = Directory.current.path;
  final runnerPath = '$projectRoot/test/e2e/e2e_runner.dart';

  if (!File(runnerPath).existsSync()) {
    print('Error: New E2E runner not found at $runnerPath');
    print('Please ensure the test/e2e/ framework is properly installed.');
    exit(1);
  }

  print('Delegating to test/e2e/e2e_runner.dart...\n');

  // Use Process.start with inheritStdio for real-time output
  final process = await Process.start('dart', [
    'run',
    runnerPath,
    ...args,
  ], workingDirectory: projectRoot);

  // Forward stdout and stderr
  process.stdout.listen((data) => stdout.add(data));
  process.stderr.listen((data) => stderr.add(data));

  // Wait for completion and exit with same code
  final exitCode = await process.exitCode;
  exit(exitCode);
}
