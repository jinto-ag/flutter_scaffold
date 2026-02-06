/// Flutter Scaffold CLI - A production-grade scaffolding tool.
///
/// This library provides a Dart CLI implementation for creating
/// Flutter projects with clean architecture scaffold.
library;

// Core
export 'src/core/constants.dart';
export 'src/core/errors.dart';
export 'src/core/version.dart';

// Utils
export 'src/utils/file_utils.dart';
export 'src/utils/logger.dart';
export 'src/utils/process_utils.dart';
export 'src/utils/string_utils.dart';
export 'src/utils/templates.dart';

// Services
export 'src/services/backup_service.dart';
export 'src/services/config_service.dart';
export 'src/services/dependency_service.dart';
export 'src/services/feature_service.dart';
export 'src/services/flutter_service.dart';
export 'src/services/git_service.dart';
export 'src/services/history_service.dart';
export 'src/services/sandbox_service.dart';
export 'src/services/scaffold_service.dart';

// Commands
export 'src/commands/add_command.dart';
export 'src/commands/config_command.dart';
export 'src/commands/create_command.dart';
export 'src/commands/info_command.dart';
export 'src/commands/init_command.dart';
export 'src/commands/interactive_command.dart';
export 'src/commands/remove_command.dart';
export 'src/commands/reset_command.dart';
export 'src/commands/upgrade_command.dart';
