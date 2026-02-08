/// Repository step for E2E tests.
library;

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests repository add command.
class RepositoryStep extends E2EStep {
  @override
  String get name => 'repository';

  @override
  String get description => 'Add Repository command';

  @override
  List<String> get dependencies => [
    'lib/src/commands/add_repository_command.dart',
    'lib/src/templates/feature/repository.dart.template',
    'lib/src/templates/feature/repository_impl.dart.template',
    'lib/src/templates/feature/remote_datasource.dart.template',
    'lib/src/templates/feature/local_datasource.dart.template',
    'lib/src/templates/feature/mapper.dart.template',
  ];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const featureName = 'repo_test';

    // Create feature first
    await context.logCommand(
      stepName: 'repository',
      commandName: 'create_test_feature',
      description: 'Create feature for repository testing',
      args: ['add', 'feature', featureName],
    );

    // Test 1: Add basic repository
    await context.logCommand(
      stepName: 'repository',
      commandName: 'add_repository_basic',
      description: 'Add basic repository',
      args: ['add', 'repository', 'product', '--feature', featureName],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/domain/repositories/product_repository.dart',
    );
    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/repositories/product_repository_impl.dart',
    );

    // Test 2: Add repository with both datasources and mapper
    await context.logCommand(
      stepName: 'repository',
      commandName: 'add_repository_with_datasources',
      description: 'Add repository with datasources and mapper',
      args: [
        'add',
        'repository',
        'item',
        '--feature',
        featureName,
        '--include-datasources',
        '--include-mapper',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/datasources/item_remote_datasource.dart',
    );
    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/datasources/item_local_datasource.dart',
    );
    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/mappers/item_mapper.dart',
    );

    // Test 3: Add repository with remote-only
    await context.logCommand(
      stepName: 'repository',
      commandName: 'add_repository_remote_only',
      description: 'Add repository with remote datasource only',
      args: [
        'add',
        'repository',
        'api_only',
        '--feature',
        featureName,
        '--include-datasources',
        '--remote-only',
        '--force',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/datasources/api_only_remote_datasource.dart',
    );

    // Test 4: Add repository with local-only
    await context.logCommand(
      stepName: 'repository',
      commandName: 'add_repository_local_only',
      description: 'Add repository with local datasource only',
      args: [
        'add',
        'repository',
        'cache',
        '--feature',
        featureName,
        '--include-datasources',
        '--local-only',
        '--force',
      ],
    );

    FileAssertions.expectFile(
      '${context.projectPath}/lib/src/features/$featureName/data/datasources/cache_local_datasource.dart',
    );
  }
}
