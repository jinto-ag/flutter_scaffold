#!/usr/bin/env dart

// ignore_for_file: avoid_print
/// Comprehensive E2E Test Script for flutter_scaffold
///
/// Usage: dart run scripts/e2e_test.dart [--keep] [--verbose] [--quick] [--steps=step1,step2]
library;

import 'dart:io';
import 'dart:async';

// ANSI color codes
const _red = '\x1B[31m';
const _green = '\x1B[32m';
const _blue = '\x1B[34m';
const _cyan = '\x1B[36m';
const _reset = '\x1B[0m';

void main(List<String> args) async {
  final keepProject = args.contains('--keep');
  final verbose = args.contains('--verbose');
  final quick = args.contains('--quick');
  final help = args.contains('--help') || args.contains('-h');

  if (help) {
    print('Usage: dart run scripts/e2e_test.dart [options]');
    print('Options:');
    print('  --keep       Keep generated projects');
    print('  --verbose    Show detailed output');
    print(
      '  --quick      Skip time-consuming steps (integration, existing project)',
    );
    print(
      '  --steps=...  Comma-separated list of steps to run (e.g., init,features)',
    );
    print('  --list-steps List available steps');
    exit(0);
  }

  // Parse steps
  final stepsArg = args.firstWhere(
    (a) => a.startsWith('--steps='),
    orElse: () => '',
  );
  final selectedSteps = stepsArg.isEmpty
      ? null
      : stepsArg.substring(8).split(',').map((s) => s.trim()).toList();

  final context = TestContext(keepProject: keepProject, verbose: verbose);

  // Define Steps
  final allSteps = <String, Future<void> Function()>{
    'build_cli': () => context.runStep('Building CLI', () async {
      await context.run('dart', [
        'pub',
        'global',
        'activate',
        '--source',
        'path',
        '.',
      ]);
    }),

    'config': () => context.runStep('Config Command', () async {
      await context.run('flutter_scaffold', [
        'config',
        'init',
      ], workingDirectory: context.tempDir.path);
      await context.run('flutter_scaffold', [
        'config',
        'show',
      ], workingDirectory: context.tempDir.path);
    }),

    'upgrade': () => context.runStep('Upgrade Command (Check)', () async {
      await context.run('flutter_scaffold', ['upgrade', '--check']);
    }),

    'create': () => context.runStep('Creating New Project (create)', () async {
      final newProjectName = 'e2e_new_${context.timestamp}';
      final newProjectPath = '${context.tempDir.path}/$newProjectName';

      await context.run('flutter_scaffold', [
        'create',
        newProjectName,
        context.tempDir.path,
      ]);

      context.projectPath = newProjectPath; // Set active project path

      context.expectFile('$newProjectPath/pubspec.yaml');
      context.expectFile('$newProjectPath/lib/main.dart');
      context.expectDir('$newProjectPath/lib/src/core');
    }),

    'features': () => context.runStep(
      'Feature Management (add/remove)',
      () async {
        context.ensureProjectPath();
        final featureName = 'test_feat';

        // Add Feature
        await context.run('flutter_scaffold', [
          'add',
          'feature',
          featureName,
        ], workingDirectory: context.projectPath);

        context.expectDir(
          '${context.projectPath}/lib/src/features/$featureName',
        );
        context.expectFile(
          '${context.projectPath}/lib/src/features/$featureName/presentation/screens/${featureName}_screen.dart',
        );

        // Add Duplicate (should fail with exit code 1)
        try {
          await context.run('flutter_scaffold', [
            'add',
            'feature',
            featureName,
          ], workingDirectory: context.projectPath);
          throw Exception('Duplicate feature addition should have failed');
        } catch (e) {
          if (!e.toString().contains('exit code 1') &&
              !e.toString().contains('Exit Code: 1')) {
            rethrow;
          }
        }

        // Remove Feature
        await context.run('flutter_scaffold', [
          'remove',
          'feature',
          featureName,
          '--force',
        ], workingDirectory: context.projectPath);

        context.expectNoDir(
          '${context.projectPath}/lib/src/features/$featureName',
        );
      },
    ),

    'usecase': () => context.runStep('Add UseCase Command', () async {
      context.ensureProjectPath();
      final featureName = 'usecase_test';

      // Create feature first
      await context.run('flutter_scaffold', [
        'add',
        'feature',
        featureName,
      ], workingDirectory: context.projectPath);

      // Add usecase
      await context.run('flutter_scaffold', [
        'add',
        'usecase',
        'get_items',
        '--feature',
        featureName,
        '--return-type',
        'List<String>',
        '--description',
        'Get all items from repository',
      ], workingDirectory: context.projectPath);

      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/domain/usecases/get_items_usecase.dart',
      );

      // Test dry-run (should not create file)
      await context.run('flutter_scaffold', [
        'add',
        'usecase',
        'delete_item',
        '--feature',
        featureName,
        '--dry-run',
      ], workingDirectory: context.projectPath);

      // File should NOT exist (dry-run)
      if (File(
        '${context.projectPath}/lib/src/features/$featureName/domain/usecases/delete_item_usecase.dart',
      ).existsSync()) {
        throw Exception('Dry-run should not create file');
      }
    }),

    'repository': () => context.runStep('Add Repository Command', () async {
      context.ensureProjectPath();
      final featureName = 'repo_test';

      // Create feature first
      await context.run('flutter_scaffold', [
        'add',
        'feature',
        featureName,
      ], workingDirectory: context.projectPath);

      // Add repository with datasources and mapper
      await context.run('flutter_scaffold', [
        'add',
        'repository',
        'item',
        '--feature',
        featureName,
        '--include-datasources',
        '--include-mapper',
      ], workingDirectory: context.projectPath);

      // Verify all files created
      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/domain/repositories/item_repository.dart',
      );
      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/repositories/item_repository_impl.dart',
      );
      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/datasources/item_remote_datasource.dart',
      );
      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/datasources/item_local_datasource.dart',
      );
      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/mappers/item_mapper.dart',
      );

      // Test remote-only
      await context.run('flutter_scaffold', [
        'add',
        'repository',
        'api_only',
        '--feature',
        featureName,
        '--include-datasources',
        '--remote-only',
        '--force',
      ], workingDirectory: context.projectPath);

      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/datasources/api_only_remote_datasource.dart',
      );
    }),

    'model': () => context.runStep('Add Model Command', () async {
      context.ensureProjectPath();
      final featureName = 'model_test';

      // Create feature first
      await context.run('flutter_scaffold', [
        'add',
        'feature',
        featureName,
      ], workingDirectory: context.projectPath);

      // Add basic model (syntax: add model <feature> <model> --field ...)
      await context.run('flutter_scaffold', [
        'add',
        'model',
        featureName,
        'user',
        '--field',
        'id:String',
        '--field',
        'name:String',
        '--field',
        'email:String',
      ], workingDirectory: context.projectPath);

      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/models/user_model.dart',
      );

      // Add json_serializable model
      await context.run('flutter_scaffold', [
        'add',
        'model',
        featureName,
        'product',
        '--json-serializable',
        '--field',
        'id:int',
        '--field',
        'title:String',
      ], workingDirectory: context.projectPath);

      context.expectFile(
        '${context.projectPath}/lib/src/features/$featureName/data/models/product_model.dart',
      );
    }),

    'dry_run': () => context.runStep('Dry Run verification', () async {
      context.ensureProjectPath();
      final dryFeature = 'dry_feature';
      await context.run('flutter_scaffold', [
        'add',
        'feature',
        dryFeature,
        '--dry-run',
      ], workingDirectory: context.projectPath);
      context.expectNoDir(
        '${context.projectPath}/lib/src/features/$dryFeature',
      );
    }),

    'existing_project': () =>
        context.runStep('Existing Project Integration (init)', () async {
          final existingProjectName = 'e2e_existing_${context.timestamp}';
          final existingProjectPath =
              '${context.tempDir.path}/$existingProjectName';

          print('Creating standard Flutter project...');
          await context.run('flutter', [
            'create',
            existingProjectName,
          ], workingDirectory: context.tempDir.path);

          print('Running flutter_scaffold init...');
          await context.run('flutter_scaffold', [
            'init',
            '--force',
            '--no-git',
            '--no-backup',
          ], workingDirectory: existingProjectPath);

          context.expectDir('$existingProjectPath/lib/src/core');
          context.expectFile('$existingProjectPath/flutter_scaffold');
          context.expectFile('$existingProjectPath/.vscode/extensions.json');
        }),

    'verification': () =>
        context.runStep('Verification (analyze & test)', () async {
          context.ensureProjectPath();
          print('Verifying ${context.projectPath}...');
          await context.run('flutter', [
            'pub',
            'get',
          ], workingDirectory: context.projectPath);
          await context.run('flutter', [
            'analyze',
          ], workingDirectory: context.projectPath);
          await context.run('flutter', [
            'test',
          ], workingDirectory: context.projectPath);
        }),
  };

  if (args.contains('--list-steps')) {
    print('Available steps:');
    for (var k in allSteps.keys) {
      print('  - $k');
    }
    exit(0);
  }

  try {
    printHeader('Flutter Scaffold Comprehensive E2E Test');

    await context.setup();

    // Determine steps to run
    final stepsToRun = selectedSteps ?? allSteps.keys.toList();

    // Remove skipped steps if quick mode
    if (quick && selectedSteps == null) {
      stepsToRun.remove('existing_project');
      stepsToRun.remove('verification');
    }

    print('Steps to run: ${stepsToRun.join(', ')}\n');

    for (final stepName in stepsToRun) {
      if (allSteps.containsKey(stepName)) {
        await allSteps[stepName]!();
      } else {
        printError('Unknown step: $stepName');
        exit(1);
      }
    }

    printSuccess('E2E Tests Passed');
  } catch (e, st) {
    printError('Test Failed: $e');
    if (verbose) print(st);
    exit(1);
  } finally {
    await context.cleanup();
  }
}

