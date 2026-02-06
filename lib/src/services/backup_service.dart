/// Backup service for safely backing up and restoring files.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/logger.dart';

/// Result of a backup operation.
class BackupResult {
  const BackupResult({
    required this.backupId,
    required this.backupPath,
    required this.filesBackedUp,
    required this.timestamp,
  });

  /// Unique identifier for this backup (timestamp-based).
  final String backupId;

  /// Path to the backup directory.
  final String backupPath;

  /// List of files that were backed up.
  final List<String> filesBackedUp;

  /// When the backup was created.
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'backupPath': backupPath,
    'filesBackedUp': filesBackedUp,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BackupResult.fromJson(Map<String, dynamic> json) => BackupResult(
    backupId: json['backupId'] as String,
    backupPath: json['backupPath'] as String,
    filesBackedUp: List<String>.from(json['filesBackedUp'] as List),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Entry in the backup index.
class BackupEntry {
  const BackupEntry({
    required this.backupId,
    required this.operationName,
    required this.filesBackedUp,
    required this.timestamp,
  });

  final String backupId;
  final String operationName;
  final List<String> filesBackedUp;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'operationName': operationName,
    'filesBackedUp': filesBackedUp,
    'timestamp': timestamp.toIso8601String(),
  };

  factory BackupEntry.fromJson(Map<String, dynamic> json) => BackupEntry(
    backupId: json['backupId'] as String,
    operationName: json['operationName'] as String,
    filesBackedUp: List<String>.from(json['filesBackedUp'] as List),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// Service for backing up and restoring project files.
class BackupService {
  BackupService({ScaffoldLogger? logger})
    : _logger = logger ?? ScaffoldLogger();

  final ScaffoldLogger _logger;

  /// The backup directory name within the project.
  static const String backupDirName = '.flutter_scaffold/backups';

  /// Get the backup directory path for a project.
  String _getBackupDir(String projectPath) =>
      p.join(projectPath, backupDirName);

  /// Get the backup index file path.
  String _getIndexPath(String projectPath) =>
      p.join(_getBackupDir(projectPath), 'index.json');

  /// Backup specified files before an operation.
  ///
  /// [projectPath] - Root path of the project.
  /// [paths] - Relative paths of files/directories to backup.
  /// [operationName] - Name of the operation (for logging).
  Future<BackupResult> backup({
    required String projectPath,
    required List<String> paths,
    String operationName = 'unknown',
  }) async {
    final timestamp = DateTime.now();
    final backupId = timestamp.millisecondsSinceEpoch.toString();
    final backupPath = p.join(_getBackupDir(projectPath), backupId);
    final backedUpFiles = <String>[];

    _logger.section('Creating backup ($operationName)...');

    // Create backup directory
    final backupDir = Directory(backupPath);
    if (!backupDir.existsSync()) {
      backupDir.createSync(recursive: true);
    }

    // Backup each path
    for (final relativePath in paths) {
      final sourcePath = p.join(projectPath, relativePath);
      final destPath = p.join(backupPath, relativePath);

      if (FileSystemEntity.isFileSync(sourcePath)) {
        await _backupFile(sourcePath, destPath);
        backedUpFiles.add(relativePath);
      } else if (FileSystemEntity.isDirectorySync(sourcePath)) {
        await _backupDirectory(sourcePath, destPath);
        backedUpFiles.add(relativePath);
      }
    }

    // Update index
    final entry = BackupEntry(
      backupId: backupId,
      operationName: operationName,
      filesBackedUp: backedUpFiles,
      timestamp: timestamp,
    );
    await _addToIndex(projectPath, entry);

    final result = BackupResult(
      backupId: backupId,
      backupPath: backupPath,
      filesBackedUp: backedUpFiles,
      timestamp: timestamp,
    );

    _logger.success(
      'Backup created: $backupId (${backedUpFiles.length} items)',
    );
    return result;
  }

  /// Backup a single file.
  Future<void> _backupFile(String source, String dest) async {
    final destFile = File(dest);
    final destDir = destFile.parent;
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }
    await File(source).copy(dest);
  }

  /// Backup a directory recursively.
  Future<void> _backupDirectory(String source, String dest) async {
    final sourceDir = Directory(source);
    final destDir = Directory(dest);

    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    await for (final entity in sourceDir.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: source);
      final destPath = p.join(dest, relativePath);

      if (entity is File) {
        await _backupFile(entity.path, destPath);
      } else if (entity is Directory) {
        Directory(destPath).createSync(recursive: true);
      }
    }
  }

  /// Restore files from a specific backup.
  ///
  /// [projectPath] - Root path of the project.
  /// [backupId] - ID of the backup to restore from.
  Future<void> restore({
    required String projectPath,
    required String backupId,
  }) async {
    final backupPath = p.join(_getBackupDir(projectPath), backupId);
    final backupDir = Directory(backupPath);

    if (!backupDir.existsSync()) {
      throw ArgumentError('Backup not found: $backupId');
    }

    _logger.section('Restoring from backup $backupId...');

    // Get backup entry to know what was backed up
    final entries = listBackups(projectPath);
    final entry = entries.firstWhere(
      (e) => e.backupId == backupId,
      orElse: () => throw ArgumentError('Backup entry not found: $backupId'),
    );

    var restoredCount = 0;

    // Restore each backed up path
    for (final relativePath in entry.filesBackedUp) {
      final sourcePath = p.join(backupPath, relativePath);
      final destPath = p.join(projectPath, relativePath);

      if (FileSystemEntity.isFileSync(sourcePath)) {
        await _backupFile(sourcePath, destPath);
        restoredCount++;
      } else if (FileSystemEntity.isDirectorySync(sourcePath)) {
        await _restoreDirectory(sourcePath, destPath);
        restoredCount++;
      }
    }

    _logger.success('Restored $restoredCount items from backup $backupId');
  }

  /// Restore a directory recursively.
  Future<void> _restoreDirectory(String source, String dest) async {
    final sourceDir = Directory(source);
    final destDir = Directory(dest);

    // Remove existing destination if it exists
    if (destDir.existsSync()) {
      destDir.deleteSync(recursive: true);
    }
    destDir.createSync(recursive: true);

    await for (final entity in sourceDir.list(recursive: true)) {
      final relativePath = p.relative(entity.path, from: source);
      final destPath = p.join(dest, relativePath);

      if (entity is File) {
        await _backupFile(entity.path, destPath);
      } else if (entity is Directory) {
        Directory(destPath).createSync(recursive: true);
      }
    }
  }

  /// List all available backups for a project.
  List<BackupEntry> listBackups(String projectPath) {
    final indexPath = _getIndexPath(projectPath);
    final indexFile = File(indexPath);

    if (!indexFile.existsSync()) {
      return [];
    }

    try {
      final content = indexFile.readAsStringSync();
      final List<dynamic> entries = jsonDecode(content) as List<dynamic>;
      return entries
          .map((e) => BackupEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } catch (e) {
      _logger.warn('Failed to read backup index: $e');
      return [];
    }
  }

  /// Add a backup entry to the index.
  Future<void> _addToIndex(String projectPath, BackupEntry entry) async {
    final indexPath = _getIndexPath(projectPath);
    final indexFile = File(indexPath);

    List<BackupEntry> entries = [];
    if (indexFile.existsSync()) {
      try {
        final content = indexFile.readAsStringSync();
        final List<dynamic> existing = jsonDecode(content) as List<dynamic>;
        entries = existing
            .map((e) => BackupEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Start fresh if index is corrupted
      }
    } else {
      indexFile.parent.createSync(recursive: true);
    }

    entries.add(entry);

    // Keep only last 10 backups
    if (entries.length > 10) {
      final toRemove = entries.sublist(0, entries.length - 10);
      for (final old in toRemove) {
        final oldPath = p.join(_getBackupDir(projectPath), old.backupId);
        final oldDir = Directory(oldPath);
        if (oldDir.existsSync()) {
          oldDir.deleteSync(recursive: true);
        }
      }
      entries = entries.sublist(entries.length - 10);
    }

    final json = entries.map((e) => e.toJson()).toList();
    indexFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  /// Delete a specific backup.
  Future<void> deleteBackup(String projectPath, String backupId) async {
    final backupPath = p.join(_getBackupDir(projectPath), backupId);
    final backupDir = Directory(backupPath);

    if (backupDir.existsSync()) {
      backupDir.deleteSync(recursive: true);
    }

    // Remove from index
    final indexPath = _getIndexPath(projectPath);
    final indexFile = File(indexPath);

    if (indexFile.existsSync()) {
      try {
        final content = indexFile.readAsStringSync();
        final List<dynamic> existing = jsonDecode(content) as List<dynamic>;
        final entries = existing
            .map((e) => BackupEntry.fromJson(e as Map<String, dynamic>))
            .where((e) => e.backupId != backupId)
            .toList();

        final json = entries.map((e) => e.toJson()).toList();
        indexFile.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(json),
        );
      } catch (e) {
        // Ignore index errors
      }
    }

    _logger.success('Deleted backup: $backupId');
  }
}
