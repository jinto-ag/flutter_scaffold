# Flutter Scaffold Template Extension

A VS Code extension that provides syntax highlighting, linting, and IntelliSense for flutter_scaffold template files.

## Features

### 🎨 Syntax Highlighting

- Full Dart syntax highlighting for `.dart.template` files
- Shell syntax highlighting for hook templates
- Special highlighting for `{{placeholder}}` patterns

### ✅ Linting

- Validates placeholder names against known placeholders
- Shows warnings for unknown placeholders

### 💡 IntelliSense

- Hover information for placeholders
- Autocompletion for placeholder names

## Installation

### From Source

```bash
cd vscode-extension
npm install
npm run compile
```

Then press `F5` in VS Code to run the extension in development mode.

### Package for Distribution

```bash
npm run package
code --install-extension flutter-scaffold-template-0.1.0.vsix
```

## Supported Placeholders

| Placeholder       | Description                                 |
| ----------------- | ------------------------------------------- |
| `{{projectName}}` | Project name from pubspec.yaml (snake_case) |
| `{{featureName}}` | Feature name in snake_case                  |
| `{{FeatureName}}` | Feature name in PascalCase                  |

## Configuration

| Setting                                         | Default | Description                       |
| ----------------------------------------------- | ------- | --------------------------------- |
| `flutterScaffoldTemplate.enableLinting`         | `true`  | Enable linting for template files |
| `flutterScaffoldTemplate.enableFormatOnSave`    | `true`  | Format template files on save     |
| `flutterScaffoldTemplate.placeholderValidation` | `true`  | Validate placeholder names        |

## File Associations

| Pattern               | Language       |
| --------------------- | -------------- |
| `*.dart.template`     | Dart Template  |
| `pre-commit.template` | Shell Template |
| `commit-msg.template` | Shell Template |
| `setup.sh.template`   | Shell Template |
