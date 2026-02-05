#!/bin/bash

# =============================================================================
# Flutter Clean Architecture Scaffold Script
# =============================================================================
# Creates a minimal, production-ready folder structure following Clean
# Architecture principles for Flutter projects using Riverpod + GoRouter.
#
# Usage:
#   ./scaffold.sh [OPTIONS]
#   ./scaffold.sh add feature <name>   # Add a new feature module
#
# Options:
#   --force        Overwrite existing files
#   --install-deps Install required dependencies
#   --verify       Verify all files and folders exist
#   --help         Show this help message
#   --dry-run      Preview without creating
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------
readonly SCRIPT_VERSION="2.0.0"
readonly SRC_DIR="lib/src"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Counters
DIRS_CREATED=0
FILES_CREATED=0
FILES_SKIPPED=0

# Flags
FORCE=false
DRY_RUN=false
INSTALL_DEPS=false
SKIP_DEPS=false
VERIFY=false

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[!]${NC} $1"; }
log_error()   { echo -e "${RED}[✗]${NC} $1" >&2; }
log_created() { echo -e "  ${GREEN}+${NC} $1"; }
log_skipped() { echo -e "  ${YELLOW}○${NC} $1 (exists)"; }
log_would()   { echo -e "  ${CYAN}→${NC} $1"; }

# -----------------------------------------------------------------------------
# Help
# -----------------------------------------------------------------------------
show_help() {
    cat << EOF
${CYAN}Flutter Clean Architecture Scaffold v${SCRIPT_VERSION}${NC}

${YELLOW}USAGE:${NC}
    ./scaffold.sh [OPTIONS]
    ./scaffold.sh create <project_name> [LOCATION] [FLUTTER_OPTIONS]
    ./scaffold.sh reset project          # Reset entire project (destructive)
    ./scaffold.sh add feature <name>
    ./scaffold.sh remove feature <name>

${YELLOW}COMMANDS:${NC}
    create <project_name> [LOCATION] [FLUTTER_OPTIONS]
                           Create new Flutter project + clean architecture
    reset project           Reset entire project (destructive)
    add feature <name>      Create a new feature module
    remove feature <name>   Remove a feature module
    reset feature <name>    Reset feature to original state (destructive)
    info                    Show available features in the project

${YELLOW}PROJECT LOCATION:${NC}
    cwd                    Current directory (default)
    ../<name>             Parent directory
    ./<name>              Current directory with subfolder
    <path>                Absolute or relative path

${YELLOW}FLUTTER CREATE OPTIONS:${NC}
    --org <organization>   Organization (default: com.example)
    --description <text>   Project description
    --platforms <platform> Platforms (android,ios,web,linux,macos,windows)
    --template <template>   Project template
    --sample <id>          Sample ID
    And all other flutter create options

${YELLOW}GENERIC OPTIONS:${NC}
    --force        Overwrite existing files (default: skip)
    --skip-deps    Skip dependency installation (for create/reset commands)
    --install-deps Install Riverpod, GoRouter, Freezed dependencies (for existing projects)
    --verify       Verify all files and folders exist
    --dry-run      Preview what would be created
    --help         Show this help

${YELLOW}NOTES:${NC}
    • The 'create' command automatically installs all dependencies and runs code generation
    • The 'reset project' command regenerates code after resetting
    • Use --skip-deps to skip automatic dependency installation
    • Dependencies: flutter_riverpod, riverpod_annotation, go_router, freezed

${YELLOW}STRUCTURE:${NC}
    lib/src/
    ├── app.dart                    # MaterialApp.router configuration
    ├── core/
    │   ├── errors/                 # Exception & Failure types
    │   ├── extensions/             # Dart/Flutter extensions
    │   ├── theme/                  # Theme configuration
    │   └── utils/                  # Utilities (logger, etc.)
    ├── routing/                    # GoRouter configuration
    ├── shared/
    │   ├── providers/              # Global Riverpod providers
    │   └── widgets/                # Reusable widgets
    └── features/
        └── <feature>/              # Feature modules
            ├── data/               # Data sources, models, repo implementations
            ├── domain/             # Entities, repository interfaces, use cases
            └── presentation/       # Screens, widgets, providers

${YELLOW}EXAMPLES:${NC}
    # Create new project (interactive location)
    ./scaffold.sh create my_app
    
    # Create project in specific location with custom org
    ./scaffold.sh create my_app ../ --org com.mycompany
    
    # Create project with platforms and description
    ./scaffold.sh create my_app cwd --platforms android,ios,web --description "My App"
    
    # Create project with template
    ./scaffold.sh create my_app ./ --template skeleton
    
    # Regular scaffold operations
    ./scaffold.sh                      # Create base scaffold (existing project)
    ./scaffold.sh --install-deps       # Create scaffold + install deps
    ./scaffold.sh add feature auth     # Add 'auth' feature module
    ./scaffold.sh add feature settings # Add 'settings' feature module
    ./scaffold.sh reset feature auth   # Reset 'auth' feature to original state
    ./scaffold.sh reset project        # Reset entire project
    ./scaffold.sh info                 # Show all features and their details

EOF
}

# -----------------------------------------------------------------------------
# File Content Writer
# -----------------------------------------------------------------------------
write_file_content() {
    local file="$1"
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$file")"
    
    case "$file" in
        "$SRC_DIR/app.dart")
            cat > "$file" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routing/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    
    return MaterialApp.router(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
EOF
            ;;
        "$SRC_DIR/core/errors/exceptions.dart")
            cat > "$file" << 'EOF'
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;
  
  const AppException(this.message, {this.code, this.details});
  
  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

class ServerException extends AppException {
  const ServerException(super.message, {super.code, super.details});
}

