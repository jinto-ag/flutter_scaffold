/// Cache manager for E2E tests.
///
/// Uses file hashes to skip unchanged test steps.
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// Cache manager for E2E test step results.
///
/// Computes file hashes to determine if test steps need to be re-run.
class CacheManager {
  final String cacheDir;
  final String projectRoot;
  late final File _cacheFile;
  Map<String, dynamic> _cache = {};

  CacheManager({required this.projectRoot, String? cacheDir})
    : cacheDir = cacheDir ?? '$projectRoot/.flutter_scaffold' {
    _cacheFile = File('${this.cacheDir}/e2e_cache.json');
    _loadCache();
  }

  void _loadCache() {
    if (_cacheFile.existsSync()) {
      try {
        final content = _cacheFile.readAsStringSync();
        _cache = jsonDecode(content) as Map<String, dynamic>;
      } catch (e) {
        _cache = {};
      }
    }
  }

  void _saveCache() {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    _cacheFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(_cache),
    );
  }

  /// Compute MD5 hash of file contents.
  String _computeFileHash(String path) {
    final file = File(path);
    if (!file.existsSync()) return '';
    final bytes = file.readAsBytesSync();
    return md5.convert(bytes).toString();
  }

  /// Compute combined hash for a list of file paths.
  String computeFilesHash(List<String> paths) {
    final hashes = <String>[];
    for (final path in paths) {
      hashes.add(_computeFileHash(path));
    }
    hashes.sort();
    final combined = hashes.join('|');
    return md5.convert(utf8.encode(combined)).toString();
  }

  /// Get all files matching a glob pattern recursively.
  List<String> getFilesMatching(String basePath, String pattern) {
    final files = <String>[];
    final dir = Directory(basePath);
    if (!dir.existsSync()) return files;

    for (final entity in dir.listSync(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(basePath.length + 1);
        if (_matchesPattern(relativePath, pattern)) {
          files.add(entity.path);
        }
      }
    }
    return files;
  }

  bool _matchesPattern(String path, String pattern) {
    // Simple glob matching for *.template and *.dart patterns
    if (pattern.contains('**')) {
      final suffix = pattern.replaceAll('**/', '').replaceAll('*', '');
      return path.endsWith(suffix);
    }
    final suffix = pattern.replaceAll('*', '');
    return path.endsWith(suffix);
  }

  /// Check if a step is cached and valid.
  bool isStepCached(String stepName, List<String> dependencyFiles) {
    if (!_cache.containsKey('steps')) return false;
    final steps = _cache['steps'] as Map<String, dynamic>?;
    if (steps == null || !steps.containsKey(stepName)) return false;

    final stepData = steps[stepName] as Map<String, dynamic>;
    final cachedHash = stepData['hash'] as String?;
    if (cachedHash == null) return false;

    final currentHash = computeFilesHash(dependencyFiles);
    return cachedHash == currentHash;
  }

  /// Mark a step as completed with its dependency hash.
  void markStepComplete(
    String stepName,
    List<String> dependencyFiles, {
    bool passed = true,
  }) {
    _cache['steps'] ??= <String, dynamic>{};
    final steps = _cache['steps'] as Map<String, dynamic>;
    steps[stepName] = {
      'hash': computeFilesHash(dependencyFiles),
      'passed': passed,
      'timestamp': DateTime.now().toIso8601String(),
    };
    _saveCache();
  }

  /// Invalidate cache for a specific step.
  void invalidateStep(String stepName) {
    if (_cache.containsKey('steps')) {
      final steps = _cache['steps'] as Map<String, dynamic>;
      steps.remove(stepName);
      _saveCache();
    }
  }

  /// Clear all cache.
  void clearAll() {
    _cache = {};
    if (_cacheFile.existsSync()) {
      _cacheFile.deleteSync();
    }
  }

  /// Get cache statistics.
  CacheStats getStats() {
    final steps = _cache['steps'] as Map<String, dynamic>? ?? {};
    int passedCount = 0;
    int failedCount = 0;
    DateTime? oldestRun;
    DateTime? newestRun;

    for (final entry in steps.entries) {
      final data = entry.value as Map<String, dynamic>;
      if (data['passed'] == true) {
        passedCount++;
      } else {
        failedCount++;
      }
      final timestamp = DateTime.tryParse(data['timestamp'] as String? ?? '');
      if (timestamp != null) {
        if (oldestRun == null || timestamp.isBefore(oldestRun)) {
          oldestRun = timestamp;
        }
        if (newestRun == null || timestamp.isAfter(newestRun)) {
          newestRun = timestamp;
        }
      }
    }

    return CacheStats(
      totalCached: steps.length,
      passedCount: passedCount,
      failedCount: failedCount,
      oldestRun: oldestRun,
      newestRun: newestRun,
      cacheFilePath: _cacheFile.path,
    );
  }

  /// Get list of cached step names.
  List<String> getCachedSteps() {
    final steps = _cache['steps'] as Map<String, dynamic>? ?? {};
    return steps.keys.toList();
  }
}

/// Cache statistics.
class CacheStats {
  const CacheStats({
    required this.totalCached,
    required this.passedCount,
    required this.failedCount,
    this.oldestRun,
    this.newestRun,
    required this.cacheFilePath,
  });

  final int totalCached;
  final int passedCount;
  final int failedCount;
  final DateTime? oldestRun;
  final DateTime? newestRun;
  final String cacheFilePath;

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Cache Statistics:');
    buffer.writeln('  Total cached steps: $totalCached');
    buffer.writeln('  Passed: $passedCount');
    buffer.writeln('  Failed: $failedCount');
    if (oldestRun != null) {
      buffer.writeln('  Oldest run: $oldestRun');
    }
    if (newestRun != null) {
      buffer.writeln('  Newest run: $newestRun');
    }
    buffer.writeln('  Cache file: $cacheFilePath');
    return buffer.toString();
  }
}
