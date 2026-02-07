/// Build CLI step for E2E tests.
library;

import '../step_base.dart';
import '../test_context.dart';

/// Step that builds and activates the CLI.
class BuildCliStep extends E2EStep {
  @override
  String get name => 'build_cli';

  @override
  String get description => 'Building and activating CLI';

  @override
  List<String> get dependencies => [
    'lib/src/commands/**/*.dart',
    'lib/src/services/**/*.dart',
    'lib/src/utils/**/*.dart',
    'pubspec.yaml',
  ];

  @override
  Future<void> execute(E2ETestContext context) async {
    await context.runner.runDart([
      'pub',
      'global',
      'activate',
      '--source',
      'path',
      '.',
    ]);
  }
}