class CacheException extends AppException {
  const CacheException(super.message, {super.code, super.details});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.details});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.details});
}
EOF
            ;;
        "$SRC_DIR/core/errors/failures.dart")
            cat > "$file" << 'EOF'
abstract class Failure {
  final String message;
  final String? code;
  final dynamic details;
  
  const Failure(this.message, {this.code, this.details});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;
  
  @override
  int get hashCode => message.hashCode ^ code.hashCode;
  
  @override
  String toString() => 'Failure: $message${code != null ? ' (Code: $code)' : ''}';
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code, super.details});
}

class CacheFailure extends Failure {
  const CacheFailure(super.message, {super.code, super.details});
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code, super.details});
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code, super.details});
}
EOF
            ;;
        "$SRC_DIR/core/extensions/context_extensions.dart")
            cat > "$file" << 'EOF'
import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  // Theme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  
  // Media Query
  double get width => MediaQuery.of(this).size.width;
  double get height => MediaQuery.of(this).size.height;
  bool get isMobile => width < 600;
  bool get isTablet => width >= 600 && width < 1200;
  bool get isDesktop => width >= 1200;
  
  // Navigation
  void pop<T extends Object?>([T? result]) => Navigator.of(this).pop<T>(result);
  Future<T?> push<T extends Object?>(Route<T> route) => Navigator.of(this).push<T>(route);
  
  // SnackBar
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    return ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
  }
}
EOF
            ;;
        "$SRC_DIR/core/theme/app_theme.dart")
            cat > "$file" << 'EOF'
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1976D2),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        margin: EdgeInsets.all(8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
EOF
            ;;
        "$SRC_DIR/core/utils/logger.dart")
            cat > "$file" << 'EOF'
import 'dart:developer' as developer;

class AppLogger {
  static const String _defaultTag = 'App';
  
  static void debug(String message, {String? tag}) {
    developer.log(
      '🔍 $message',
      name: tag ?? _defaultTag,
      level: 500,
    );
  }
  
  static void info(String message, {String? tag}) {
    developer.log(
      'ℹ️ $message',
      name: tag ?? _defaultTag,
      level: 800,
    );
  }
  
  static void warning(String message, {String? tag}) {
    developer.log(
      '⚠️ $message',
      name: tag ?? _defaultTag,
      level: 900,
    );
  }
  
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    developer.log(
      '❌ $message',
      name: tag ?? _defaultTag,
      error: error,
      stackTrace: stackTrace,
      level: 1000,
    );
  }
}
EOF
            ;;
        "$SRC_DIR/routing/app_router.dart")
            cat > "$file" << 'EOF'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'routes.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: Routes.home,
        name: Routes.homeName,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('Route not found: \${state.uri.path}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(Routes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Import screens for now - in real app, you'd have proper imports
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Home Screen', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('Add your content here!'),
          ],
        ),
      ),
    );
  }
}
EOF
            ;;
        "$SRC_DIR/routing/routes.dart")
            cat > "$file" << 'EOF'
class Routes {
  // Route names
  static const String homeName = 'home';
  static const String authName = 'auth';
  static const String settingsName = 'settings';
  
  // Route paths
  static const String home = '/';
  static const String auth = '/auth';
  static const String settings = '/settings';
  
  // Dynamic routes
  static const String userDetail = '/user/:id';
  static const String editProfile = '/profile/edit';
  static const String itemDetail = '/item/:id';
  
  // Query parameters
  static Map<String, String> homeQuery({
    String? tab,
    String? filter,
  }) {
    final queryParams = <String, String>{};
    if (tab != null) queryParams['tab'] = tab;
    if (filter != null) queryParams['filter'] = filter;
    return queryParams;
  }
}
EOF
            ;;
        "$SRC_DIR/shared/providers/shared_providers.dart")
            cat > "$file" << 'EOF'
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'shared_providers.g.dart';

// Example shared providers that can be used across the app

/// Theme mode provider for app-wide theme switching
@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

/// App settings provider
@riverpod
class AppSettingsNotifier extends _$AppSettingsNotifier {
  @override
  AppSettings build() => const AppSettings(
        notificationsEnabled: true,
        darkMode: false,
        language: 'en',
      );

  void updateSettings(AppSettings settings) {
    state = settings;
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setDarkMode(bool darkMode) {
    state = state.copyWith(darkMode: darkMode);
  }

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }
}

/// User session provider
@riverpod
class UserSessionNotifier extends _$UserSessionNotifier {
  @override
  UserSession? build() => null;

  void setSession(UserSession session) {
    state = session;
  }

  void clearSession() {
    state = null;
  }
}

/// Global loading state provider
@riverpod
class GlobalLoading extends _$GlobalLoading {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}

/// Global error state provider
@riverpod
class GlobalError extends _$GlobalError {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }

  void clearError() {
    state = null;
  }
}

// Data classes
class AppSettings {
  final bool notificationsEnabled;
  final bool darkMode;
  final String language;

  const AppSettings({
    required this.notificationsEnabled,
    required this.darkMode,
    required this.language,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    String? language,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      language: language ?? this.language,
    );
  }
}

class UserSession {
  final String id;
  final String email;
  final String name;

  const UserSession({
    required this.id,
    required this.email,
    required this.name,
  });
}
EOF
            ;;
        *)
            # For feature files, create basic empty structure
            write_feature_content "$file"
            ;;
    esac
}

write_feature_content() {
    local file="$1"
    local filename=$(basename "$file")
    
    case "$filename" in
        *_screen.dart)
            local feature_name=$(basename "$file" "_screen.dart")
            local pascal_name=$(_pascal_case "$feature_name")
            cat > "$file" << EOF
