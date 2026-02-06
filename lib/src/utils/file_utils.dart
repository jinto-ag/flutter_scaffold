/// File system utilities for the Flutter Scaffold CLI.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/errors.dart';

/// Utility class for file system operations.
class FileUtils {
  const FileUtils();

  /// Check if a directory exists.
  bool directoryExists(String path) => Directory(path).existsSync();

  /// Check if a file exists.
  bool fileExists(String path) => File(path).existsSync();

  /// Create a directory and all parent directories.
  ///
  /// Returns true if the directory was created, false if it already exists.
  bool createDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) return false;
    dir.createSync(recursive: true);
    return true;
  }

  /// Create a file with the given content.
  ///
  /// Creates parent directories if they don't exist.
  /// If [force] is true, overwrites existing files.
  /// Returns true if the file was created/written, false if skipped.
  bool createFile(String path, String content, {bool force = false}) {
    final file = File(path);

    if (file.existsSync() && !force) {
      return false;
    }

    // Ensure parent directory exists
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }

    file.writeAsStringSync(content);
    return true;
  }

  /// Delete a directory and all its contents.
  void deleteDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  }

  /// Read file contents as string.
  String readFile(String path) {
    final file = File(path);
    return file.readAsStringSync();
  }

  /// Write content to a file, overwriting existing content.
  void writeFile(String path, String content) {
    final file = File(path);
    file.writeAsStringSync(content);
  }

  /// Delete a file.
  void deleteFile(String path) {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  /// Copy a file to a destination.
  void copyFile(String source, String destination) {
    final sourceFile = File(source);
    if (!sourceFile.existsSync()) {
      throw FileSystemException('Source file does not exist: $source');
    }

    // Ensure destination parent exists
    final destParent = Directory(p.dirname(destination));
    if (!destParent.existsSync()) {
      destParent.createSync(recursive: true);
    }

    sourceFile.copySync(destination);
  }

  /// Make a file executable (chmod +x on Unix systems).
  void makeExecutable(String path) {
    if (Platform.isLinux || Platform.isMacOS) {
      Process.runSync('chmod', ['+x', path]);
    }
  }

  /// List all files in a directory (recursive).
  List<FileSystemEntity> listFiles(String path, {bool recursive = false}) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    return dir.listSync(recursive: recursive).toList();
  }

  /// Count files in a directory.
  int countFiles(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return 0;

    return dir.listSync(recursive: true).whereType<File>().length;
  }

  /// Count directories in a directory.
  int countDirectories(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return 0;

    return dir.listSync(recursive: true).whereType<Directory>().length;
  }

  /// Get all subdirectories of a directory (non-recursive).
  List<String> listSubdirectories(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return [];

    return dir
        .listSync()
        .whereType<Directory>()
        .map((d) => p.basename(d.path))
        .toList()
      ..sort();
  }

  /// Get the current working directory.
  String get currentDirectory => Directory.current.path;

  /// Join path segments.
  String joinPath(String part1, [String? part2, String? part3, String? part4]) {
    return p.join(part1, part2, part3, part4);
  }

  /// Get the directory name from a path.
  String dirname(String path) => p.dirname(path);

  /// Get the base name from a path.
  String basename(String path) => p.basename(path);

  /// Normalize a path.
  String normalize(String path) => p.normalize(path);

  /// Check if pubspec.yaml exists in the given directory.
  bool isFlutterProject(String path) {
    return fileExists(joinPath(path, 'pubspec.yaml'));
  }

  /// Get the project name from pubspec.yaml.
  String? getProjectName(String projectPath) {
    final pubspecPath = joinPath(projectPath, 'pubspec.yaml');
    if (!fileExists(pubspecPath)) return null;

    try {
      final content = readFile(pubspecPath);

      // Simple regex to extract 'name: project_name'
      final nameMatch = RegExp(
        r'^name:\s*(\S+)',
        multiLine: true,
      ).firstMatch(content);
      return nameMatch?.group(1);
    } catch (e) {
      return null;
    }
  }

  /// Get the size of a directory in human-readable format.
  String getDirectorySize(String path) {
    final dir = Directory(path);
    if (!dir.existsSync()) return 'N/A';

    var totalSize = 0;
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        totalSize += entity.lengthSync();
      }
    }

    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024) {
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    }
    if (totalSize < 1024 * 1024 * 1024) {
      return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
