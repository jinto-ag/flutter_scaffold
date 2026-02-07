#!/usr/bin/env dart

/// E2E Test Runner for flutter_scaffold.
///
/// This is the main entry point for E2E tests with:
/// - Modular step execution
/// - File hash-based caching
/// - Verbose and force options
///
/// Usage: dart run test/e2e/e2e_runner.dart [options]
///
/// Options:
///   --force      Force run all steps, ignore cache
///   --verbose    Show detailed output
///   --keep       Keep generated temp projects
///   --quick      Skip slow steps (verification)
///   --steps=...  Comma-separated list of steps to run
///   --list-steps List available steps
///   -h, --help   Show help
library;

import 'dart:io';

import '../utils/test_utils.dart';
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

  if (help) {
    _printHelp();
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
    'create': CreateStep(),
    'features': FeatureStep(),
    'usecase': UsecaseStep(),
    'repository': RepositoryStep(),
    'model': ModelStep(),
    'verification': VerifyStep(),
  };

  if (listSteps) {
    print('Available steps:');
    for (final entry in allSteps.entries) {
      print('  - ${entry.key}: ${entry.value.description}');
    }
    exit(0);
  }

  final projectRoot = Directory.current.path;
  final logFile = File('$projectRoot/.flutter_scaffold/e2e_test.log');

  final context = E2ETestContext(
    verbose: verbose,
    keepProject: keepProject,
    force: force,
    projectRoot: projectRoot,
    logFile: logFile,
  );

  try {
    context.logger.header('Flutter Scaffold E2E Test Runner');
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

    // Execute steps
    for (final stepName in orderedSteps) {
      final step = allSteps[stepName];
      if (step == null) {
        context.logger.error('Unknown step: $stepName');
        exit(1);
      }

      // Check cache
      final dependencyFiles = step.getDependencyFiles(projectRoot);
      if (!force &&
          context.cacheManager.isStepCached(stepName, dependencyFiles)) {
        context.logger.info(
          '${AnsiColors.gray}[SKIP] ${step.description} (cached)${AnsiColors.reset}',
        );
        continue;
      }

      // Run step
      context.logger.stepStart(step.description);
      try {
        await step.execute(context);
        context.logger.stepComplete();
        context.cacheManager.markStepComplete(stepName, dependencyFiles);
      } catch (e) {
        context.logger.stepFailed();
        context.logger.error(e.toString());
        context.cacheManager.markStepComplete(
          stepName,
          dependencyFiles,
          passed: false,
        );
        rethrow;
      }
    }

    context.logger.success('E2E Tests Passed');
  } catch (e, st) {
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
  --force        Force run all steps, ignore cache
  --verbose      Show detailed command output
  --keep         Keep generated temp projects
  --quick        Skip slow steps (verification)
  --steps=...    Comma-separated list of steps to run
  --list-steps   List available steps
  -h, --help     Show this help

Examples:
  dart run test/e2e/e2e_runner.dart                    # Run all tests
  dart run test/e2e/e2e_runner.dart --force            # Force re-run all
  dart run test/e2e/e2e_runner.dart --steps=create,usecase
  dart run test/e2e/e2e_runner.dart --quick --verbose
''');
}