class TestContext {
  final bool keepProject;
  final bool verbose;
  late Directory tempDir;
  late int timestamp;
  final File logFile;

  String? projectPath; // Current active project being tested

  TestContext({required this.keepProject, required this.verbose})
    : logFile = File('${Directory.current.path}/e2e_test.log');

  Future<void> setup() async {
    timestamp = DateTime.now().millisecondsSinceEpoch;
    tempDir = Directory.systemTemp.createTempSync('fs_e2e_');

    if (logFile.existsSync()) logFile.deleteSync();
    logFile.writeAsStringSync('E2E Test Log - ${DateTime.now()}\n\n');

    // Check if flutter is installed
    try {
      await run('flutter', ['--version']);
    } catch (e) {
      throw Exception('Flutter SDK not found. Please install Flutter.');
    }

    print('Temp Dir: ${tempDir.path}');
  }

  Future<void> cleanup() async {
    if (!keepProject && tempDir.existsSync()) {
      print('Cleaning up...');
      try {
        tempDir.deleteSync(recursive: true);
      } catch (e) {
        print('Warning: Failed to cleanup temp dir: $e');
      }
    } else if (keepProject) {
      print('Keeping temp dir at ${tempDir.path}');
    }
  }

  void ensureProjectPath() {
    if (projectPath == null) {
      throw Exception(
        'Project path is not set. Run "create" or "existing_project" step first, or ensure a step setting it ran appropriately.',
      );
    }
  }

