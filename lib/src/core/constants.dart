/// Application-wide constants for Flutter Scaffold CLI.
library;

/// Version of the CLI tool.
const String version = '0.1.0';

/// Name of the CLI executable.
const String executableName = 'flutter_scaffold';

/// Description for the CLI tool.
const String description =
    'A production-grade Flutter project scaffolding tool with Clean Architecture.';

/// Source directory for generated scaffold.
const String srcDir = 'lib/src';

/// Core scaffold directories.
const List<String> coreDirectories = [
  '$srcDir/core/errors',
  '$srcDir/core/extensions',
  '$srcDir/core/theme',
  '$srcDir/core/utils',
  '$srcDir/routing',
  '$srcDir/shared/providers',
  '$srcDir/shared/widgets',
  '$srcDir/features',
];

/// Core scaffold files (relative to project root).
const List<String> coreFiles = [
  '$srcDir/app.dart',
  '$srcDir/core/errors/exceptions.dart',
  '$srcDir/core/errors/failures.dart',
  '$srcDir/core/extensions/context_extensions.dart',
  '$srcDir/core/theme/app_theme.dart',
  '$srcDir/core/utils/logger.dart',
  '$srcDir/routing/app_router.dart',
  '$srcDir/routing/routes.dart',
  '$srcDir/shared/providers/shared_providers.dart',
];

/// Feature directories template (relative to feature root).
const List<String> featureDirectories = [
  'data/datasources',
  'data/models',
  'data/repositories',
  'domain/entities',
  'domain/repositories',
  'domain/usecases',
  'presentation/providers',
  'presentation/screens',
  'presentation/widgets',
];

/// Default dependencies to install.
const List<String> coreDependencies = [
  'flutter_riverpod',
  'riverpod_annotation',
  'go_router',
  'freezed_annotation',
  'json_annotation',
];

/// Default dev dependencies to install.
const List<String> devDependencies = [
  'riverpod_generator',
  'build_runner',
  'freezed',
  'json_serializable',
];
