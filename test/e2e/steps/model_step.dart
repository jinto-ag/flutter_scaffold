/// Model step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests model add command.
class ModelStep extends E2EStep {
  @override
  String get name => 'model';

  @override
  String get description => 'Add Model command';

  @override
  List<String> get dependencies => [
    'lib/src/commands/add_model_command.dart',
    'lib/src/services/model_service.dart',
    'lib/src/templates/feature/basic_model.dart.template',
    'lib/src/templates/feature/json_serializable_model.dart.template',
    'lib/src/templates/feature/freezed_model.dart.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'model_test';

    // Create feature first
    await context.logCommand(
      stepName: 'model',
      commandName: 'create_test_feature',
      description: 'Create feature for model testing',
      args: ['add', 'feature', featureName],
    );

    // Test 1: Add basic model
    await context.logCommand(
      stepName: 'model',
      commandName: 'add_model_basic',
      description: 'Add basic model',
      args: [
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
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/models/user_model.dart',
    );

    // Test 2: Add json_serializable model
    await context.logCommand(
      stepName: 'model',
      commandName: 'add_model_json_serializable',
      description: 'Add model with json_serializable',
      args: [
        'add',
        'model',
        featureName,
        'product',
        '--json-serializable',
        '--field',
        'id:int',
        '--field',
        'title:String',
        '--field',
        'price:double',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/models/product_model.dart',
    );

    // Test 3: Add freezed model
    await context.logCommand(
      stepName: 'model',
      commandName: 'add_model_freezed',
      description: 'Add model with freezed',
      args: [
        'add',
        'model',
        featureName,
        'order_item',
        '--freezed',
        '--field',
        'productId:String',
        '--field',
        'quantity:int',
        '--field',
        'price:double',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/models/order_item_model.dart',
    );

    // Test 4: Add model with all field types
    await context.logCommand(
      stepName: 'model',
      commandName: 'add_model_all_field_types',
      description: 'Add model with all field types',
      args: [
        'add',
        'model',
        featureName,
        'complete',
        '--json-serializable',
        '--field',
        'id:int',
        '--field',
        'uuid:String',
        '--field',
        'name:String',
        '--field',
        'price:double',
        '--field',
        'isActive:bool',
        '--field',
        'tags:List<String>',
        '--field',
        'createdAt:DateTime',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/models/complete_model.dart',
    );
  }
}
