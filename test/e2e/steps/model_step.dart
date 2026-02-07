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
    'lib/src/templates/feature/model.dart.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'model_test';

    // Create feature first
    await context.runScaffoldInProject(['add', 'feature', featureName]);

    // Add basic model
    await context.runScaffoldInProject([
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
    ]);

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/models/user_model.dart',
    );

    // Add json_serializable model
    await context.runScaffoldInProject([
      'add',
      'model',
      featureName,
      'product',
      '--json-serializable',
      '--field',
      'id:int',
      '--field',
      'title:String',
    ]);

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/models/product_model.dart',
    );
  }
}
