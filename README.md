# Flutter Scaffold CLI

A **production-grade Dart CLI tool** for scaffolding Flutter projects with Clean Architecture. Replaces the bash-based `scaffold.sh` with a modular, testable, cross-platform Dart implementation.

## Features

- 🏗️ **Clean Architecture Structure** - Organized layers: core, routing, shared, features
- 📦 **Feature Modules** - Add/remove/reset feature modules with full structure
- 🔧 **Dependency Management** - Auto-install Riverpod, GoRouter, Freezed
- 🛠️ **Code Generation** - Integrated build_runner support
- ✅ **Verification** - Built-in scaffold verification
- 🎨 **Beautiful Output** - Colored, styled console messages

## Installation

```bash
# Clone and activate globally
dart pub global activate --source path .

# Or run directly
dart run bin/flutter_scaffold.dart <command>
```

## Usage

### Create New Project

```bash
# Create project with scaffold
flutter_scaffold create my_app

# Create with custom org and platforms
flutter_scaffold create my_app --org com.mycompany --platforms android,ios,web

# Create without installing dependencies
flutter_scaffold create my_app --skip-deps
```

### Apply to Existing Project

```bash
# Apply scaffold to current directory
flutter_scaffold scaffold

# With dependency installation
flutter_scaffold scaffold --install-deps
```

### Manage Features

```bash
# Add a feature
flutter_scaffold add feature auth

# Remove a feature
flutter_scaffold remove feature auth

# Reset a feature to initial state
flutter_scaffold reset feature auth
```

### Project Operations

```bash
# View project info
flutter_scaffold info

# Reset entire project (destructive)
flutter_scaffold reset project

# Verify scaffold structure
flutter_scaffold --verify

# Install dependencies
flutter_scaffold --install-deps
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
        ├── domain/               # Entities, repository interfaces, use cases
        └── presentation/         # Screens, widgets, providers
```

## Dependencies

Automatically installs:

- `flutter_riverpod`, `riverpod_annotation` - State management
- `go_router` - Declarative routing
- `freezed_annotation`, `json_annotation` - Code generation
- Dev: `riverpod_generator`, `build_runner`, `freezed`, `json_serializable`

## Development

```bash
# Run tests
dart test

# Analyze code
dart analyze

# Run CLI locally
dart run bin/flutter_scaffold.dart --help
```

## License

MIT