import 'package:flutter/material.dart';

class ${pascal_name}Screen extends StatelessWidget {
  const ${pascal_name}Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${pascal_name}'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${pascal_name} Screen', style: TextStyle(fontSize: 24)),
            SizedBox(height: 16),
            Text('Add your ${feature_name} content here!'),
          ],
        ),
      ),
    );
  }
}
EOF
            ;;
        *_providers.dart)
            local feature_name=$(basename "$file" "_providers.dart")
            local pascal_name=$(_pascal_case "$feature_name")
            cat > "$file" << EOF
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '${feature_name}_providers.g.dart';

// ${pascal_name} providers

/// Example provider for ${feature_name} state
@riverpod
class ${pascal_name}Notifier extends _\$${pascal_name}Notifier {
  @override
  ${pascal_name}State build() => ${pascal_name}State.initial();

  /// Load data for ${feature_name}
  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      // Add your data loading logic here
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Clear any error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// State class for ${pascal_name}
class ${pascal_name}State {
  final bool isLoading;
  final String? error;

  const ${pascal_name}State({
    this.isLoading = false,
    this.error,
  });

  factory ${pascal_name}State.initial() => const ${pascal_name}State();

  ${pascal_name}State copyWith({
    bool? isLoading,
    String? error,
  }) {
    return ${pascal_name}State(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
EOF
            ;;
        *_entity.dart)
            local feature_name=$(basename "$file" "_entity.dart")
            local pascal_name=$(_pascal_case "$feature_name")
            cat > "$file" << EOF
/// ${pascal_name} entity representing a ${feature_name} in the domain layer.
class ${pascal_name}Entity {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ${pascal_name}Entity({
    required this.id,
    required this.name,
    this.description = '',
    required this.createdAt,
    this.updatedAt,
  });

  /// Display name with fallback
  String get displayName => name.isNotEmpty ? name : 'Unnamed ${pascal_name}';

  /// Check if entity was created recently (within 7 days)
  bool get isRecentlyCreated {
    final now = DateTime.now();
    return now.difference(createdAt).inDays < 7;
  }

  ${pascal_name}Entity copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ${pascal_name}Entity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ${pascal_name}Entity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '${pascal_name}Entity(id: \$id, name: \$name)';
}
EOF
            ;;
        *_repository.dart)
            local feature_name=$(basename "$file" "_repository.dart")
            local pascal_name=$(_pascal_case "$feature_name")
            cat > "$file" << EOF
import '../entities/${feature_name}_entity.dart';

abstract class ${pascal_name}Repository {
  // CRUD operations
  Future<List<${pascal_name}Entity>> getAll();
  Future<${pascal_name}Entity?> getById(String id);
  Future<${pascal_name}Entity> create(${pascal_name}Entity entity);
  Future<${pascal_name}Entity> update(${pascal_name}Entity entity);
  Future<void> delete(String id);
  
  // Custom methods for ${feature_name}
  Future<List<${pascal_name}Entity>> search(String query);
  Future<bool> exists(String id);
}
EOF
            ;;
        *)
            # For any other files, create empty structure
            touch "$file"
            ;;
    esac
}

