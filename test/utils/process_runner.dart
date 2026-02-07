/// Process runner utilities for tests.
///
/// Provides a consistent way to run external processes with logging and error handling.
library;

import 'dart:io';

import 'logging.dart';

/// Result of a process execution.
class ProcessRunResult {
  final int exitCode;
  final String stdout;
  final String stderr;
  final String command;

  const ProcessRunResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    required this.command,
  });

  bool get success => exitCode == 0;

  String get output => '$stdout\n$stderr'.trim();
}

/// Exception thrown when a process fails.
class ProcessFailedException implements Exception {
  final ProcessRunResult result;

  const ProcessFailedException(this.result);

  @override
  String toString() =>
      'Command failed: ${result.command}\n'
      'Exit Code: ${result.exitCode}\n'
      'Output: ${result.output}';
}

/// Process runner with logging support.
class ProcessRunner {
  final TestLogger? logger;
  final bool throwOnError;

  const ProcessRunner({this.logger, this.throwOnError = true});

  /// Run a command and return the result.
  Future<ProcessRunResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool throwOnError = true,
  }) async {
    final command = '$executable ${args.join(' ')}';
    logger?.debug('Running: $command');

    final result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      runInShell: Platform.isWindows,
    );

    final runResult = ProcessRunResult(
      exitCode: result.exitCode,
      stdout: result.stdout.toString(),
      stderr: result.stderr.toString(),
      command: command,
    );

    if (logger != null) {
      logger!.debug('Exit code: ${runResult.exitCode}');
      if (runResult.output.isNotEmpty) {
        logger!.debug('Output: ${runResult.output}');
      }
    }

    if (throwOnError && this.throwOnError && !runResult.success) {
      throw ProcessFailedException(runResult);
    }

    return runResult;
  }

  /// Run flutter_scaffold CLI command.
  Future<ProcessRunResult> runScaffold(
    List<String> args, {
    String? workingDirectory,
  }) {
    return run('flutter_scaffold', args, workingDirectory: workingDirectory);
  }

  /// Run flutter command.
  Future<ProcessRunResult> runFlutter(
    List<String> args, {
    String? workingDirectory,
  }) {
    return run('flutter', args, workingDirectory: workingDirectory);
  }

  /// Run dart command.
  Future<ProcessRunResult> runDart(
    List<String> args, {
    String? workingDirectory,
  }) {
    return run('dart', args, workingDirectory: workingDirectory);
  }
}
