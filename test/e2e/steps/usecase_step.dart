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
    'lib/src/services/feature_service.dart',
    'lib/src/templates/feature/usecase.dart.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'usecase_test';

    // Create feature first
    await context.logCommand(
      stepName: 'usecase',
      commandName: 'create_test_feature',
      description: 'Create feature for usecase testing',
      args: ['add', 'feature', featureName],
    );

    // Test 1: Add basic usecase
    await context.logCommand(
      stepName: 'usecase',
      commandName: 'add_usecase_basic',
      description: 'Add basic usecase',
      args: ['add', 'usecase', 'get_items', '--feature', featureName],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/get_items_usecase.dart',
    );

    // Test 2: Add usecase with return type and description
    await context.logCommand(
      stepName: 'usecase',
      commandName: 'add_usecase_with_return_type',
      description: 'Add usecase with return type and description',
      args: [
        'add',
        'usecase',
        'get_all_products',
        '--feature',
        featureName,
        '--return-type',
        'List<Product>',
        '--description',
        'fetching all products',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/get_all_products_usecase.dart',
    );

    // Test 3: Add usecase without params
    await context.logCommand(
      stepName: 'usecase',
      commandName: 'add_usecase_no_params',
      description: 'Add usecase without params',
      args: [
        'add',
        'usecase',
        'clear_cart',
        '--feature',
        featureName,
        '--no-with-params',
        '--return-type',
        'void',
        '--description',
        'clearing the cart',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/clear_cart_usecase.dart',
    );

    // Test 4: Add usecase with all options
    await context.logCommand(
      stepName: 'usecase',
      commandName: 'add_usecase_all_options',
      description: 'Add usecase with all options',
      args: [
        'add',
        'usecase',
        'create_order',
        '--feature',
        featureName,
        '--with-params',
        '--return-type',
        'Order',
        '--description',
        'creating a new order',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/create_order_usecase.dart',
    );

    // Test 5: Dry-run (should not create file)
    await context.logCommand(
      stepName: 'usecase',
      commandName: 'add_usecase_dry_run',
      description: 'Add usecase dry-run test',
      args: [
        'add',
        'usecase',
        'delete_item',
        '--feature',
        featureName,
        '--dry-run',
      ],
    );

    // File should NOT exist (dry-run)
    final dryRunFile = File(
      '${context.projectPath}/lib/src/features/$featureName/domain/usecases/delete_item_usecase.dart',
    );
    if (dryRunFile.existsSync()) {
      throw Exception('Dry-run should not create file');
    }
  }
}
