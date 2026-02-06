/// Interactive command for TUI-based option selection.
library;

import 'dart:io';

import 'package:args/command_runner.dart';

import '../core/version.dart';
import '../utils/logger.dart';

/// Command to launch interactive mode for easier option selection.
class InteractiveCommand extends Command<int> {
  @override
  String get name => 'interactive';

  @override
  List<String> get aliases => ['i'];

  @override
  String get description => 'Launch interactive mode for guided setup';

  @override
  Future<int> run() async {
    final logger = ScaffoldLogger();

    logger.header('Flutter Scaffold Interactive Mode');
    logger.info('Version: $appVersion');
    logger.info('');

    while (true) {
      final action = logger.chooseOne(
        'What would you like to do?',
        choices: [
          'Create new project',
          'Initialize existing project',
          'Add feature',
          'Add model',
          'Remove feature',
          'View project info',
          'Configure settings',
          'Check for updates',
          'Exit',
        ],
        defaultValue: 'Create new project',
      );

      logger.info('');

      switch (action) {
        case 'Create new project':
          await _createProject(logger);
        case 'Initialize existing project':
          await _initProject(logger);
        case 'Add feature':
          await _addFeature(logger);
        case 'Add model':
          await _addModel(logger);
        case 'Remove feature':
          await _removeFeature(logger);
        case 'View project info':
          await _viewInfo(logger);
        case 'Configure settings':
          await _configure(logger);
        case 'Check for updates':
          await _checkUpdates(logger);
        case 'Exit':
          logger.success('Goodbye! 👋');
          return 0;
      }

      logger.divider();
    }
  }

  Future<void> _createProject(ScaffoldLogger logger) async {
    final projectName = logger.prompt(
      'Enter project name:',
      defaultValue: 'my_app',
    );

    final org = logger.prompt(
      'Enter organization (reverse domain):',
      defaultValue: 'com.example',
    );

    final includeExamples = logger.confirm(
      'Include example code?',
      defaultValue: false,
    );

    logger.info('');
    logger.info('Creating project with:');
    logger.info('  Name: $projectName');
    logger.info('  Organization: $org');
    logger.info('  Examples: ${includeExamples ? "yes" : "no"}');
    logger.info('');

    final confirm = logger.confirm('Proceed?', defaultValue: true);

    if (confirm) {
      final args = [
        'run',
        'flutter_scaffold:flutter_scaffold',
        'create',
        projectName,
        '--org',
        org,
      ];
      if (!includeExamples) args.add('--no-examples');

      final result = await Process.run('dart', args);
      stdout.write(result.stdout);
      stderr.write(result.stderr);
    }
  }

  Future<void> _initProject(ScaffoldLogger logger) async {
    final dryRun = logger.confirm(
      'Run in dry-run mode first?',
      defaultValue: true,
    );

    logger.info('');

    final args = ['run', 'flutter_scaffold:flutter_scaffold', 'init'];
    if (dryRun) args.add('--dry-run');

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  Future<void> _addFeature(ScaffoldLogger logger) async {
    final featureName = logger.prompt('Enter feature name:');

    if (featureName.isEmpty) {
      logger.error('Feature name cannot be empty');
      return;
    }

    final screenName = logger.prompt(
      'Enter screen name (optional):',
      defaultValue: '',
    );

    logger.info('');

    final args = [
      'run',
      'flutter_scaffold:flutter_scaffold',
      'add',
      'feature',
      featureName,
    ];
    if (screenName.isNotEmpty) {
      args.addAll(['--screen', screenName]);
    }

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  Future<void> _addModel(ScaffoldLogger logger) async {
    final featureName = logger.prompt('Enter feature name for model:');
    final modelName = logger.prompt('Enter model name:');

    if (featureName.isEmpty || modelName.isEmpty) {
      logger.error('Feature and model names are required');
      return;
    }

    final modelType = logger.chooseOne(
      'Select model type:',
      choices: ['freezed', 'json_serializable', 'basic'],
      defaultValue: 'freezed',
    );

    logger.info('');

    final args = [
      'run',
      'flutter_scaffold:flutter_scaffold',
      'add',
      'model',
      featureName,
      modelName,
      '--type',
      modelType,
    ];

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  Future<void> _removeFeature(ScaffoldLogger logger) async {
    final featureName = logger.prompt('Enter feature name to remove:');

    if (featureName.isEmpty) {
      logger.error('Feature name cannot be empty');
      return;
    }

    final confirm = logger.confirm(
      'Are you sure you want to remove "$featureName"?',
      defaultValue: false,
    );

    if (!confirm) {
      logger.info('Cancelled.');
      return;
    }

    final args = [
      'run',
      'flutter_scaffold:flutter_scaffold',
      'remove',
      'feature',
      featureName,
    ];

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  Future<void> _viewInfo(ScaffoldLogger logger) async {
    final args = ['run', 'flutter_scaffold:flutter_scaffold', 'info'];

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  Future<void> _configure(ScaffoldLogger logger) async {
    final action = logger.chooseOne(
      'Configuration action:',
      choices: ['Initialize config', 'Show current config'],
      defaultValue: 'Show current config',
    );

    final args = [
      'run',
      'flutter_scaffold:flutter_scaffold',
      'config',
      action == 'Initialize config' ? 'init' : 'show',
    ];

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }

  Future<void> _checkUpdates(ScaffoldLogger logger) async {
    final args = [
      'run',
      'flutter_scaffold:flutter_scaffold',
      'upgrade',
      '--check',
    ];

    final result = await Process.run('dart', args);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
  }
}
