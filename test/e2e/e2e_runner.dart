#!/usr/bin/env dart

/// E2E Test Runner for flutter_scaffold.
///
/// This is the main entry point for E2E tests with:
/// - Modular step execution
/// - File hash-based caching
/// - Granular per-command logging
/// - Verbose and force options
///
/// Usage: dart run test/e2e/e2e_runner.dart [options]
///
/// Options:
///   --force        Force run all steps, ignore cache
///   --verbose      Show detailed output
///   --keep         Keep generated temp projects
///   --quick        Skip slow steps (verification)
///   --steps=...    Comma-separated list of steps to run
///   --list-steps   List available steps
///   --output=...   Output directory for logs (default: e2e_test_output)
///   --reset-output Clear output directory before running
///   --fail-fast    Stop on first failure (default: continue all tests)
///   -h, --help     Show help
library;

import 'dart:io';

import '../utils/test_utils.dart';
import 'cache_manager.dart';
import 'step_base.dart';
import 'test_context.dart';
import 'steps/steps.dart';

void main(List<String> args) async {
  final force = args.contains('--force');
  final verbose = args.contains('--verbose');
  final keepProject = args.contains('--keep');
  final quick = args.contains('--quick');
  final help = args.contains('--help') || args.contains('-h');
  final listSteps = args.contains('--list-steps');
  final resetOutput = args.contains('--reset-output');
  final failFast = args.contains('--fail-fast');
  final cacheStats = args.contains('--cache-stats');
  final cacheClear = args.contains('--cache-clear');

  // Parse output directory
  final outputArg = args.firstWhere(
    (a) => a.startsWith('--output='),
    orElse: () => '',
  );
  final outputPath = outputArg.isEmpty ? null : outputArg.substring(9);

  if (help) {
    _printHelp();
    exit(0);
  }

  // Handle cache management commands early
  final projectRoot = Directory.current.path;
  if (cacheStats || cacheClear) {
    final cacheManager = CacheManager(projectRoot: projectRoot);
    if (cacheClear) {
      cacheManager.clearAll();
      print('Cache cleared.');
    }
    if (cacheStats) {
      final stats = cacheManager.getStats();
      print(stats);
      print('Cached steps: ${cacheManager.getCachedSteps().join(', ')}');
    }
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

  // Register all steps
  final allSteps = <String, E2EStep>{
    'build_cli': BuildCliStep(),
    'config': ConfigStep(),
    'upgrade': UpgradeStep(),
    'create': CreateStep(),
    'init': InitStep(),
    'features': FeatureStep(),
    'usecase': UsecaseStep(),
    'repository': RepositoryStep(),
    'model': ModelStep(),
    'dry_run': DryRunStep(),
    'force_flag': ForceStep(),
    'reset': ResetStep(),
    'info': InfoStep(),
    'help': HelpStep(),
    'verification': VerifyStep(),
  };

  if (listSteps) {
    print('Available steps:');
    for (final entry in allSteps.entries) {
      print('  - ${entry.key}: ${entry.value.description}');
    }
    exit(0);
  }

  // projectRoot is already declared above for cache management
  final logFile = File('$projectRoot/.flutter_scaffold/e2e_test.log');

  final context = E2ETestContext(
    verbose: verbose,
    keepProject: keepProject,
    force: force,
    projectRoot: projectRoot,
    outputPath: outputPath,
    logFile: logFile,
  );

  try {
    context.logger.header('Flutter Scaffold E2E Test Runner');

    // Reset output if requested
    if (resetOutput) {
      context.resetOutput();
      context.logger.info('Output directory cleared.');
    }

    await context.setup();

    // Determine steps to run
    var stepsToRun = selectedSteps ?? allSteps.keys.toList();

    // Remove slow steps in quick mode
    if (quick && selectedSteps == null) {
      stepsToRun = stepsToRun.where((s) => s != 'verification').toList();
    }

    context.logger.info('Steps to run: ${stepsToRun.join(', ')}\n');

    // Check dependencies and resolve order
    final orderedSteps = _resolveStepOrder(stepsToRun, allSteps);

    // Track failures and skips for final report
    final failures = <String, String>{};
    int skippedCount = 0;
    int ranCount = 0;

    // Execute steps
    for (final stepName in orderedSteps) {
      final step = allSteps[stepName];
      if (step == null) {
        context.logger.error('Unknown step: $stepName');
        if (failFast) exit(1);
        failures[stepName] = 'Unknown step';
        continue;
      }

      // Check cache
      final dependencyFiles = step.getDependencyFiles(projectRoot);
      if (!force &&
          !step.alwaysRun &&
          context.cacheManager.isStepCached(stepName, dependencyFiles)) {
        context.logger.info(
          '${AnsiColors.gray}[SKIP] ${step.description} (cached)${AnsiColors.reset}',
        );
        skippedCount++;
        continue;
      }

      // Run step
      context.logger.stepStart(step.description);
      try {
        await step.execute(context);
        context.logger.stepComplete();
        context.cacheManager.markStepComplete(stepName, dependencyFiles);
        ranCount++;
      } catch (e, stackTrace) {
        context.logger.stepFailed();
        context.logger.error(e.toString());

        // Log the error to a file for debugging
        context.logError(
          stepName: stepName,
          errorName: 'step_failure',
          description: 'Step "$stepName" failed during execution',
          error: e,
          stackTrace: stackTrace,
        );

        context.cacheManager.markStepComplete(
          stepName,
          dependencyFiles,
          passed: false,
        );
        failures[stepName] = e.toString();
        if (failFast) rethrow;
        // Continue to next step if not fail-fast
      }
    }

    // Generate index files
    context.generateIndex();

    // Report failures
    if (failures.isNotEmpty) {
      context.logger.error('\n${failures.length} step(s) failed:');
      for (final entry in failures.entries) {
        context.logger.error(
          '  ✗ ${entry.key}: ${entry.value.split('\n').first}',
        );
      }
      context.logger.info('\nLogs available at: ${context.outputDir.path}');
      exit(1);
    }

    context.logger.success('E2E Tests Passed');
    context.logger.info(
      'Summary: $ranCount ran, $skippedCount cached/skipped, ${failures.length} failed',
    );
    context.logger.info('Logs available at: ${context.outputDir.path}');
  } catch (e, st) {
    // Generate index even on failure
    context.generateIndex();
    context.logger.error('Test Failed: $e');
    if (verbose) print(st);
    exit(1);
  } finally {
    await context.cleanup();
  }
}

/// Resolve step order based on dependencies.
List<String> _resolveStepOrder(
  List<String> steps,
  Map<String, E2EStep> allSteps,
) {
  final resolved = <String>[];
  final visited = <String>{};

  void visit(String name) {
    if (visited.contains(name)) return;
    visited.add(name);

    final step = allSteps[name];
    if (step == null) return;

    for (final dep in step.requiredSteps) {
      if (!resolved.contains(dep) && steps.contains(dep)) {
        visit(dep);
      } else if (!resolved.contains(dep) && !steps.contains(dep)) {
        // Dependency not in selected steps, add it anyway
        visit(dep);
      }
    }

    if (!resolved.contains(name)) {
      resolved.add(name);
    }
  }

  for (final name in steps) {
    visit(name);
  }

  return resolved;
}

void _printHelp() {
  print('''
E2E Test Runner for flutter_scaffold

Usage: dart run test/e2e/e2e_runner.dart [options]

Options:
  --force          Force run all steps, ignore cache
  --verbose        Show detailed command output
  --keep           Keep generated temp projects
  --quick          Skip slow steps (verification)
  --steps=...      Comma-separated list of steps to run
  --list-steps     List available steps
  --output=...     Output directory for logs (default: e2e_test_output)
  --reset-output   Clear output directory before running
  --fail-fast      Stop on first failure (default: continue all tests)
  --cache-stats    Show cache statistics
  --cache-clear    Clear all cached step results
  -h, --help       Show this help

Examples:
  dart run test/e2e/e2e_runner.dart                       # Run all tests
  dart run test/e2e/e2e_runner.dart --force               # Force re-run all
  dart run test/e2e/e2e_runner.dart --steps=create,features,model
  dart run test/e2e/e2e_runner.dart --quick --verbose
  dart run test/e2e/e2e_runner.dart --reset-output        # Clear logs first
  dart run test/e2e/e2e_runner.dart --fail-fast           # Stop on first error
  dart run test/e2e/e2e_runner.dart --cache-stats         # View cache info
  dart run test/e2e/e2e_runner.dart --cache-clear         # Clear cache
''');
}
