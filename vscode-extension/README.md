# Flutter Scaffold Template Extension

A VS Code extension that provides syntax highlighting, linting, formatting, and IntelliSense for `flutter_scaffold` template files (`.dart.template`).

## Features

### 🎨 Syntax Highlighting

- Full Dart syntax highlighting for `.dart.template` files.
- Shell syntax highlighting for hook templates (`pre-commit.template`, etc.).
- **Smart Highlighting**: Distinguishes between control flow (`{{if}}`, `{{else}}`) and variable placeholders (`{{variable}}`).

### 🛠️ Robust Formatting

- **Zone-Based Formatting**: Intelligently handles structural breaks in templates (e.g., `{{if}}` inside a constructor) by formatting code zones independently.
- **Syntax Normalization**: Automatically cleans up template syntax:
  - Trims whitespace in tags: `{{ if HAS_FIELDS }}` → `{{if HAS_FIELDS}}`
  - Normalizes control lines.
  - Removes excessive blank lines.
- **Valid Dart Parsing**: Uses deterministic placeholder mapping (e.g., `{{PASCAL_NAME}}` → `Tmpl0Placeholder`) to ensure templates are treated as valid Dart code during formatting.

### ✅ Linting & Validation

- **Placeholder Validation**: Checks against a list of known placeholders (e.g., `projectName`, `featureName`).
- **Nesting Verification**: Detects unmatched `{{if}}`/`{{endif}}` blocks.
- **Red Squiggles**: Clearly highlights unknown placeholders or broken logic.

### 💡 IntelliSense & Analysis

- **Shadow Analysis**: Creates a hidden `.__analysis__.dart` file to leverage the standard Dart analyzer for code completion and errors within your template.
- **Hover Information**: Shows descriptions for standard placeholders.
- **Auto-completion**: Suggests available placeholders and control flow keywords.

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
code --install-extension flutter-scaffold-template-0.1.7.vsix
```

## Supported Placeholders

| Placeholder              | Description                                 |
| :----------------------- | :------------------------------------------ |
| `{{projectName}}`        | Project name from pubspec.yaml (snake_case) |
| `{{featureName}}`        | Feature name in snake_case                  |
| `{{FeatureName}}`        | Feature name in PascalCase                  |
| `{{PASCAL_NAME}}`        | Entity/Feature name in PascalCase           |
| `{{MODEL_NAME}}`         | Model name (snake_case)                     |
| `{{PASCAL_MODEL_NAME}}`  | Model name (PascalCase)                     |
| `{{screenName}}`         | Screen name (camelCase/snake_case context)  |
| `{{PASCAL_SCREEN_NAME}}` | Screen name (PascalCase)                    |
| `{{FIELDS}}`             | List of model fields                        |
| `{{HAS_FIELDS}}`         | Boolean conditional for fields presence     |

## Configuration

| Setting                                         | Default | Description                       |
| :---------------------------------------------- | :------ | :-------------------------------- |
| `flutterScaffoldTemplate.enableLinting`         | `true`  | Enable linting for template files |
| `flutterScaffoldTemplate.enableFormatOnSave`    | `true`  | Format template files on save     |
| `flutterScaffoldTemplate.placeholderValidation` | `true`  | Validate placeholder names        |

## File Associations

| Pattern               | Language       |
| :-------------------- | :------------- |
| `*.dart.template`     | Dart Template  |
| `pre-commit.template` | Shell Template |
| `commit-msg.template` | Shell Template |
| `setup.sh.template`   | Shell Template |
