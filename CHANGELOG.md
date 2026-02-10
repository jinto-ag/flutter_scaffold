# Changelog

All notable changes to flutter_scaffold will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-10

### Added
- 🎉 Production-grade Flutter project scaffolding with Clean Architecture
- ✨ Feature module management (add/remove/reset)
- 🏗️ Robust template engine with conditionals and variables
- 📦 Automatic dependency management (Riverpod, GoRouter, Freezed)
- 🛠️ Integrated build_runner support
- ✅ Scaffold structure verification
- 🎨 Colored console output with detailed logging
- 🔍 Project information display and management
- ⚙️ YAML-based configuration system
- 🚀 Interactive guided setup mode
- 📦 Package management with upgrade system
- 🧪 Comprehensive E2E testing framework
- 🔧 VS Code extension for template development

### Features
- **Command System**
  - `create` - New project creation with advanced options
  - `init` - Initialize scaffold in existing Flutter project
  - `add feature|model|repository|usecase` - Module management
  - `remove feature` - Feature removal
  - `reset feature|project` - Reset operations
  - `config init|show` - Configuration management
  - `info` - Project information display
  - `upgrade` - Self-upgrade system
  - `interactive` - Guided setup mode

- **Template Engine**
  - Support for `{{if}}/{{else}}/{{endif}}` conditionals
  - Variable substitution with comprehensive placeholders
  - Model generation with JSON serialization and Freezed support
  - Repository generation with data sources
  - Use case generation with return types
  - Screen generation with routing integration

- **Development Tools**
  - E2E testing with caching and detailed reporting
  - Dry-run mode for all operations
  - Force operations for conflict resolution
  - Verbose logging for debugging
  - Comprehensive error handling and validation

- **VS Code Extension**
  - Syntax highlighting for `.dart.template` files
  - Template validation and placeholder checking
  - IntelliSense and auto-completion
  - Zone-based formatting with syntax normalization
  - Shadow analysis using Dart analyzer

### Technical
- Modular architecture with service separation
- Comprehensive unit and E2E test coverage
- Cross-platform support (Windows, macOS, Linux)
- Git integration for project operations
- Hook system for custom build steps

## [1.0.0] - Initial Release

- Initial version.