# Helper function to convert snake_case to PascalCase
_pascal_case() {
    local str="$1"
    local result=""
    local capitalize_next=true
    
    for ((i=0; i<${#str}; i++)); do
        local char="${str:$i:1}"
        if [[ "$char" == "_" ]]; then
            capitalize_next=true
        else
            if [[ "$capitalize_next" == true ]]; then
                result+="${char^^}"
                capitalize_next=false
            else
                result+="$char"
            fi
        fi
    done
    
    echo "$result"
}

# -----------------------------------------------------------------------------
# Utility Functions
# -----------------------------------------------------------------------------
create_dir() {
    local dir="$1"
    if [[ "$DRY_RUN" == true ]]; then
        return 0
    fi
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir"
        DIRS_CREATED=$((DIRS_CREATED + 1))
    fi
}

create_file() {
    local file="$1"
    create_dir "$(dirname "$file")"
    
    if [[ "$DRY_RUN" == true ]]; then
        if [[ -f "$file" ]]; then
            log_skipped "$file"
        else
            log_would "$file"
        fi
        return 0
    fi
    
    if [[ -f "$file" && "$FORCE" != true ]]; then
        log_skipped "$file"
        FILES_SKIPPED=$((FILES_SKIPPED + 1))
    else
        # Create file with appropriate content
        write_file_content "$file"
        log_created "$file"
        FILES_CREATED=$((FILES_CREATED + 1))
    fi
}

check_flutter() {
    if [[ ! -f "pubspec.yaml" ]]; then
        log_error "Not a Flutter project (no pubspec.yaml)"
        exit 1
    fi
}

install_dependencies() {
    log_info "Installing dependencies..."
    echo ""
    
    # Core dependencies
    log_info "Adding core dependencies..."
    flutter pub add flutter_riverpod riverpod_annotation go_router freezed_annotation json_annotation
    
    echo ""
    log_info "Adding dev dependencies..."
    flutter pub add --dev riverpod_generator build_runner freezed json_serializable
    
    echo ""
    log_info "Resolving dependencies..."
    flutter pub get
    
    echo ""
    log_success "Dependencies installed!"
    
    # Run build_runner to generate code
    run_build_runner
    
    # Verify generated code
    run_flutter_analyze
}

run_build_runner() {
    echo ""
    log_info "Running build_runner to generate code..."
    echo ""
    if dart run build_runner build --delete-conflicting-outputs; then
        log_success "Generated code successfully!"
        return 0
    else
        log_warning "build_runner failed - you may need to run 'flutter pub get' first"
        return 1
    fi
}

run_flutter_analyze() {
    echo ""
    log_info "Verifying code with flutter analyze..."
    echo ""
    if flutter analyze; then
        log_success "Code analysis passed - no issues found!"
        return 0
    else
        log_warning "flutter analyze found issues - please review and fix"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Add Feature Command
# -----------------------------------------------------------------------------
add_feature() {
    local feature_name="$1"
    
    # Validate feature name
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        echo "Usage: ./scaffold.sh add feature <name>"
        exit 1
    fi
    
    # Convert to snake_case (lowercase, replace spaces/hyphens with underscores)
    feature_name=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' -' '_')
    
    local feature_dir="$SRC_DIR/features/$feature_name"
    
    # Check if feature already exists
    if [[ -d "$feature_dir" && "$FORCE" != true ]]; then
        log_error "Feature '$feature_name' already exists at $feature_dir"
        log_info "Use --force to overwrite"
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Adding Feature:${NC} $feature_name"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Feature directories
    local feature_dirs=(
        "$feature_dir/data/datasources"
        "$feature_dir/data/models"
        "$feature_dir/data/repositories"
        "$feature_dir/domain/entities"
        "$feature_dir/domain/repositories"
        "$feature_dir/domain/usecases"
        "$feature_dir/presentation/providers"
        "$feature_dir/presentation/screens"
        "$feature_dir/presentation/widgets"
    )
    
    # Feature files
    local feature_files=(
        "$feature_dir/presentation/screens/${feature_name}_screen.dart"
        "$feature_dir/presentation/providers/${feature_name}_providers.dart"
        "$feature_dir/domain/entities/${feature_name}_entity.dart"
        "$feature_dir/domain/repositories/${feature_name}_repository.dart"
    )
    
    log_info "Creating directories..."
    for dir in "${feature_dirs[@]}"; do
        create_dir "$dir"
    done
    
    echo ""
    log_info "Creating files..."
    for file in "${feature_files[@]}"; do
        create_file "$file"
    done
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    log_success "Feature '$feature_name' created!"
    echo -e "  Directories: ${GREEN}${#feature_dirs[@]}${NC}"
    echo -e "  Files: ${GREEN}${#feature_files[@]}${NC}"
    
    echo ""
    echo -e "${BLUE}Feature structure:${NC}"
    echo "  $feature_dir/"
    echo "  ├── data/{datasources, models, repositories}/"
    echo "  ├── domain/{entities, repositories, usecases}/"
    echo "  └── presentation/{providers, screens, widgets}/"
    echo ""
    
    # Run verification if requested
    if [[ "$VERIFY" == true ]]; then
        verify_scaffold
    fi
}

# -----------------------------------------------------------------------------
# Reset Feature Command
# -----------------------------------------------------------------------------
reset_feature() {
    local feature_name="$1"
    
    # Validate feature name
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        echo "Usage: ./scaffold.sh reset feature <name>"
        exit 1
    fi
    
    # Convert to snake_case
    feature_name=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' -' '_')
    
    local feature_dir="$SRC_DIR/features/$feature_name"
    
    # Check if feature exists
    if [[ ! -d "$feature_dir" ]]; then
        log_error "Feature '$feature_name' does not exist at $feature_dir"
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  RESETTING Feature:${NC} $feature_name"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Show what will be affected
    echo -e "${YELLOW}This will COMPLETELY RESET the feature:${NC}"
    echo "  • Remove ALL custom files and content"
    echo "  • Remove the entire feature directory: $feature_dir/"
    echo "  • Recreate basic feature structure"
    echo "  • ${RED}THIS IS DESTRUCTIVE AND CANNOT BE UNDONE${NC}"
    echo ""
    
    # Count files that will be deleted
    local file_count=$(find "$feature_dir" -type f | wc -l)
    local dir_count=$(find "$feature_dir" -type d | wc -l)
    
    echo -e "${BLUE}Current feature contains:${NC}"
    echo "  • $file_count files"
    echo "  • $dir_count directories"
    echo ""
    
    # Strong confirmation required
    if [[ "$FORCE" != true ]]; then
        echo -e "${RED}⚠️  DANGER: This will permanently delete all custom work!${NC}"
        echo ""
        read -p "Type 'RESET' to confirm reset of '$feature_name': " confirm
        if [[ "$confirm" != "RESET" ]]; then
            log_info "Reset cancelled - confirmation not matched"
            exit 0
        fi
        
        echo ""
        echo -e "${RED}FINAL CONFIRMATION:${NC}"
        read -p "Are you absolutely sure you want to reset '$feature_name'? (yes/no): " final_confirm
        if [[ "$final_confirm" != "yes" ]]; then
            log_info "Reset cancelled"
            exit 0
        fi
    fi
    
    echo ""
    log_info "Resetting feature '$feature_name'..."
    
    # Remove the entire feature directory
    if [[ "$DRY_RUN" != true ]]; then
        rm -rf "$feature_dir"
        log_success "Removed existing feature directory"
        
        echo ""
        log_info "Recreating basic feature structure..."
        
        # Recreate using add_feature function but with reset flag
        RESET_MODE=true add_feature "$feature_name"
    else
        log_would "Remove directory: $feature_dir/"
        log_would "Recreate basic feature structure"
    fi
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    log_success "Feature '$feature_name' reset complete!"
    echo ""
    echo -e "${GREEN}✓${NC} All custom content removed"
    echo -e "${GREEN}✓${NC} Basic structure recreated"
    echo ""
}

# -----------------------------------------------------------------------------
# Remove Feature Command
# -----------------------------------------------------------------------------
remove_feature() {
    local feature_name="$1"
    
    # Validate feature name
    if [[ -z "$feature_name" ]]; then
        log_error "Feature name is required"
        echo "Usage: ./scaffold.sh remove feature <name>"
        exit 1
    fi
    
    # Convert to snake_case
    feature_name=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]' | tr ' -' '_')
    
    local feature_dir="$SRC_DIR/features/$feature_name"
    
    # Check if feature exists
    if [[ ! -d "$feature_dir" ]]; then
        log_error "Feature '$feature_name' does not exist at $feature_dir"
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  Removing Feature:${NC} $feature_name"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Confirm removal
    if [[ "$FORCE" != true ]]; then
        echo -e "${YELLOW}This will permanently delete:${NC}"
        echo "  $feature_dir/"
        echo ""
        read -p "Are you sure? (y/N): " confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            log_info "Cancelled"
            exit 0
        fi
    fi
    
    # Remove the feature directory
    rm -rf "$feature_dir"
    
    echo ""
    log_success "Feature '$feature_name' removed!"
    echo ""
}

verify_scaffold() {
    log_info "Verifying scaffold structure..."
    echo ""
    
    local missing_dirs=0
    local missing_files=0
    local total_dirs=${#DIRS[@]}
    local total_files=${#FILES[@]}
    
    # Check directories
    echo -e "${BLUE}Directories:${NC}"
    for dir in "${DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} $dir"
        else
            echo -e "  ${RED}✗${NC} $dir (missing)"
            missing_dirs=$((missing_dirs + 1))
        fi
    done
    
    echo ""
    echo -e "${BLUE}Files:${NC}"
    for file in "${FILES[@]}"; do
        if [[ -f "$file" ]]; then
            echo -e "  ${GREEN}✓${NC} $file"
        else
            echo -e "  ${RED}✗${NC} $file (missing)"
            missing_files=$((missing_files + 1))
        fi
    done
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    
    local passed_dirs=$((total_dirs - missing_dirs))
    local passed_files=$((total_files - missing_files))
    
    echo -e "  Directories: ${GREEN}$passed_dirs${NC}/${total_dirs}"
    echo -e "  Files:       ${GREEN}$passed_files${NC}/${total_files}"
    
    if [[ $missing_dirs -eq 0 && $missing_files -eq 0 ]]; then
        echo ""
        log_success "All scaffold items verified!"
        return 0
    else
        echo ""
        log_error "Missing: $missing_dirs directories, $missing_files files"
        log_info "Run './scaffold.sh' to create missing items"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Directory & File Structure (Core scaffold - features via add_feature)
# -----------------------------------------------------------------------------
readonly DIRS=(
    # Core
    "$SRC_DIR/core/errors"
    "$SRC_DIR/core/extensions"
    "$SRC_DIR/core/theme"
    "$SRC_DIR/core/utils"
    # Routing
    "$SRC_DIR/routing"
    # Shared
    "$SRC_DIR/shared/providers"
    "$SRC_DIR/shared/widgets"
    # Features directory
    "$SRC_DIR/features"
)

readonly FILES=(
    # App entry
    "$SRC_DIR/app.dart"
    # Core
    "$SRC_DIR/core/errors/exceptions.dart"
    "$SRC_DIR/core/errors/failures.dart"
    "$SRC_DIR/core/extensions/context_extensions.dart"
    "$SRC_DIR/core/theme/app_theme.dart"
    "$SRC_DIR/core/utils/logger.dart"
    # Routing
    "$SRC_DIR/routing/app_router.dart"
    "$SRC_DIR/routing/routes.dart"
    # Shared
    "$SRC_DIR/shared/providers/shared_providers.dart"
)

# -----------------------------------------------------------------------------
# Create Project Command
# -----------------------------------------------------------------------------
create_project() {
    local project_name="$1"
    local location="${2:-}"
    shift 2
    local flutter_options=("$@")
    
    # Validate project name
    if [[ -z "$project_name" ]]; then
        log_error "Project name is required"
        echo "Usage: ./scaffold.sh create <project_name> [location] [flutter_options]"
        exit 1
    fi
    
    # Validate project name format (Flutter project naming rules)
    if [[ ! "$project_name" =~ ^[a-z0-9_]+$ ]]; then
        log_error "Project name must contain only lowercase letters, numbers, and underscores"
        exit 1
    fi
    
    # Handle project location
    if [[ -z "$location" ]]; then
        echo ""
        echo -e "${CYAN}Project Location Options:${NC}"
        echo "  1) cwd     - Current directory"
        echo "  2) ../$project_name - Parent directory"
        echo "  3) ./$project_name - Current directory as subfolder"
        echo "  4) custom  - Specify custom path"
        echo ""
        read -p "Choose location (1-4): " location_choice
        
        case $location_choice in
            1) location="cwd" ;;
            2) location="../$project_name" ;;
            3) location="./$project_name" ;;
            4) 
                read -p "Enter custom path: " custom_path
                if [[ -z "$custom_path" ]]; then
                    log_error "Custom path cannot be empty"
                    exit 1
                fi
                location="$custom_path"
                ;;
            *) 
                log_error "Invalid choice"
                exit 1
                ;;
        esac
    fi
    
    # Resolve the actual project path
    local project_path
    local flutter_target_dir
    
    # Handle the location properly
    case "$location" in
        "cwd"|"./"|"")
            flutter_target_dir="$project_name"
            project_path="$(pwd)/$project_name"
            ;;
        "..")
            flutter_target_dir="../$project_name"
            project_path="$(pwd)/../$project_name"
            ;;
        ".."*)
            # ../directory - remove the ../ prefix for flutter create
            flutter_target_dir="${location:3}"
            project_path="$(pwd)/$location"
            ;;
        "./"*)
            # ./directory - remove the ./ prefix for flutter create
            flutter_target_dir="${location:2}"
            project_path="$(pwd)/${location:2}"
            ;;
        /*)
            # Absolute path - extract just the directory name for flutter create
            local dir_name=$(basename "$location")
            flutter_target_dir="$location"
            project_path="$location"
            ;;
        *)
            # Simple directory name
            flutter_target_dir="$location/$project_name"
            project_path="$(pwd)/$location/$project_name"
            ;;
    esac
    
    # Ensure parent directory exists
    local parent_dir=$(dirname "$project_path")
    if [[ ! -d "$parent_dir" ]]; then
        if [[ "$DRY_RUN" != true ]]; then
            mkdir -p "$parent_dir"
            log_info "Created parent directory: $parent_dir"
        fi
    fi
    
    # Check if directory already exists
    if [[ -d "$project_path" && "$FORCE" != true ]]; then
        log_error "Directory '$project_path' already exists"
        log_info "Use --force to overwrite"
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Creating Flutter Project:${NC} $project_name"
    echo -e "${CYAN}  Location:${NC} $project_path"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Remove existing directory if force is enabled
    if [[ -d "$project_path" && "$FORCE" == true ]]; then
        log_warning "Removing existing directory '$project_path'..."
        rm -rf "$project_path"
    fi
    
    # Build flutter create command
    local flutter_cmd="flutter create"
    
    # Filter out generic options from flutter options
    local filtered_flutter_options=()
    for option in "${flutter_options[@]}"; do
        if [[ "$option" != "--force" && "$option" != "--dry-run" && "$option" != "--install-deps" && "$option" != "--verify" ]]; then
            filtered_flutter_options+=("$option")
        fi
    done
    
    # Add default org if not specified
    local has_org=false
    for option in "${filtered_flutter_options[@]}"; do
        if [[ "$option" =~ ^--org ]]; then
            has_org=true
            break
        fi
    done
    
    if [[ "$has_org" == false ]]; then
        flutter_cmd="$flutter_cmd --org com.example"
    fi
    
    # Add user provided options
    if [[ ${#filtered_flutter_options[@]} -gt 0 ]]; then
        flutter_cmd="$flutter_cmd ${filtered_flutter_options[*]}"
    fi
    flutter_cmd="$flutter_cmd $flutter_target_dir"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_would "Run: $flutter_cmd"
        log_would "Apply clean architecture scaffold to $project_path/"
        echo ""
        log_success "Dry run complete"
        exit 0
    fi
    
    log_info "Creating Flutter project..."
    echo "$flutter_cmd"
    
    # Create Flutter project
    if eval "$flutter_cmd"; then
        log_success "Flutter project created successfully!"
    else
        log_error "Failed to create Flutter project"
        exit 1
    fi
    
    echo ""
    log_info "Applying clean architecture scaffold..."
    
    # Change to project directory and apply scaffold
    local current_dir=$(pwd)
    cd "$project_path"
    
    # Copy this script to the new project
    cp "$current_dir/scaffold.sh" "./scaffold.sh"
    chmod +x "./scaffold.sh"
    
    # Run scaffold creation (without creating new Flutter project)
    log_info "Creating clean architecture structure..."
    
    # Create core structure
    for dir in "${DIRS[@]}"; do create_dir "$dir"; done
    
    echo ""
    log_info "Creating core files..."
    for file in "${FILES[@]}"; do create_file "$file"; done
    
    # Add home feature
    echo ""
    log_info "Adding 'home' feature..."
    add_feature "home"
    
    # Install dependencies and run build_runner unless skipped
    if [[ "$SKIP_DEPS" != true ]]; then
        echo ""
        install_dependencies
    else
        log_info "Skipping dependency installation (--skip-deps)"
    fi
    
    # Run verification if requested
    if [[ "$VERIFY" == true ]]; then
        echo ""
        verify_scaffold
    fi
    
    cd "$current_dir"
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    log_success "Project '$project_name' created with clean architecture!"
    echo ""
    echo -e "${BLUE}Project Details:${NC}"
    echo "  Location: $project_path"
    echo "  Name: $project_name"
    if [[ ${#flutter_options[@]} -gt 0 ]]; then
        echo "  Options: ${flutter_options[*]}"
    fi
    echo ""
    if [[ "$SKIP_DEPS" != true ]]; then
        echo -e "${GREEN}✓${NC} Dependencies installed"
        echo -e "${GREEN}✓${NC} Code generation complete"
        echo -e "${GREEN}✓${NC} Code analysis passed"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. cd $project_path"
        echo "  2. flutter run"
    else
        echo -e "${YELLOW}!${NC} Dependencies not installed (--skip-deps)"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "  1. cd $project_path"
        echo "  2. ./scaffold.sh --install-deps"
        echo "  3. flutter run"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Reset Project Command
# -----------------------------------------------------------------------------
reset_project() {
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  RESETTING ENTIRE PROJECT${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Check if we're in a Flutter project
    check_flutter
    
    # Count files and directories that will be affected
    local src_files=$(find "$SRC_DIR" -type f 2>/dev/null | wc -l)
    local src_dirs=$(find "$SRC_DIR" -type d 2>/dev/null | wc -l)
    
    echo -e "${RED}⚠️  CRITICAL WARNING:${NC}"
    echo "  This will COMPLETELY RESET the entire clean architecture scaffold"
    echo "  • Remove ALL files in lib/src/ directory"
    echo "  • Remove ALL features and custom code"
    echo "  • Recreate basic clean architecture structure"
    echo "  • ${RED}THIS IS EXTREMELY DESTRUCTIVE AND CANNOT BE UNDONE${NC}"
    echo ""
    
    if [[ $src_files -gt 0 || $src_dirs -gt 0 ]]; then
        echo -e "${YELLOW}Current scaffold contains:${NC}"
        echo "  • $src_files files in lib/src/"
        echo "  • $src_dirs directories in lib/src/"
        echo ""
    fi
    
    # Multiple confirmation steps
    if [[ "$FORCE" != true ]]; then
        echo -e "${RED}STEP 1 - CONFIRMATION:${NC}"
        read -p "Type 'RESET-PROJECT' to confirm project reset: " confirm1
        if [[ "$confirm1" != "RESET-PROJECT" ]]; then
            log_info "Project reset cancelled - confirmation not matched"
            exit 0
        fi
        
        echo ""
        echo -e "${RED}STEP 2 - FINAL CONFIRMATION:${NC}"
        read -p "Are you absolutely sure you want to reset the entire project? (yes/no): " confirm2
        if [[ "$confirm2" != "yes" ]]; then
            log_info "Project reset cancelled"
            exit 0
        fi
    fi
    
    echo ""
    log_info "Resetting entire project..."
    
    if [[ "$DRY_RUN" == true ]]; then
        log_would "Remove directory: lib/src/"
        log_would "Recreate clean architecture structure"
        log_would "Add home feature"
        echo ""
        log_success "Dry run complete"
        exit 0
    fi
    
    # Remove entire src directory
    if [[ -d "$SRC_DIR" ]]; then
        rm -rf "$SRC_DIR"
        log_success "Removed existing clean architecture structure"
    fi
    
    # Recreate the entire scaffold
    echo ""
    log_info "Recreating clean architecture structure..."
    
    # Create core structure
    log_info "Creating core directories..."
    for dir in "${DIRS[@]}"; do create_dir "$dir"; done
    
    echo ""
    log_info "Creating core files..."
    for file in "${FILES[@]}"; do create_file "$file"; done
    
    # Add home feature
    echo ""
    log_info "Adding 'home' feature..."
    add_feature "home"
    
    # Run build_runner to generate code unless skipped
    if [[ "$SKIP_DEPS" != true ]]; then
        run_build_runner
        run_flutter_analyze
    else
        log_info "Skipping code generation (--skip-deps)"
    fi
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    log_success "Project reset complete!"
    echo ""
    echo -e "${GREEN}✓${NC} All clean architecture content removed"
    echo -e "${GREEN}✓${NC} Basic structure recreated"
    echo -e "${GREEN}✓${NC} Home feature added"
    if [[ "$SKIP_DEPS" != true ]]; then
        echo -e "${GREEN}✓${NC} Code generation complete"
        echo -e "${GREEN}✓${NC} Code analysis passed"
    else
        echo -e "${YELLOW}!${NC} Code generation skipped (--skip-deps)"
        echo ""
        echo -e "${BLUE}Next steps:${NC}"
        echo "  Run 'dart run build_runner build --delete-conflicting-outputs'"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Info Command
# -----------------------------------------------------------------------------
show_info() {
    local features_dir="$SRC_DIR/features"
    
    if [[ ! -d "$features_dir" ]]; then
        log_error "Features directory not found at $features_dir"
        echo "Run './scaffold.sh' to create the basic structure first"
        exit 1
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Project Features Information${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Get all feature directories
    local features=($(find "$features_dir" -maxdepth 1 -mindepth 1 -type d -exec basename {} \; | sort))
    
    if [[ ${#features[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No features found in $features_dir${NC}"
        echo ""
        echo -e "${BLUE}To add a feature:${NC}"
        echo "  ./scaffold.sh add feature <name>"
        echo ""
        return 0
    fi
    
    echo -e "${BLUE}Found ${#features[@]} feature(s):${NC}"
    echo ""
    
    local total_files=0
    local total_dirs=0
    
    for feature in "${features[@]}"; do
        local feature_path="$features_dir/$feature"
        local file_count=$(find "$feature_path" -type f | wc -l)
        local dir_count=$(find "$feature_path" -type d | wc -l)
        local feature_size=$(du -sh "$feature_path" 2>/dev/null | cut -f1 || echo "N/A")
        
        total_files=$((total_files + file_count))
        total_dirs=$((total_dirs + dir_count))
        
        echo -e "${GREEN}📁 ${feature}${NC}"
        echo "   Path: $feature_path"
        echo "   Files: $file_count | Directories: $dir_count | Size: $feature_size"
        
        # Check for key files
        local key_files=()
        [[ -f "$feature_path/presentation/screens/${feature}_screen.dart" ]] && key_files+=("screen")
        [[ -f "$feature_path/presentation/providers/${feature}_providers.dart" ]] && key_files+=("providers")
        [[ -f "$feature_path/domain/entities/${feature}_entity.dart" ]] && key_files+=("entity")
        [[ -f "$feature_path/domain/repositories/${feature}_repository.dart" ]] && key_files+=("repository")
        
        if [[ ${#key_files[@]} -gt 0 ]]; then
            echo "   Components: $(IFS=', '; echo "${key_files[*]}")"
        fi
        
        # Show recent modification
        local latest_file=$(find "$feature_path" -type f -exec ls -lt {} + | head -1 | awk '{print $6, $7, $8}' 2>/dev/null || echo "Unknown")
        echo "   Last modified: $latest_file"
        echo ""
    done
    
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    echo -e "${BLUE}Summary:${NC}"
    echo "  Total features: ${#features[@]}"
    echo "  Total files: $total_files"
    echo "  Total directories: $total_dirs"
    echo ""
    
    echo -e "${BLUE}Available commands:${NC}"
    echo "  ./scaffold.sh add feature <name>     - Add new feature"
    echo "  ./scaffold.sh remove feature <name>  - Remove feature"
    echo "  ./scaffold.sh reset feature <name>   - Reset feature"
    echo ""
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------
COMMAND=""
FEATURE_NAME=""
PROJECT_NAME=""
PROJECT_LOCATION=""
FLUTTER_OPTIONS=()

parse_args() {
    # Check for help first
    for arg in "$@"; do
        if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
            show_help
            exit 0
        fi
    done
    
    # Parse remaining arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            create)
                COMMAND="create_project"
                PROJECT_NAME="${2:-}"
                if [[ -z "$PROJECT_NAME" ]]; then
                    log_error "Project name is required for create command"
                    echo "Usage: ./scaffold.sh create <project_name> [location] [flutter_options]"
                    exit 1
                fi
                shift 2
                # Remaining arguments could be location and flutter options
                PROJECT_LOCATION="${1:-}"
                shift
                # Collect remaining arguments as flutter options
                while [[ $# -gt 0 ]]; do
                    FLUTTER_OPTIONS+=("$1")
                    shift
                done
                ;;
            reset)
                if [[ "${2:-}" == "project" ]]; then
                    COMMAND="reset_project"
                    shift 2
                elif [[ "${2:-}" == "feature" ]]; then
                    COMMAND="reset_feature"
                    FEATURE_NAME="${3:-}"
                    shift 3 2>/dev/null || shift $#
                else
                    log_error "Unknown reset target: ${2:-}"
                    echo "Usage: ./scaffold.sh reset [project|feature]"
                    exit 1
                fi
                ;;
            add)
                if [[ "${2:-}" == "feature" ]]; then
                    COMMAND="add_feature"
                    FEATURE_NAME="${3:-}"
                    shift 3 2>/dev/null || shift $#
                else
                    log_error "Unknown command: add ${2:-}"
                    exit 1
                fi
                ;;
            remove)
                if [[ "${2:-}" == "feature" ]]; then
                    COMMAND="remove_feature"
                    FEATURE_NAME="${3:-}"
                    shift 3 2>/dev/null || shift $#
                else
                    log_error "Unknown command: remove ${2:-}"
                    exit 1
                fi
                ;;
            info)
                COMMAND="info"
                shift
                ;;
            --force) 
                FORCE=true
                shift
                ;;
            --dry-run) 
                DRY_RUN=true
                shift
                ;;
            --install-deps) 
                INSTALL_DEPS=true
                shift
                ;;
            --skip-deps) 
                SKIP_DEPS=true
                shift
                ;;
            --verify) 
                VERIFY=true
                shift
                ;;
            *) 
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"
    
    # Handle create project command (doesn't need Flutter project check)
    if [[ "$COMMAND" == "create_project" ]]; then
        create_project "$PROJECT_NAME" "$PROJECT_LOCATION" "${FLUTTER_OPTIONS[@]}"
        exit 0
    fi
    
    # Handle reset project command
    if [[ "$COMMAND" == "reset_project" ]]; then
        reset_project
        exit 0
    fi
    
    # Check if we're in a Flutter project for other commands
    check_flutter
    
    # Handle add feature command
    if [[ "$COMMAND" == "add_feature" ]]; then
        add_feature "$FEATURE_NAME"
        exit 0
    fi
    
    # Handle remove feature command
    if [[ "$COMMAND" == "remove_feature" ]]; then
        remove_feature "$FEATURE_NAME"
        exit 0
    fi
    
    # Handle reset feature command
    if [[ "$COMMAND" == "reset_feature" ]]; then
        reset_feature "$FEATURE_NAME"
        exit 0
    fi
    
    # Handle info command
    if [[ "$COMMAND" == "info" ]]; then
        show_info
        exit 0
    fi
    
    echo ""
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Flutter Clean Architecture Scaffold${NC} v${SCRIPT_VERSION}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # If verify only, run verification and exit
    if [[ "$VERIFY" == true ]]; then
        verify_scaffold
        exit $?
    fi
    
    if [[ "$DRY_RUN" == true ]]; then
        log_warning "DRY RUN - no changes will be made"
    fi
    if [[ "$FORCE" == true ]]; then
        log_warning "FORCE - existing files will be overwritten"
    fi
    
    # Create core structure
    log_info "Creating core directories..."
    for dir in "${DIRS[@]}"; do create_dir "$dir"; done
    
    echo ""
    log_info "Creating core files..."
    for file in "${FILES[@]}"; do create_file "$file"; done
    
    # Add home feature using add_feature function
    if [[ "$DRY_RUN" != true ]]; then
        echo ""
        log_info "Adding 'home' feature..."
        add_feature "home"
    fi
    
    echo ""
    echo -e "${CYAN}──────────────────────────────────────────────────────────${NC}"
    
    if [[ "$DRY_RUN" == true ]]; then
        log_success "Dry run complete"
    else
        log_success "Scaffold complete!"
    fi
    
    # Install deps if requested
    if [[ "$INSTALL_DEPS" == true && "$DRY_RUN" != true ]]; then
        echo ""
        install_dependencies
    fi
    
    # Run verification after scaffolding (not in dry-run)
    if [[ "$DRY_RUN" != true ]]; then
        echo ""
        verify_scaffold
    fi
    
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    if [[ "$INSTALL_DEPS" != true ]]; then
        echo "  1. Run './scaffold.sh --install-deps' to add dependencies"
    fi
    echo "  2. Implement app.dart with MaterialApp.router"
    echo "  3. Add your features in lib/src/features/"
    echo ""
}

main "$@"