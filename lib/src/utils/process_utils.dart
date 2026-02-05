/// Process execution utilities for the Flutter Scaffold CLI.
library;

import 'dart:io';

import '../core/errors.dart';
import 'logger.dart';

/// Result of a process execution.
class ProcessResult {
  const ProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  bool get success => exitCode == 0;
}

/// Utility class for executing external processes.
class ProcessUtils {
  ProcessUtils({ScaffoldLogger? logger}) : _logger = logger;

  final ScaffoldLogger? _logger;

  /// Run a process and wait for completion.
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool showOutput = true,
  }) async {
    _logger?.debug('Running: $executable ${arguments.join(' ')}');

    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );

    final stdout = StringBuffer();
    final stderr = StringBuffer();

    // Stream output if requested
    process.stdout.transform(const SystemEncoding().decoder).listen((data) {
      stdout.write(data);
      if (showOutput) {
        // ignore: avoid_print
        print(data);
      }
    });

    process.stderr.transform(const SystemEncoding().decoder).listen((data) {
      stderr.write(data);
      if (showOutput) {
        // ignore: avoid_print
        print(data);
      }
    });

    final exitCode = await process.exitCode;

    return ProcessResult(
      exitCode: exitCode,
      stdout: stdout.toString(),
      stderr: stderr.toString(),
    );
  }

  /// Run a process and throw on failure.
  Future<ProcessResult> runOrThrow(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    bool showOutput = true,
    String? errorMessage,
  }) async {
    final result = await run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );

    if (!result.success) {
      throw ProcessException(
        errorMessage ?? 'Process failed: $executable ${arguments.join(' ')}',
        exitCode: result.exitCode,
      );
    }

    return result;
  }

  /// Run Flutter command.
  Future<ProcessResult> flutter(
    List<String> arguments, {
    String? workingDirectory,
    bool showOutput = true,
  }) async {
    return run(
      'flutter',
      arguments,
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );
  }

  /// Run Dart command.
  Future<ProcessResult> dart(
    List<String> arguments, {
    String? workingDirectory,
    bool showOutput = true,
  }) async {
    return run(
      'dart',
      arguments,
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );
  }

  /// Run flutter pub add with dependencies.
  Future<ProcessResult> pubAdd(
    List<String> packages, {
    String? workingDirectory,
    bool isDev = false,
    bool showOutput = true,
  }) async {
    final args = ['pub', 'add'];
    if (isDev) args.add('--dev');
    args.addAll(packages);

    return flutter(
      args,
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );
  }

  /// Run flutter pub get.
  Future<ProcessResult> pubGet({
    String? workingDirectory,
    bool showOutput = true,
  }) async {
    return flutter(
      ['pub', 'get'],
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );
  }

  /// Run build_runner.
  Future<ProcessResult> buildRunner({
    String? workingDirectory,
    bool deleteConflicting = true,
    bool showOutput = true,
  }) async {
    final args = ['run', 'build_runner', 'build'];
    if (deleteConflicting) args.add('--delete-conflicting-outputs');

    return dart(
      args,
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );
  }

  /// Run flutter analyze.
  Future<ProcessResult> analyze({
    String? workingDirectory,
    bool showOutput = true,
  }) async {
    return flutter(
      ['analyze'],
      workingDirectory: workingDirectory,
      showOutput: showOutput,
    );
  }

  /// Run flutter create.
  Future<ProcessResult> createProject(
    String projectPath, {
    String? org,
    String? description,
    List<String>? platforms,
    List<String> extraArgs = const [],
    bool showOutput = true,
  }) async {
    final args = ['create'];

    if (org != null) {
      args.addAll(['--org', org]);
    }

    if (description != null) {
      args.addAll(['--description', description]);
    }

    if (platforms != null && platforms.isNotEmpty) {
      args.addAll(['--platforms', platforms.join(',')]);
    }

    args.addAll(extraArgs);
    args.add(projectPath);

    return flutter(args, showOutput: showOutput);
  }
}
