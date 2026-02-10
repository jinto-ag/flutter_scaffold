# GitHub Setup

This repository uses a comprehensive GitHub setup for professional development workflows.

## 🚀 Branch Protection

- **Default Branch**: `main`
- **Protection Rules**: 
  - Require PR review (1 approval)
  - Require status checks to pass
  - Restrict pushes to maintainers
  - Include CI/CD Pipeline and Code Quality checks

## 🔄 CI/CD Pipeline

### Workflows

1. **CI/CD Pipeline** (`.github/workflows/ci-cd.yml`)
   - Triggers: Push to `main`/`dev`, Pull Requests
   - Tests: Unit tests, E2E tests, code quality
   - Build: Multi-platform (Windows, macOS, Linux)
   - Release: Automatic GitHub releases
   - Security: Trivy vulnerability scanning

2. **Code Quality** (`.github/workflows/code-quality.yml`)
   - Triggers: Pull Requests to `main`/`dev`
   - CodeQL analysis
   - Formatting and linting checks
   - Test coverage reporting

3. **Dependency Updates** (`.github/workflows/dependency-update.yml`)
   - Triggers: Weekly schedule (Mondays 9:00 UTC)
   - Automatic dependency updates
   - PR creation for updates

### Status Checks

Required status checks for merging to `main`:

- **CI/CD Pipeline**: 
  - Flutter Scaffold CLI tests pass
  - VS Code Extension tests pass
  - Security scan passes

- **Code Quality**:
  - CodeQL analysis passes
  - Code formatting is correct
  - No critical vulnerabilities

## 🏗️ Build Process

### Flutter Scaffold CLI
```bash
# Test
dart test
dart run test/e2e/e2e_runner.dart --quick

# Build
dart compile exe bin/flutter_scaffold.dart -o bin/flutter_scaffold

# Package
tar -czf flutter_scaffold.tar.gz -C dist .
```

### VS Code Extension
```bash
# Test
npm test
npm run lint

# Compile
npm run compile

# Package
npm run package
```

## 🚀 Release Process

1. **Trigger**: Push to `main` branch
2. **Verification**: All status checks must pass
3. **Automatic Release**:
   - GitHub release created
   - Artifacts uploaded
   - Version tagged
   - Optional: Pub.dev publishing

### Release Artifacts

- **CLI Binaries**: `flutter_scaffold-{OS}-{SHA}.tar.gz`
- **VS Code Extension**: `flutter-scaffold-template-{VERSION}.vsix`
- **Source Code**: Automatically included in release

## 🔐 Security

- **Automated Scanning**: Trivy vulnerability scanner
- **CodeQL Analysis**: GitHub's advanced static analysis
- **Dependency Checks**: Known vulnerability database
- **Manual Reporting**: Security policy defined in `SECURITY.md`

## 📊 Monitoring

- **Test Coverage**: Codecov integration
- **Build Status**: GitHub Actions status
- **Dependency Health**: Automated updates
- **Security**: Continuous vulnerability scanning