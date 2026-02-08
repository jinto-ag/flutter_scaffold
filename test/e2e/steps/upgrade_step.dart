/// Upgrade step for E2E tests.
library;

import '../step_base.dart';
import '../test_context.dart';

/// Step that tests upgrade command.
class UpgradeStep extends E2EStep {
  @override
  String get name => 'upgrade';

  @override
  String get description => 'Upgrade command (check)';

  @override
  List<String> get dependencies => ['lib/src/commands/upgrade_command.dart'];

  @override
  List<String> get requiredSteps => ['build_cli'];

  @override
  Future<void> execute(E2ETestContext context) async {
    // Test upgrade --check (non-destructive)
    await context.runner.runScaffold(['upgrade', '--check']);
  }
}
