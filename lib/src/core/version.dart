/// Version utility for dynamically parsing version from pubspec.yaml.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

/// Parses and caches the version from pubspec.yaml.
class VersionInfo {
  VersionInfo._();

  static String? _cachedVersion;
  static String? _cachedName;

  /// Get the package version from pubspec.yaml.
  ///
  /// Returns the version string or '0.0.0' if parsing fails.
  static String get version {
    if (_cachedVersion != null) return _cachedVersion!;
    _parsePubspec();
    return _cachedVersion ?? '0.0.0';
  }

  /// Get the package name from pubspec.yaml.
  static String get name {
    if (_cachedName != null) return _cachedName!;
    _parsePubspec();
    return _cachedName ?? 'flutter_scaffold';
  }

  /// Parse the pubspec.yaml file to extract version and name.
  static void _parsePubspec() {
    try {
      // Try to find pubspec.yaml in current directory or package root
      final pubspecPath = _findPubspecPath();
      if (pubspecPath == null) {
        _cachedVersion = '0.1.0'; // Fallback
        _cachedName = 'flutter_scaffold';
        return;
      }

      final content = File(pubspecPath).readAsStringSync();

      // Parse version using regex (simple YAML parsing)
      final versionMatch = RegExp(
        r'^version:\s*(.+)$',
        multiLine: true,
      ).firstMatch(content);
      if (versionMatch != null) {
        _cachedVersion = versionMatch.group(1)?.trim();
      }

      // Parse name using regex
      final nameMatch = RegExp(
        r'^name:\s*(.+)$',
        multiLine: true,
      ).firstMatch(content);
      if (nameMatch != null) {
        _cachedName = nameMatch.group(1)?.trim();
      }

      _cachedVersion ??= '0.1.0';
      _cachedName ??= 'flutter_scaffold';
    } catch (e) {
      _cachedVersion = '0.1.0';
      _cachedName = 'flutter_scaffold';
    }
  }

  /// Find the pubspec.yaml path by searching up from script location.
  static String? _findPubspecPath() {
    // First try the package's own pubspec (for when running from source)
    final scriptPath = Platform.script.toFilePath();
    var dir = Directory(p.dirname(scriptPath));

    // Walk up looking for pubspec.yaml
    for (var i = 0; i < 5; i++) {
      final pubspec = File(p.join(dir.path, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        // Verify it's our pubspec
        final content = pubspec.readAsStringSync();
        if (content.contains('name: flutter_scaffold')) {
          return pubspec.path;
        }
      }
      dir = dir.parent;
    }

    return null;
  }

  /// Reset the cached values (useful for testing).
  static void reset() {
    _cachedVersion = null;
    _cachedName = null;
  }
}

/// Convenience getter for the version.
String get appVersion => VersionInfo.version;

/// Convenience getter for the package name.
String get appName => VersionInfo.name;
