# Changelog

All notable changes to flutter_scaffold will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0-beta] - 2026-02-10

### 🚀 Public Preview Release

This is the first public beta release of flutter_scaffold, a production-grade Flutter project scaffolding tool with Clean Architecture support.

### ✨ Added

#### Core Scaffolding System
- **Project Creation**: `flutter_scaffold create` with advanced options (platforms, organization, description)
- **Existing Project Setup**: `flutter_scaffold init` for adding scaffold to existing Flutter projects
- **Interactive Mode**: Guided setup with `flutter_scaffold interactive`

#### Module Management
- **Feature Modules**: `flutter_scaffold add|remove|reset feature` with complete Clean Architecture structure
- **Model Generation**: `flutter_scaffold add model` with JSON serialization and Freezed support
- **Repository Generation**: `flutter_scaffold add repository` with data sources and mapper support
- **Use Case Generation**: `flutter_scaffold add usecase` with return types and descriptions

#### Template Engine
- **Advanced Conditionals**: `{{if}}/{{else}}/{{endif}}` logic in templates
- **Variable Substitution**: Comprehensive placeholder system for project customization
- **Model Templates**: Support for basic models, JSON serializable, and Freezed models
- **Repository Templates**: Complete repository implementation with remote/local data sources
- **Screen Templates**: Generate screens with automatic routing integration

#### Development Tools
- **Configuration System**: YAML-based configuration with `flutter_scaffold config`
- **Project Information**: `flutter_scaffold info` for project overview
- **Verification System**: `flutter_scaffold --verify` for scaffold structure validation
- **E2E Testing**: Comprehensive testing framework with caching and detailed reporting
- **Dry Run Mode**: Preview all operations without creating files

#### Build & Dependency Management
- **Automatic Dependencies**: Install Riverpod, GoRouter, Freezed, and build tools
- **Build Runner Integration**: Run `dart run build_runner` automatically when needed
- **Dependency Upgrades**: `flutter_scaffold upgrade` for self-updating

#### Developer Experience
- **Colored Console Output**: Beautiful, styled terminal messages with progress indicators
- **Verbose Logging**: Debug information with `--verbose` flag
- **Force Operations**: Override conflicts with `--force` flag
- **Comprehensive Help**: Detailed help system with examples

#### VS Code Extension (v0.1.3)
- **Syntax Highlighting**: Full Dart syntax for `.dart.template` files
- **Template Validation**: Real-time placeholder checking and error detection
- **IntelliSense**: Auto-completion for template variables and control flow
- **Formatting**: Zone-based template formatting with syntax normalization
- **Shadow Analysis**: Uses Dart analyzer for template validation

### 🔧 Technical Improvements

#### Architecture
- **Modular Design**: Separated concerns with service-based architecture
- **Cross-Platform**: Support for Windows, macOS, and Linux
- **Git Integration**: Automatic git operations and hooks
- **Error Handling**: Comprehensive error reporting with stack traces

#### Performance
- **E2E Test Caching**: Skip unchanged tests for faster development cycles
- **Incremental Builds**: Smart detection of changed files
- **Parallel Operations**: Concurrent execution where possible

#### Testing
- **Unit Tests**: Complete coverage for core functionality
- **E2E Tests**: End-to-end validation of all commands
- **Template Testing**: Automated validation of generated code

### 📋 Commands Reference

#### Project Management
```bash
flutter_scaffold create <name>          # Create new project
flutter_scaffold init                    # Initialize existing project
flutter_scaffold interactive             # Interactive guided setup
flutter_scaffold info                    # Show project information
flutter_scaffold upgrade                 # Upgrade to latest version
```

#### Module Management
```bash
flutter_scaffold add feature <name>     # Add feature module
flutter_scaffold add model <name>       # Add data model
flutter_scaffold add repository <name>   # Add repository
flutter_scaffold add usecase <name>      # Add use case
flutter_scaffold remove feature <name>   # Remove feature
```

#### Configuration
```bash
flutter_scaffold config init             # Create config file
flutter_scaffold config show             # Show current config
```

#### Operations
```bash
flutter_scaffold reset feature <name>    # Reset feature
flutter_scaffold reset project          # Reset entire project
flutter_scaffold --verify               # Verify structure
flutter_scaffold --install-deps         # Install dependencies
```

### 🎯 Breaking Changes

This is a beta release. While the API is stabilizing, some breaking changes may occur before the stable release. Key areas that may change:

- Template variable names may be refined
- Configuration file structure may evolve
- Command-line argument structure may be adjusted based on feedback

### 🔮 Roadmap

#### Next Releases (v0.1.x)
- [ ] Plugin system for custom templates
- [ ] Database integration templates
- [ ] State management variants (BLoC,GetX)
- [ ] CI/CD template generation
- [ ] Webhooks integration

#### v0.2.0
- [ ] GUI/IDE integration
- [ ] Template marketplace
- [ ] Advanced project templates
- [ ] Multi-module project support

### 🤝 Feedback

As a beta release, feedback is crucial! Please report issues and suggestions through:
- GitHub Issues: https://github.com/jinto-ag/flutter_scaffold/issues
- GitHub Discussions: https://github.com/jinto-ag/flutter_scaffold/discussions

---

## [Unreleased] - Work in Progress

### Potential Features
- Plugin system implementation
- Additional template packs
- Enhanced error recovery
- Performance optimizations
