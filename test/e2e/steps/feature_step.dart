/// Feature step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests feature add/remove commands.
class FeatureStep extends E2EStep {
  @override
  String get name => 'features';

  @override
  String get description => 'Feature management (add/remove)';

  @override
  List<String> get dependencies => [
    'lib/src/commands/add_feature_command.dart',
    'lib/src/commands/remove_feature_command.dart',
    'lib/src/services/feature_service.dart',
    'lib/src/services/build_runner_service.dart',
    'lib/src/templates/feature/**/*.template',
    'lib/src/templates/routing/**/*.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    // Test 1: Add basic feature
    await context.logCommand(
      stepName: 'feature',
      commandName: 'add_basic_feature',
      description: 'Add basic feature',
      args: ['add', 'feature', 'product'],
    );

    FileAssertions.expectDir('${context.projectPath}/lib/src/features/product');
    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/product/presentation/screens/product_screen.dart',
    );

    // Test 2: Add feature with screen type
    await context.logCommand(
      stepName: 'feature',
      commandName: 'add_feature_with_screen',
      description: 'Add feature with list screen',
      args: ['add', 'feature', 'order', '--screen', 'list', '--force'],
    );

    FileAssertions.expectDir('${context.projectPath}/lib/src/features/order');

    // Test 3: Add feature with model and fields
    await context.logCommand(
      stepName: 'feature',
      commandName: 'add_feature_with_model',
      description: 'Add feature with model and json_serializable',
      args: [
        'add',
        'feature',
        'cart',
        '--model',
        'item',
        '--json-serializable',
        '--field',
        'id:int',
        '--field',
        'name:String',
        '--field',
        'price:double',
        '--force',
      ],
    );

    FileAssertions.expectDir('${context.projectPath}/lib/src/features/cart');
    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/cart/data/models/item_model.dart',
    );

    // Test 4: Duplicate feature without --force (should fail)
    try {
      await context.logCommand(
        stepName: 'feature',
        commandName: 'add_duplicate_no_force',
        description: 'Add duplicate feature (should fail)',
        args: ['add', 'feature', 'product'],
      );
      throw Exception('Duplicate feature addition should have failed');
    } catch (e) {
      if (!e.toString().contains('exit code 1') &&
          !e.toString().contains('Exit Code: 1')) {
        rethrow;
      }
    }

    // Test 5: Remove feature
    await context.logCommand(
      stepName: 'feature',
      commandName: 'remove_feature',
      description: 'Remove feature',
      args: ['remove', 'feature', 'cart', '--force'],
    );

    FileAssertions.expectNoDir('${context.projectPath}/lib/src/features/cart');
  }
}