  Future<void> runStep(String name, Future<void> Function() action) async {
    stdout.write('$_cyan[STEP] $name... $_reset');
    try {
      await action();
      print('$_green✓$_reset');
    } catch (e) {
      print('$_red✗$_reset');
      printError(e.toString());
      rethrow;
    }
  }

  Future<ProcessResult> run(
    String executable,
    List<String> args, {
    String? workingDirectory,
  }) async {
    if (verbose) print('\nRunning: $executable ${args.join(' ')}');

    final result = await Process.run(
      executable,
      args,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
    );

    final output = '${result.stdout}\n${result.stderr}';
    logFile.writeAsStringSync(
      '[$executable ${args.join(' ')}]\n$output\n',
      mode: FileMode.append,
    );

    if (result.exitCode != 0) {
      throw Exception(
        'Command failed: $executable ${args.join(' ')}\nExit Code: ${result.exitCode}\nOutput: $output',
      );
    }
    return result;
  }

  void expectFile(String path) {
    if (!File(path).existsSync()) {
      throw Exception('Expected file not found: $path');
    }
  }

  void expectDir(String path) {
    if (!Directory(path).existsSync()) {
      throw Exception('Expected directory not found: $path');
    }
  }

  void expectNoDir(String path) {
    if (Directory(path).existsSync()) {
      throw Exception('Expected directory to NOT exist: $path');
    }
  }
}

void printHeader(String msg) {
  print(
    '\n$_blue════════════════════════════════════════════════════════════$_reset',
  );
  print('$_blue  $msg$_reset');
  print(
    '$_blue════════════════════════════════════════════════════════════$_reset\n',
  );
}

void printSuccess(String msg) {
  print('\n$_green✓ $msg$_reset\n');
}

void printError(String msg) {
  print('\n$_red✗ $msg$_reset\n');
}
