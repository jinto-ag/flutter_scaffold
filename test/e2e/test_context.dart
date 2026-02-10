/// Test context for E2E tests.
///
/// Provides shared state and utilities for E2E test steps.
library;

import 'dart:convert';
import 'dart:io';

import '../utils/test_utils.dart';
import 'cache_manager.dart';

/// Entry for a command execution log.
class CommandLogEntry {
  final String stepName;
  final String commandName;
  final String description;
  final String command;
  final String logPath;
  final bool success;
  final DateTime timestamp;

  CommandLogEntry({
    required this.stepName,
    required this.commandName,
    required this.description,
    required this.command,
    required this.logPath,
    required this.success,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'step': stepName,
    'command': commandName,
    'description': description,
    'fullCommand': command,
    'log': logPath,
    'success': success,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Shared context for E2E test execution.
///
/// Maintains state across test steps and provides common utilities.
class E2ETestContext {
  final bool verbose;
  final bool keepProject;
  final bool force;
  final TestLogger logger;
  final ProcessRunner runner;
  final TempDirectoryManager tempManager;
  final CacheManager cacheManager;
  final String projectRoot;

  /// Output directory for logs.
  late final Directory outputDir;

  /// Registry of all command executions.
  final List<CommandLogEntry> commandRegistry = [];

  String? _projectPath;
  late final int timestamp;

  E2ETestContext({
    required this.verbose,
    required this.keepProject,
    required this.force,
    required this.projectRoot,
    String? outputPath,
    File? logFile,
  }) : logger = TestLogger(verbose: verbose, logFile: logFile),
       runner = ProcessRunner(
         logger: TestLogger(verbose: verbose),
         throwOnError: true,
       ),
       tempManager = TempDirectoryManager(),
       cacheManager = CacheManager(projectRoot: projectRoot) {
    timestamp = DateTime.now().millisecondsSinceEpoch;
    outputDir = Directory(outputPath ?? '$projectRoot/e2e_test_output');
  }

  /// Get temp directory path.
  String get tempPath => tempManager.tempDir.path;

  /// Get the current project under test.
  String get projectPath {
    if (_projectPath == null) {
      throw StateError('Project path not set. Run "create" step first.');
    }
    return _projectPath!;
  }

  /// Set the project path.
  set projectPath(String value) {
    _projectPath = value;
  }

  /// Check if project path is set.
  bool get hasProject => _projectPath != null;

  /// Setup the test context.
  Future<void> setup() async {
    logger.debug('Setting up E2E test context...');
    logger.debug('Temp directory: $tempPath');
    logger.debug('Output directory: ${outputDir.path}');
    logger.debug('Timestamp: $timestamp');

    // Create output directory
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // Verify flutter is available
    try {
      await runner.runFlutter(['--version']);
    } catch (e) {
      throw Exception('Flutter SDK not found. Please install Flutter.');
    }
  }

  /// Reset output directory.
  void resetOutput() {
    if (outputDir.existsSync()) {
      outputDir.deleteSync(recursive: true);
    }
    outputDir.createSync(recursive: true);
    commandRegistry.clear();
  }

  /// Cleanup the test context.
  Future<void> cleanup() async {
    logger.flush();
    if (!keepProject) {
      logger.info('Cleaning up...');
      tempManager.cleanup();
    } else {
      logger.info('Keeping temp dir at: $tempPath');
    }
  }

  /// Run a command in the current project directory.
  Future<ProcessRunResult> runInProject(String executable, List<String> args) {
    return runner.run(executable, args, workingDirectory: projectPath);
  }

  /// Run flutter_scaffold command in the current project.
  Future<ProcessRunResult> runScaffoldInProject(List<String> args) {
    return runner.runScaffold(args, workingDirectory: projectPath);
  }

  /// Run and log a command with granular output.
  ///
  /// Creates a log file at `outputDir/stepName/commandName.log` and
  /// registers the execution in the command registry.
  ///
  /// Set [throwOnError] to false to continue execution on failure.
  Future<ProcessRunResult?> logCommand({
    required String stepName,
    required String commandName,
    required String description,
    required List<String> args,
    String? workingDirectory,
    bool useScaffold = true,
    bool throwOnError = true,
  }) async {
    // Create step directory
    final stepDir = Directory('${outputDir.path}/$stepName');
    if (!stepDir.existsSync()) {
      stepDir.createSync(recursive: true);
    }

    // Create log file
    final logFile = File('${stepDir.path}/$commandName.log');
    final relativePath = '$stepName/$commandName.log';
    final fullCommand = useScaffold
        ? 'flutter_scaffold ${args.join(' ')}'
        : args.join(' ');

    // Write header
    final buffer = StringBuffer()
      ..writeln('=' * 60)
      ..writeln('Command: $fullCommand')
      ..writeln('Description: $description')
      ..writeln('Timestamp: ${DateTime.now()}')
      ..writeln('Working Directory: ${workingDirectory ?? projectPath}')
      ..writeln('=' * 60)
      ..writeln();

    logger.debug('▶ Running: $description');

    bool success = true;
    ProcessRunResult? result;
    String? errorMessage;

    try {
      if (useScaffold) {
        result = await runner.runScaffold(
          args,
          workingDirectory: workingDirectory ?? projectPath,
        );
      } else {
        result = await runner.run(
          args.first,
          args.skip(1).toList(),
          workingDirectory: workingDirectory ?? projectPath,
        );
      }
      buffer.writeln(result.output);
      buffer.writeln();
      buffer.writeln('[RESULT: SUCCESS]');
      buffer.writeln('[EXIT CODE: ${result.exitCode}]');
      logger.debug('  ✓ Success');
    } catch (e, stackTrace) {
      success = false;
      errorMessage = e.toString();
      buffer.writeln('ERROR: $e');
      buffer.writeln();
      buffer.writeln('STACK TRACE:');
      buffer.writeln(stackTrace.toString());
      buffer.writeln();
      buffer.writeln('[RESULT: FAILED]');
      logger.debug('  ✗ Failed');
    }

    // Always write log file
    logFile.writeAsStringSync(buffer.toString());

    // Register in command registry
    commandRegistry.add(
      CommandLogEntry(
        stepName: stepName,
        commandName: commandName,
        description: description,
        command: fullCommand,
        logPath: relativePath,
        success: success,
        timestamp: DateTime.now(),
      ),
    );

    // Throw if requested and failed
    if (!success && throwOnError) {
      throw Exception('Command failed: $fullCommand\n$errorMessage');
    }

    return result;
  }

  /// Log an error that occurred outside of a command execution.
  void logError({
    required String stepName,
    required String errorName,
    required String description,
    required Object error,
    StackTrace? stackTrace,
  }) {
    final stepDir = Directory('${outputDir.path}/$stepName');
    if (!stepDir.existsSync()) {
      stepDir.createSync(recursive: true);
    }

    final logFile = File('${stepDir.path}/$errorName.log');
    final relativePath = '$stepName/$errorName.log';

    final buffer = StringBuffer()
      ..writeln('=' * 60)
      ..writeln('Error: $description')
      ..writeln('Timestamp: ${DateTime.now()}')
      ..writeln('=' * 60)
      ..writeln()
      ..writeln('ERROR: $error')
      ..writeln();

    if (stackTrace != null) {
      buffer.writeln('STACK TRACE:');
      buffer.writeln(stackTrace.toString());
      buffer.writeln();
    }

    buffer.writeln('[RESULT: FAILED]');
    logFile.writeAsStringSync(buffer.toString());

    commandRegistry.add(
      CommandLogEntry(
        stepName: stepName,
        commandName: errorName,
        description: description,
        command: 'N/A (error)',
        logPath: relativePath,
        success: false,
        timestamp: DateTime.now(),
      ),
    );

    logger.error('Error logged: $description');
  }

  /// Generate index.md and commands.json files.
  void generateIndex() {
    logger.info('Generating index files...');

    // Group commands by step
    final stepGroups = <String, List<CommandLogEntry>>{};
    for (final entry in commandRegistry) {
      stepGroups.putIfAbsent(entry.stepName, () => []).add(entry);
    }

    // Generate index.md
    final mdBuffer = StringBuffer()
      ..writeln('# E2E Test Results')
      ..writeln()
      ..writeln('**Generated:** ${DateTime.now()}')
      ..writeln()
      ..writeln('## Summary')
      ..writeln()
      ..writeln('| Status | Count |')
      ..writeln('|--------|-------|')
      ..writeln(
        '| ✅ Passed | ${commandRegistry.where((e) => e.success).length} |',
      )
      ..writeln(
        '| ❌ Failed | ${commandRegistry.where((e) => !e.success).length} |',
      )
      ..writeln('| **Total** | ${commandRegistry.length} |')
      ..writeln()
      ..writeln('## Commands')
      ..writeln();

    for (final step in stepGroups.keys) {
      mdBuffer
        ..writeln('### ${_capitalize(step)}')
        ..writeln()
        ..writeln('| Status | Command | Log |')
        ..writeln('|--------|---------|-----|');

      for (final entry in stepGroups[step]!) {
        final status = entry.success ? '✅' : '❌';
        mdBuffer.writeln(
          '| $status | ${entry.description} | [${entry.commandName}.log](${entry.logPath}) |',
        );
      }
      mdBuffer.writeln();
    }

    File('${outputDir.path}/index.md').writeAsStringSync(mdBuffer.toString());

    // Generate commands.json
    final jsonData = {
      'generated': DateTime.now().toIso8601String(),
      'summary': {
        'total': commandRegistry.length,
        'passed': commandRegistry.where((e) => e.success).length,
        'failed': commandRegistry.where((e) => !e.success).length,
      },
      'commands': commandRegistry.map((e) => e.toJson()).toList(),
    };

    File(
      '${outputDir.path}/commands.json',
    ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(jsonData));

    logger.success('Generated: ${outputDir.path}/index.md');
    logger.success('Generated: ${outputDir.path}/commands.json');
  }

  /// Create a unique project name.
  String uniqueProjectName(String prefix) {
    return '${prefix}_$timestamp';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
