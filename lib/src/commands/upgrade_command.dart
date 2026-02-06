/// Upgrade command for self-updating the CLI.
library;

import 'dart:convert';
import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/version.dart';
import '../services/distribution_service.dart';
import '../utils/logger.dart';

/// Command to check for updates and upgrade the CLI.
class UpgradeCommand extends Command<int> {
  UpgradeCommand({DistributionService? distributionService})
    : _distributionService = distributionService ?? DistributionService() {
    argParser
      ..addFlag(
        'check',
        abbr: 'c',
        help: 'Check for updates without installing',
        negatable: false,
      )
      ..addFlag(
        'git',
        abbr: 'g',
        help: 'Upgrade from git repository (advanced users)',
        negatable: false,
      )
      ..addOption(
        'channel',
        help: 'Git channel/branch to use (requires --git)',
        allowed: ['stable', 'beta', 'alpha', 'main'],
        defaultsTo: 'main',
      );
  }

  final DistributionService _distributionService;

  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade flutter_scaffold to the latest version';

  @override
  Future<int> run() async {
    final logger = ScaffoldLogger();
    final args = argResults!;
    final checkOnly = args.flag('check');
    final useGit = args.flag('git');
    final channel = args.option('channel');

    logger.header('Flutter Scaffold Upgrade');

    // Get current version
    logger.info('Current version: $appVersion');

    if (checkOnly && !useGit) {
      await _checkUpdates(logger);
      return 0;
    }

    if (useGit) {
      return await _upgradeFromGit(logger, channel);
    } else {
      return await _upgradeFromPub(logger);
    }
  }

  Future<int> _checkUpdates(ScaffoldLogger logger) async {
    final progress = logger.progress('Checking for updates...');
    try {
      final latestVersion = await _getLatestVersion();
      if (latestVersion == null) {
        progress.fail('Failed to check for updates');
        return 1;
      }
      progress.complete('Latest version: $latestVersion');

      if (_isNewerVersion(latestVersion, appVersion)) {
        logger.info('');
        logger.success('🎉 A new version is available!');
        logger.info('  Current: $appVersion');
        logger.info('  Latest:  $latestVersion');
        logger.info('');
        logger.info('Run `flutter_scaffold upgrade` to install.');
      } else {
        logger.info('');
        logger.success('✓ You are already on the latest version!');
      }
      return 0;
    } catch (e) {
      progress.fail('Error checking for updates');
      return 1;
    }
  }

  Future<int> _upgradeFromPub(ScaffoldLogger logger) async {
    // Check updates first
    final latestVersion = await _getLatestVersion();
    if (latestVersion != null && !_isNewerVersion(latestVersion, appVersion)) {
      final confirm = logger.confirm(
        'You are already on the latest version. Re-install?',
        defaultValue: false,
      );
      if (!confirm) return 0;
    }

    final progress = logger.progress('Upgrading from pub.dev...');
    final result = await Process.run('dart', [
      'pub',
      'global',
      'activate',
      'flutter_scaffold',
    ]);

    return _handleUpgradeResult(logger, progress, result);
  }

  Future<int> _upgradeFromGit(ScaffoldLogger logger, String? channel) async {
    final progress = logger.progress('Upgrading from git ($channel)...');

    final result = await Process.run('dart', [
      'pub',
      'global',
      'activate',
      '-sgit',
      'https://github.com/jinto-ag/flutter_scaffold',
      '--git-ref',
      channel ?? 'main',
    ]);

    return _handleUpgradeResult(logger, progress, result);
  }

  Future<int> _handleUpgradeResult(
    ScaffoldLogger logger,
    Progress progress,
    ProcessResult result,
  ) async {
    if (result.exitCode == 0) {
      progress.complete('Upgraded successfully!');
      logger.success('');
      logger.success('🚀 flutter_scaffold has been upgraded');

      // Bundle artifacts into current project if applicable
      if (File('pubspec.yaml').existsSync()) {
        logger.info('');
        logger.info('Updating local project artifacts...');
        await _distributionService.bundleArtifacts(
          targetDir: Directory.current.path,
        );
      }

      return 0;
    } else {
      progress.fail('Upgrade failed');
      logger.error(result.stderr.toString());
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
