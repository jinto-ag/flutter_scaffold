import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/constants.dart';
import '../utils/file_utils.dart';
import '../utils/logger.dart';
import '../utils/process_utils.dart';

/// Service to handle distribution of CLI executable and VSCode extension.
class DistributionService {
  final ScaffoldLogger _logger;
  final FileUtils _fileUtils;
  final ProcessUtils _processUtils;

  DistributionService({
    ScaffoldLogger? logger,
    FileUtils? fileUtils,
    ProcessUtils? processUtils,
  }) : _logger = logger ?? ScaffoldLogger(),
       _fileUtils = fileUtils ?? const FileUtils(),
       _processUtils = processUtils ?? ProcessUtils();

  /// Compiles the CLI executable.
  Future<File?> compileCli({
    required String sourceDir,
    required String outputDir,
  }) async {
    final progress = _logger.progress('Compiling CLI executable...');
    try {
      final binPath = p.join(sourceDir, 'bin', 'flutter_scaffold.dart');
      final outputPath = p.join(outputDir, executableName);

      if (!await Directory(outputDir).exists()) {
        await Directory(outputDir).create(recursive: true);
      }

      await _processUtils.run('dart', [
        'compile',
        'exe',
        binPath,
        '-o',
        outputPath,
      ], workingDirectory: sourceDir);

      progress.complete('CLI compiled successfully');
      return File(outputPath);
    } catch (e) {
      progress.fail('Failed to compile CLI');
      _logger.error(e.toString());
      return null;
    }
  }

  /// Builds the VSCode extension.
  Future<File?> buildExtension({
    required String sourceDir,
    required String outputDir,
  }) async {
    final progress = _logger.progress('Building VSCode extension...');
    try {
      final extensionDir = p.join(sourceDir, 'vscode-extension');
      if (!await Directory(extensionDir).exists()) {
        progress.fail('vscode-extension directory not found');
        return null;
      }

      if (!await Directory(outputDir).exists()) {
        await Directory(outputDir).create(recursive: true);
      }

      // Install dependencies
      await _processUtils.run('npm', [
        'install',
      ], workingDirectory: extensionDir);

      final extensionFileName = 'flutter_scaffold.vsix';
      final relativeOutputPath = p.join(outputDir, extensionFileName);
      final absoluteOutputPath = p.absolute(relativeOutputPath);

      // Package extension
      await _processUtils.run('npx', [
        'vsce',
        'package',
        '--out',
        absoluteOutputPath,
      ], workingDirectory: extensionDir);

      return File(absoluteOutputPath);
    } catch (e) {
      progress.fail('Failed to build extension');
      _logger.error(e.toString());
      return null;
    }
  }

  /// Bundles artifacts into the target project's distribution directory.
  Future<void> bundleArtifacts({required String targetDir}) async {
    final distDir = p.join(targetDir, '.flutter_scaffold', 'dist');
    if (!await Directory(distDir).exists()) {
      await Directory(distDir).create(recursive: true);
    }

    // Try to resolve source directory
    final sourceDir = _resolveSourceDir();
    final buildDir = p.join(sourceDir ?? _fileUtils.currentDirectory, 'build');

    // 1. Compile/Copy CLI
    // If we have source, compile it. Otherwise try to copy running executable.
    File? cliExe;
    if (sourceDir != null) {
      cliExe = await compileCli(sourceDir: sourceDir, outputDir: buildDir);
    } else {
      // Fallback: try to copy current executable if it's a binary
      if (p.extension(Platform.executable).isEmpty) {
        // likely a binary
        cliExe = File(Platform.executable);
      }
    }

    if (cliExe != null && await cliExe.exists()) {
      final targetExe = p.join(distDir, executableName);
      await cliExe.copy(targetExe);
      // Ensure executable permission
      await Process.run('chmod', ['+x', targetExe]);
      _logger.info('Bundled CLI executable');
    } else {
      _logger.warn('Could not bundle CLI executable (source not found)');
    }

    // 2. Build Extension
    // We need source to build extension
    if (sourceDir != null) {
      final extensionVsix = await buildExtension(
        sourceDir: sourceDir,
        outputDir: buildDir,
      );
      if (extensionVsix != null) {
        final targetVsix = p.join(distDir, 'flutter_scaffold.vsix');
        await extensionVsix.copy(targetVsix);
        _logger.info('Bundled VSCode extension');
      }
    } else {
      _logger.warn('Could not bundle VSCode extension (source not found)');
    }
  }

  /// Generates the wrapper script in the project root.
  Future<void> generateWrapper({required String targetDir}) async {
    final wrapperPath = p.join(targetDir, executableName);
    final wrapperContent =
        '''
#!/bin/bash

# Wrapper script for flutter_scaffold
# Prioritizes local version, falls back to global

LOCAL_CLI=".flutter_scaffold/dist/$executableName"
DIST_DIR=".flutter_scaffold/dist"

# Get absolute path to dist dir
if [ -d "\$DIST_DIR" ]; then
  cd "\$DIST_DIR"
  DIST_DIR_ABS=\$(pwd)
  cd - > /dev/null
fi

if [ -f "\$LOCAL_CLI" ]; then
  exec "\$LOCAL_CLI" "\$@"
else
  if command -v $executableName &> /dev/null; then
    exec $executableName "\$@"
  else
    echo "Error: flutter_scaffold not found locally or globally."
    echo "Please run 'dart pub global activate flutter_scaffold' to install."
    exit 1
  fi
fi
''';

    await File(wrapperPath).writeAsString(wrapperContent);
    await Process.run('chmod', ['+x', wrapperPath]);
    _logger.info('Generated wrapper script: $executableName');
  }

  /// Resolves the package source directory from the running script.
  String? _resolveSourceDir() {
    try {
      final script = Platform.script;
      // If we are running from source or snapshot
      if (script.scheme == 'file') {
        final scriptPath = script.toFilePath();
        // Assume script is in bin/ or lib/src/commands/
        // We want the package root.
        // Standard structure: package_root/bin/flutter_scaffold.dart

        // Go up levels until we find pubspec.yaml
        var dir = Directory(p.dirname(scriptPath));
        for (var i = 0; i < 5; i++) {
          if (File(p.join(dir.path, 'pubspec.yaml')).existsSync()) {
            return dir.path;
          }
          dir = dir.parent;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
