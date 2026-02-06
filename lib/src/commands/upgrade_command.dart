/// Upgrade command for self-updating the CLI.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/version.dart';
import '../utils/logger.dart';

/// Command to check for updates and upgrade the CLI.
class UpgradeCommand extends Command<int> {
  UpgradeCommand() {
    argParser.addFlag(
      'check',
      abbr: 'c',
      help: 'Check for updates without installing',
      negatable: false,
    );
  }

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade flutter_scaffold to the latest version';

  @override
  Future<int> run() async {
    final logger = ScaffoldLogger();
    final checkOnly = argResults?.flag('check') ?? false;

    logger.header('Flutter Scaffold Upgrade');

    // Get current version
    logger.info('Current version: $appVersion');

    // Check latest version from pub.dev
    final progress = logger.progress('Checking for updates...');
    try {
      final latestVersion = await _getLatestVersion();

      if (latestVersion == null) {
        progress.fail('Failed to check for updates');
        logger.warn('Could not reach pub.dev. Check your internet connection.');
        return 1;
      }

      progress.complete('Latest version: $latestVersion');

      // Compare versions
      if (_isNewerVersion(latestVersion, appVersion)) {
        logger.info('');
        logger.success('🎉 A new version is available!');
        logger.info('  Current: $appVersion');
        logger.info('  Latest:  $latestVersion');
        logger.info('');

        if (checkOnly) {
          logger.info('Run `flutter_scaffold upgrade` to install.');
          return 0;
        }

        // Confirm upgrade
        final confirm = logger.confirm(
          'Would you like to upgrade now?',
          defaultValue: true,
        );

        if (!confirm) {
          logger.info('Upgrade cancelled.');
          return 0;
        }

        // Perform upgrade
        final upgradeProgress = logger.progress('Upgrading...');

        final result = await Process.run('dart', [
          'pub',
          'global',
          'activate',
          'flutter_scaffold',
        ], workingDirectory: Directory.current.path);

        if (result.exitCode == 0) {
          upgradeProgress.complete('Upgraded successfully!');
          logger.success('');
          logger.success(
            '🚀 flutter_scaffold has been upgraded to $latestVersion',
          );
          logger.info('');
          logger.info(
            'Changelog: https://pub.dev/packages/flutter_scaffold/changelog',
          );
          return 0;
        } else {
          upgradeProgress.fail('Upgrade failed');
          logger.error(result.stderr.toString());
          return 1;
        }
      } else {
        logger.info('');
        logger.success('✓ You are already on the latest version!');
        return 0;
      }
    } catch (e) {
      progress.fail('Error checking for updates');
      logger.error('Error: $e');
      return 1;
    }
  }

  /// Get the latest version from pub.dev using HttpClient.
  Future<String?> _getLatestVersion() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(
        Uri.parse('https://pub.dev/api/packages/flutter_scaffold'),
      );
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['latest']?['version'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if version1 is newer than version2.
  bool _isNewerVersion(String version1, String version2) {
    try {
      final v1Parts = version1.split('.').map(int.parse).toList();
      final v2Parts = version2.split('.').map(int.parse).toList();

      for (var i = 0; i < v1Parts.length && i < v2Parts.length; i++) {
        if (v1Parts[i] > v2Parts[i]) return true;
        if (v1Parts[i] < v2Parts[i]) return false;
      }

      return v1Parts.length > v2Parts.length;
    } catch (e) {
      return false;
    }
  }
}
