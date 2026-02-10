# Contributing to flutter_scaffold

We love your input! We want to make contributing to flutter_scaffold as easy and transparent as possible, whether it's:

- Reporting a bug
- Discussing the current state of the code
- Submitting a fix
- Proposing new features
- Becoming a maintainer

## Development Process

We use GitHub to host code, to track issues and feature requests, as well as accept pull requests.

## Pull Requests

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

1. **Fork** the repo and create your branch from `dev`.
2. **If you've added code that should be tested**, add tests.
3. **If you've changed APIs**, update the documentation.
4. **Ensure the test suite passes**.
5. **Make sure your code lints**.
6. **Issue that pull request!**

### Requirements

Before submitting your PR, please ensure:

- [ ] **Code follows our style** (run `dart analyze`)
- [ ] **Self-review** your changes
- [ ] **Add tests** for new functionality
- [ ] **Update documentation** if needed
- [ ] **All tests pass** (`dart test`)
- [ ] **E2E tests pass** (`dart run test/e2e/e2e_runner.dart --quick`)
- [ ] **Commit messages follow conventional format**
  ```
  🎉 feat(scope): add amazing feature
  🐛 fix(scope): resolve issue
  📝 docs(scope): update documentation
  🔧 chore(scope): maintenance task
  ```

### Pull Request Process

1. **Update the README.md** with details of changes if applicable
2. **Update the CHANGELOG.md** following the format
3. **You may merge the Pull Request** once you have the sign-off of two other maintainers
4. **Please don't** merge your own PR unless you have explicit approval

## Setting Up Development Environment

### Prerequisites

- Dart SDK 3.0+
- Flutter SDK 3.0+
- Git

### Local Development

```bash
# Clone the repository
git clone https://github.com/jinto-ag/flutter_scaffold.git
cd flutter_scaffold

# Install dependencies
dart pub get

# Run locally
dart run bin/flutter_scaffold.dart --help

# Install for development
dart pub global activate --source path .

# Run tests
dart test

# Run E2E tests
dart run test/e2e/e2e_runner.dart --quick
```

### Running Tests

```bash
# Unit tests
dart test

# E2E tests (comprehensive)
dart run test/e2e/e2e_runner.dart

# E2E quick tests
dart run test/e2e/e2e_runner.dart --quick

# With verbose output
dart run test/e2e/e2e_runner.dart --verbose
```

## Project Structure

```
lib/src/
├── commands/          # CLI command implementations
├── services/         # Core business logic
├── templates/        # Template files for code generation
├── core/            # Core utilities and version
└── utils/           # Helper utilities

test/
├── unit/            # Unit tests
└── e2e/            # End-to-end tests
```

## Code Style

### Dart Conventions

- Follow [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` for code formatting
- Keep lines under 80 characters
- Use descriptive variable and function names

### Template Conventions

- Use snake_case for template variables
- Use PascalCase for class names in templates
- Include proper error handling in generated code
- Follow Clean Architecture principles

### Commit Messages

We follow [Conventional Commits](https://www.conventionalcommits.org/) with emojis:

```
<emoji> <type>(<scope>): <description>

Examples:
🎉 feat(cli): add interactive mode
🐛 fix(templates): resolve model generation issue
📝 docs(readme): update installation guide
🔧 chore(deps): update dependencies
🧪 test(e2e): add feature validation
```

### Valid Types and Emojis

- 🎉/✨ feat - New feature
- 🐛/🔒 fix - Bug fix
- 📝 docs - Documentation
- 🎨/💄 style - Styling/formatting
- ♻️ refactor - Code refactoring
- 🧪/✅ test - Tests
- 🔧/⬆️ chore - Dependencies/maintenance
- 🚀 perf - Performance
- 🏗️/📦 build - Build system

## Release Process

We use [Semantic Versioning](https://semver.org/) for releases.

### Version Numbers

- `MAJOR.MINOR.PATCH`
- Pre-release: `MAJOR.MINOR.PATCH-<prerelease>`
- Beta: `MAJOR.MINOR.PATCH-beta`

### Release Checklist

Before creating a release:

- [ ] All tests pass
- [ ] Documentation is updated
- [ ] CHANGELOG.md is updated
- [ ] Version is updated in pubspec.yaml
- [ ] GitHub release is created
- [ ] VS Code extension is updated if needed

## Areas of Contribution

### High Priority

1. **Template Development**: New templates for different architectures
2. **Plugin System**: Support for custom plugins
3. **Integration**: IDE integrations beyond VS Code
4. **Documentation**: Better examples and tutorials

### Medium Priority

1. **Performance**: Optimizing template generation
2. **Testing**: Better test coverage and E2E scenarios
3. **Localization**: Multi-language support
4. **Accessibility**: Better CLI accessibility

### Low Priority

1. **GUI**: Graphical interface
2. **Advanced Features**: Multi-module project support
3. **Integrations**: CI/CD platform templates

## Getting Help

If you need help contributing:

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For general questions and ideas
- **Email**: For security issues (see SECURITY.md)

## Code of Conduct

Please note that this project is released with a [Contributor Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project you agree to abide by its terms.

## Recognition

We recognize all contributors in our [README.md] and [AUTHORS.md] files. Significant contributors may be invited to become maintainers.

Thank you for contributing! 🎉