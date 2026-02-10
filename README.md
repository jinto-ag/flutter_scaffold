# Flutter Scaffold CLI

A **production-grade Dart CLI tool** for scaffolding Flutter projects with Clean Architecture. Replaces the legacy `scaffold.sh` script with a modular, testable, cross-platform Dart implementation powered by a robust template engine.

## Features

- 🏗️ **Clean Architecture Structure** - Organized layers: core, routing, shared, features
- 📦 **Feature Modules** - Add/remove/reset feature modules with full structure
- 📝 **Robust Template Engine** - Uses `.dart.template` files with logical conditionals (`{{if}}`, `{{else}}`)
- 🔧 **Dependency Management** - Auto-install Riverpod, GoRouter, Freezed
- 🛠️ **Code Generation** - Integrated build_runner support
- ✅ **Verification** - Built-in scaffold verification with detailed reporting
- 🎨 **Beautiful Output** - Colored, styled console messages
- 🔍 **Project Management** - Info display and project-level operations
- ⚙️ **Configuration** - YAML-based configuration management
- 🚀 **Interactive Mode** - Guided setup for new projects
- 📦 **Package Management** - Built-in upgrade system

## 🔌 VS Code Extension

For the best development experience when editing templates or working with the scaffold structure, install the **Flutter Scaffold Template** extension.

- **Syntax Highlighting** for template files
- **IntelliSense & Auto-completion**
- **Template Formatting & Validation**

[👉 View Extension README](vscode-extension/README.md)

## Installation

### Global Activation (Recommended)

```bash
# Clone and activate globally
git clone <repository-url>
cd flutter_scaffold
dart pub global activate --source path .

# Now available system-wide:
flutter_scaffold <command>
```

### Local Development

```bash
# Run directly from source
dart run bin/flutter_scaffold.dart <command>

# Or activate locally for this project
dart pub global activate --source path . --executable flutter_scaffold
```

### Requirements

- Dart SDK 3.0+
- Flutter SDK 3.0+
- Git (for project operations)

## Usage

### 🚀 Quick Start

```bash
# Interactive guided setup
flutter_scaffold interactive

# Create new project
flutter_scaffold create my_app
cd my_app
flutter_scaffold info  # See project details
```

### 📁 Project Creation

```bash
# Basic project creation
flutter_scaffold create my_app

# Advanced options
flutter_scaffold create my_app \
  --org com.mycompany \
  --platforms android,ios,web,macos,windows,linux \
  --description "My Awesome App" \
  --skip-deps

# Create in current directory (existing Flutter project)
flutter_scaffold init
```

### 🔧 Configuration Management

```bash
# Create configuration file
flutter_scaffold config init

# View current configuration
flutter_scaffold config show
```

### 📦 Feature Management

```bash
# Add basic feature
flutter_scaffold add feature auth

# Add feature with screen and model
flutter_scaffold add feature user \
  --screen profile \
  --model person \
  --json-serializable \
  --field id:int \
  --field name:String \
  --field email:String \
  --force

# Add feature with Freezed model
flutter_scaffold add feature product \
  --model item \
  --freezed \
  --field id:String \
  --field title:String \
  --field price:double

# Remove feature
flutter_scaffold remove feature auth

# Reset feature to initial state
flutter_scaffold reset feature auth --dry-run  # Preview first
flutter_scaffold reset feature auth --force     # Execute
```

### 🏗️ Module Management

```bash
# Add model to existing feature
flutter_scaffold add model user \
  --feature auth \
  --json-serializable \
  --field id:int \
  --field name:String \
  --field email:String

# Add use case to feature
flutter_scaffold add usecase login \
  --feature auth \
  --return-type User \
  --description "User authentication"

# Add repository with datasources
flutter_scaffold add repository user \
  --feature auth \
  --include-datasources \
  --include-mapper
```

### 📊 Project Operations

```bash
# Display detailed project information
flutter_scaffold info

# Verify scaffold structure
flutter_scaffold --verify

# Install/upgrade dependencies
flutter_scaffold --install-deps

# Show version
flutter_scaffold --version

# Enable verbose logging
flutter_scaffold --verbose create my_app
```

### 🔄 System Operations

```bash
# Upgrade to latest version
flutter_scaffold upgrade

# Reset entire project (destructive)
flutter_scaffold reset project --dry-run  # Preview first
flutter_scaffold reset project --force     # Execute
```

## Generated Structure

