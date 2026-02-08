/// Dry-run step for E2E tests.
library;

import 'dart:io';

import '../../utils/test_utils.dart';
import '../step_base.dart';
import '../test_context.dart';

/// Step that tests --dry-run flag across commands.
class DryRunStep extends E2EStep {
  @override
  String get name => 'dry_run';

  @override
  String get description => 'Dry-run flag verification';

  @override
  List<String> get dependencies => [];

  @override
  List<String> get requiredSteps => ['create'];

  @override
  Future<void> execute(E2ETestContext context) async {
    const dryFeature = 'dry_feature';

    // Test 1: Dry-run on add feature
    await context.logCommand(
      stepName: 'dry_run',
      commandName: 'add_feature_dry_run',
      description: 'Add feature with dry-run flag',
      args: ['add', 'feature', dryFeature, '--dry-run'],
    );

    // Verify nothing was created
    FileAssertions.expectNoDir(
      '${context.projectPath}/lib/src/features/$dryFeature',
    );

    // Create a real feature for next tests
    await context.logCommand(
      stepName: 'dry_run',
      commandName: 'create_test_feature',
      description: 'Create feature for dry-run tests',
      args: ['add', 'feature', 'dry_test'],
    );

    // Test 2: Dry-run on add usecase
    await context.logCommand(
      stepName: 'dry_run',
      commandName: 'add_usecase_dry_run',
      description: 'Add usecase with dry-run flag',
      args: [
        'add',
        'usecase',
        'dry_usecase',
        '--feature',
        'dry_test',
        '--dry-run',
      ],
    );

    final dryUsecaseFile = File(
      '${context.projectPath}/lib/src/features/dry_test/domain/usecases/dry_usecase_usecase.dart',
    );
    if (dryUsecaseFile.existsSync()) {
      throw Exception('Dry-run should not create usecase file');
    }

    // Test 3: Dry-run on add model
    await context.logCommand(
      stepName: 'dry_run',
      commandName: 'add_model_dry_run',
      description: 'Add model with dry-run flag',
      args: [
        'add',
        'model',
        'dry_test',
        'dry_model',
        '--field',
        'id:String',
        '--dry-run',
      ],
    );

    final dryModelFile = File(
      '${context.projectPath}/lib/src/features/dry_test/data/models/dry_model_model.dart',
    );
    if (dryModelFile.existsSync()) {
      throw Exception('Dry-run should not create model file');
    }

    // Test 4: Dry-run on add repository
    await context.logCommand(
      stepName: 'dry_run',
      commandName: 'add_repository_dry_run',
      description: 'Add repository with dry-run flag',
      args: [
        'add',
        'repository',
        'dry_repo',
        '--feature',
        'dry_test',
        '--dry-run',
      ],
    );

    final dryRepoFile = File(
      '${context.projectPath}/lib/src/features/dry_test/domain/repositories/dry_repo_repository.dart',
    );
    if (dryRepoFile.existsSync()) {
      throw Exception('Dry-run should not create repository file');
    }
  }
}
