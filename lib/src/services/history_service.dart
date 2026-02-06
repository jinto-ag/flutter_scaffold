/// History service for tracking operations and enabling revert.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../utils/logger.dart';
import 'backup_service.dart';

/// A single history entry representing an operation.
class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.operation,
    required this.description,
    required this.filesAffected,
    required this.timestamp,
    this.backupId,
  });

  /// Unique identifier (timestamp-based).
  final String id;

  /// Operation type (e.g., 'init', 'add_feature', 'remove_feature').
  final String operation;

  /// Human-readable description.
  final String description;

  /// Files that were created/modified/deleted.
  final List<String> filesAffected;

  /// When the operation occurred.
  final DateTime timestamp;

  /// Associated backup ID (if any).
  final String? backupId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'operation': operation,
    'description': description,
    'filesAffected': filesAffected,
    'timestamp': timestamp.toIso8601String(),
    'backupId': backupId,
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
    id: json['id'] as String,
    operation: json['operation'] as String,
    description: json['description'] as String,
    filesAffected: List<String>.from(json['filesAffected'] as List),
    timestamp: DateTime.parse(json['timestamp'] as String),
    backupId: json['backupId'] as String?,
  );
}

/// Service for tracking operation history and enabling revert.
class HistoryService {
  HistoryService({ScaffoldLogger? logger, BackupService? backupService})
    : _logger = logger ?? ScaffoldLogger(),
      _backupService = backupService ?? BackupService();

  final ScaffoldLogger _logger;
  final BackupService _backupService;

  /// History file path within the project.
  static const String historyFileName = '.flutter_scaffold/history.json';

  /// Get the history file path for a project.
  String _getHistoryPath(String projectPath) =>
      p.join(projectPath, historyFileName);

  /// Record an operation in the history.
  ///
  /// [projectPath] - Root path of the project.
  /// [operation] - Operation type identifier.
  /// [description] - Human-readable description.
  /// [filesAffected] - List of relative file paths affected.
  /// [backupId] - Optional backup ID associated with this operation.
  Future<HistoryEntry> record({
    required String projectPath,
    required String operation,
    required String description,
    required List<String> filesAffected,
    String? backupId,
  }) async {
    final timestamp = DateTime.now();
    final id = timestamp.millisecondsSinceEpoch.toString();

    final entry = HistoryEntry(
      id: id,
      operation: operation,
      description: description,
      filesAffected: filesAffected,
      timestamp: timestamp,
      backupId: backupId,
    );

    await _addToHistory(projectPath, entry);
    _logger.info('Recorded: $description');

    return entry;
  }

  /// Get all history entries for a project.
  List<HistoryEntry> getHistory(String projectPath) {
    final historyPath = _getHistoryPath(projectPath);
    final historyFile = File(historyPath);

    if (!historyFile.existsSync()) {
      return [];
    }

    try {
      final content = historyFile.readAsStringSync();
      final List<dynamic> entries = jsonDecode(content) as List<dynamic>;
      return entries
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Newest first
    } catch (e) {
      _logger.warn('Failed to read history: $e');
      return [];
    }
  }

  /// Revert to a specific history point by restoring associated backup.
  ///
  /// This will restore the project state from BEFORE the specified operation.
  Future<bool> revertTo(String projectPath, String historyId) async {
    final entries = getHistory(projectPath);
    final entry = entries.firstWhere(
      (e) => e.id == historyId,
      orElse: () => throw ArgumentError('History entry not found: $historyId'),
    );

    if (entry.backupId == null) {
      _logger.error('No backup associated with this operation');
      return false;
    }

    _logger.section('Reverting: ${entry.description}...');

    try {
      await _backupService.restore(
        projectPath: projectPath,
        backupId: entry.backupId!,
      );

      // Remove this entry and all newer entries from history
      await _removeEntriesAfter(projectPath, historyId);

      _logger.success('Reverted successfully');
      return true;
    } catch (e) {
      _logger.error('Failed to revert: $e');
      return false;
    }
  }

  /// Add an entry to the history file.
  Future<void> _addToHistory(String projectPath, HistoryEntry entry) async {
    final historyPath = _getHistoryPath(projectPath);
    final historyFile = File(historyPath);

    List<HistoryEntry> entries = [];
    if (historyFile.existsSync()) {
      try {
        final content = historyFile.readAsStringSync();
        final List<dynamic> existing = jsonDecode(content) as List<dynamic>;
        entries = existing
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Start fresh if corrupted
      }
    } else {
      historyFile.parent.createSync(recursive: true);
    }

    entries.add(entry);

    // Keep only last 50 entries
    if (entries.length > 50) {
      entries = entries.sublist(entries.length - 50);
    }

    final json = entries.map((e) => e.toJson()).toList();
    historyFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }

  /// Remove history entries from the specified ID onwards (including it).
  Future<void> _removeEntriesAfter(String projectPath, String historyId) async {
    final historyPath = _getHistoryPath(projectPath);
    final historyFile = File(historyPath);

    if (!historyFile.existsSync()) return;

    try {
      final content = historyFile.readAsStringSync();
      final List<dynamic> existing = jsonDecode(content) as List<dynamic>;
      final entries = existing
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      // Find the entry index and remove it and all after
      final index = entries.indexWhere((e) => e.id == historyId);
      if (index >= 0) {
        entries.removeRange(index, entries.length);
      }

      final json = entries.map((e) => e.toJson()).toList();
      historyFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(json),
      );
    } catch (e) {
      _logger.warn('Failed to clean history: $e');
    }
  }

  /// Get the most recent history entry.
  HistoryEntry? getLastEntry(String projectPath) {
    final entries = getHistory(projectPath);
    return entries.isNotEmpty ? entries.first : null;
  }

  /// Clear all history for a project.
  Future<void> clearHistory(String projectPath) async {
    final historyPath = _getHistoryPath(projectPath);
    final historyFile = File(historyPath);

    if (historyFile.existsSync()) {
      historyFile.deleteSync();
      _logger.success('History cleared');
    }
  }
}