```text
lib/src/
├── app.dart                      # MaterialApp.router configuration
├── core/
│   ├── errors/                   # Exception & Failure types
│   ├── extensions/               # Dart/Flutter extensions
│   ├── theme/                    # Theme configuration
│   └── utils/                    # Utilities (logger, etc.)
├── routing/                      # GoRouter configuration
├── shared/
│   ├── providers/                # Global Riverpod providers
│   └── widgets/                  # Reusable widgets
└── features/
    └── <feature>/                # Feature modules
        ├── data/                 # Data sources, models, repo implementations
        │   ├── datasources/      # Remote and local data sources
        │   ├── models/           # Data models with serialization
        │   └── repositories/     # Repository implementations
        ├── domain/               # Entities, repository interfaces, use cases
        │   ├── entities/         # Business entities
        │   ├── repositories/     # Repository interfaces
        │   └── usecases/         # Business logic
        └── presentation/         # Screens, widgets, providers
            ├── providers/        # Riverpod providers
            ├── screens/          # UI screens
            └── widgets/          # Feature-specific widgets
```

### Configuration File

Create `flutter_scaffold.yaml` in project root for customization:

```yaml
# flutter_scaffold.yaml
project:
  org: com.mycompany
  platforms: [android, ios, web]
  description: "My Flutter App"

features:
  default_model_options:
    json_serializable: true
    freezed: false
  
  default_screen_options:
    type: list  # list, detail, form

dependencies:
  riverpod: ^2.4.0
  go_router: ^12.1.0
  freezed_annotation: ^2.4.0
```

## Dependencies

Automatically installs and manages:

### Core Dependencies
- `flutter_riverpod`, `riverpod_annotation` - State management
- `go_router` - Declarative routing
- `freezed_annotation`, `json_annotation` - Code generation

### Development Dependencies
- `riverpod_generator`, `build_runner`, `freezed`, `json_serializable`

### Optional Dependencies
- `http` - For API data sources
- `path_provider` - For local storage
- `shared_preferences` - For local caching

## Advanced Features

### Template Engine
- **Conditionals**: `{{if HAS_FIELDS}}...{{else}}...{{endif}}`
- **Variables**: `{{projectName}}`, `{{featureName}}`, `{{PASCAL_NAME}}`
- **Loops**: `{{for field in FIELDS}}...{{endfor}}`
- **Logic**: Boolean operations and string transformations

### Dry Run Mode
Preview all operations without creating files:

```bash
flutter_scaffold add feature auth --dry-run
flutter_scaffold reset project --dry-run
```

### Force Operations
Override existing files and conflicts:

```bash
flutter_scaffold add feature auth --force
flutter_scaffold reset feature user --force
```

## Development

### Running Tests

```bash
# Unit tests
dart test

# E2E tests (comprehensive)
dart run test/e2e/e2e_runner.dart

# E2E with options
dart run test/e2e/e2e_runner.dart --quick
dart run test/e2e/e2e_runner.dart --fail-fast
dart run test/e2e/e2e_runner.dart --reset-output
dart run test/e2e/e2e_runner.dart --cache-stats
```

### Code Quality

```bash
# Analyze code
dart analyze

# Run build runner
dart run build_runner build

# Run build runner with watch
dart run build_runner watch --delete-conflicting-outputs
```

### CLI Development

```bash
# Run CLI locally
dart run bin/flutter_scaffold.dart --help

# Run with verbose logging
dart run bin/flutter_scaffold.dart --verbose create test_app

# Test specific commands
dart run bin/flutter_scaffold.dart add feature test --dry-run
```

## 🛠️ Troubleshooting

### Common Issues

1. **Command not found after installation**
   ```bash
   # Refresh your shell path
   dart pub global activate --source path . --executable flutter_scaffold
   ```

2. **Build runner fails**
   ```bash
   # Clean and rebuild
   flutter pub get
   dart run build_runner clean
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Import errors after adding features**
   ```bash
   # Run verification
   flutter_scaffold --verify
   flutter pub get
   ```

4. **Template errors**
   - Check VS Code extension for template validation
   - Verify placeholder names in `.dart.template` files

### Getting Help

```bash
# General help
flutter_scaffold --help

# Command-specific help
flutter_scaffold help add
flutter_scaffold help add feature
flutter_scaffold help config
```

## 📚 Additional Resources

- **VS Code Extension**: [Extension README](vscode-extension/README.md)
- **Template Development**: See `lib/src/templates/` directory
- **Configuration**: Run `flutter_scaffold config init` for sample file
- **E2E Testing**: See `test/e2e/` directory

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Run tests: `dart test` and `dart run test/e2e/e2e_runner.dart --quick`
4. Commit changes with conventional format: `✨ feat(feature): add amazing feature`
5. Push to branch: `git push origin feature/amazing-feature`
6. Open a Pull Request

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Version

Current version: **0.1.0-beta** - Public Preview Release

Run `flutter_scaffold --version` for the latest version information.

### 🚀 Beta Status

This is a public preview release. The core functionality is stable and ready for production use, but some features may evolve based on community feedback.

**What's Stable:**
- ✅ Project creation and initialization
- ✅ Feature/module management
- ✅ Template engine and generation
- ✅ Configuration system
- ✅ Build integration
- ✅ VS Code extension

**What May Evolve:**
- 🔄 Template variable names
- 🔄 Configuration structure
- 🔄 Command-line arguments
- 🔄 Plugin system (upcoming)
