/// Test context for E2E tests.
///
/// Provides shared state and utilities for E2E test steps.
library;

import 'dart:io';

import '../utils/test_utils.dart';
import 'cache_manager.dart';

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

  String? _projectPath;
  late final int timestamp;

  E2ETestContext({
    required this.verbose,
    required this.keepProject,
    required this.force,
    required String projectRoot,
    File? logFile,
  }) : logger = TestLogger(verbose: verbose, logFile: logFile),
       runner = ProcessRunner(
         logger: TestLogger(verbose: verbose),
         throwOnError: true,
       ),
       tempManager = TempDirectoryManager(),
       cacheManager = CacheManager(projectRoot: projectRoot) {
    timestamp = DateTime.now().millisecondsSinceEpoch;
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
    logger.debug('Timestamp: $timestamp');

    // Verify flutter is available
    try {
      await runner.runFlutter(['--version']);
    } catch (e) {
      throw Exception('Flutter SDK not found. Please install Flutter.');
    }
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

  /// Create a unique project name.
  String uniqueProjectName(String prefix) {
    return '${prefix}_$timestamp';
  }
}
