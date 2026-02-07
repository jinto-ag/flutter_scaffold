/// UseCase step for E2E tests.
library;

import 'dart:io';

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests usecase add command.
class UsecaseStep extends E2EStep {
  @override
  String get name => 'usecase';

  @override
  String get description => 'Add UseCase command';

  @override
  List<String> get dependencies => [
    'lib/src/commands/add_usecase_command.dart',
    'lib/src/templates/feature/usecase.dart.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'usecase_test';

    // Create feature first
    await context.runScaffoldInProject(['add', 'feature', featureName]);

    // Add usecase
    await context.runScaffoldInProject([
      'add',
      'usecase',
      'get_items',
      '--feature',
      featureName,
      '--return-type',
      'List<String>',
      '--description',
      'Get all items from repository',
    ]);

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/get_items_usecase.dart',
    );

    // Test dry-run (should not create file)
    await context.runScaffoldInProject([
      'add',
      'usecase',
      'delete_item',
      '--feature',
      featureName,
      '--dry-run',
    ]);

    // File should NOT exist (dry-run)
    final dryRunFile = File(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/delete_item_usecase.dart',
    );
    if (dryRunFile.existsSync()) {
      throw Exception('Dry-run should not create file');
    }
  }
}
