/// File system helpers for tests.
///
/// Provides utilities for file assertions, directory setup, and cleanup.
library;

import 'dart:io';

/// File system assertion helpers.
class FileAssertions {
  /// Assert that a file exists at the given path.
  static void expectFile(String path, {String? message}) {
    if (!File(path).existsSync()) {
      throw TestAssertionException(message ?? 'Expected file not found: $path');
    }
  }

  /// Assert that a directory exists at the given path.
  static void expectDir(String path, {String? message}) {
    if (!Directory(path).existsSync()) {
      throw TestAssertionException(
        message ?? 'Expected directory not found: $path',
      );
    }
  }

  /// Assert that a file does NOT exist.
  static void expectNoFile(String path, {String? message}) {
    if (File(path).existsSync()) {
      throw TestAssertionException(
        message ?? 'Expected file to NOT exist: $path',
      );
    }
  }

  /// Assert that a directory does NOT exist.
  static void expectNoDir(String path, {String? message}) {
    if (Directory(path).existsSync()) {
      throw TestAssertionException(
        message ?? 'Expected directory to NOT exist: $path',
      );
    }
  }

  /// Assert that a file contains specific content.
  static void expectFileContains(
    String path,
    String content, {
    String? message,
  }) {
    expectFile(path);
    final fileContent = File(path).readAsStringSync();
    if (!fileContent.contains(content)) {
      throw TestAssertionException(
        message ?? 'Expected file $path to contain: $content',
      );
    }
  }
}

/// Exception for test assertion failures.
class TestAssertionException implements Exception {
  final String message;
  const TestAssertionException(this.message);

  @override
  String toString() => message;
}

/// Temporary directory manager for tests.
class TempDirectoryManager {
  Directory? _tempDir;

  /// Get or create a temporary directory.
  Directory get tempDir {
    _tempDir ??= Directory.systemTemp.createTempSync('flutter_scaffold_test_');
    return _tempDir!;
  }

  /// Create a subdirectory in the temp directory.
  Directory createSubDir(String name) {
    final dir = Directory('${tempDir.path}/$name');
    dir.createSync(recursive: true);
    return dir;
  }

  /// Clean up the temporary directory.
  void cleanup({bool force = false}) {
    if (_tempDir != null && _tempDir!.existsSync()) {
      try {
        _tempDir!.deleteSync(recursive: true);
      } catch (e) {
        if (force) rethrow;
        // Ignore cleanup errors by default
      }
      _tempDir = null;
    }
  }
}
