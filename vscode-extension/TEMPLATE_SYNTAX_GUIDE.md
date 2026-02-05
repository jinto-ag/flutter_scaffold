# Template Syntax Guide

This guide covers the complete template syntax used in the flutter_scaffold project, including conditional logic and variable substitution.

## Overview

Templates use double curly braces `{{ }}` to denote placeholders and control flow directives. The template system supports both simple variable substitution and complex conditional logic.

## Variables

### Simple Variable Substitution

Basic variable replacement uses the following syntax:

```dart
{{variableName}}
```

### Built-in Variables

- `projectName` - The Flutter project name from pubspec.yaml (snake_case)
- `featureName` - The feature name in snake_case (e.g., my_feature)
- `FeatureName` - The feature name in PascalCase (e.g., MyFeature)

### Examples

```dart
class {{FeatureName}}Screen extends StatelessWidget {
  const {{FeatureName}}Screen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('{{FeatureName}}'),
      ),
    );
  }
}
```

## Conditional Logic

### If Statements

Basic conditional blocks:

```dart
{{if condition}}
  // Code to include when condition is true
{{endif}}
```

### If-Else Statements

Two-way conditional logic:

```dart
{{if condition}}
  // Code when condition is true
{{else}}
  // Code when condition is false
{{endif}}
```

### If-Else If-Else Statements

Multi-way conditional logic:

```dart
{{if condition1}}
  // Code when condition1 is true
{{else if condition2}}
  // Code when condition1 is false and condition2 is true
{{else}}
  // Code when all conditions are false
{{endif}}
```

### Supported Conditions

Conditional statements can use any of these boolean variables:

- `projectName` - Evaluates to true if project name is set
- `featureName` - Evaluates to true if feature name is set
- `FeatureName` - Evaluates to true if feature name is set
- Any custom boolean variable passed to the template engine

### Example: Widget with Conditional Imports

```dart
import 'package:flutter/material.dart';

{{if useRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{endif}}

{{if useBloc}}
import 'package:flutter_bloc/flutter_bloc.dart';
{{endif}}

class MyWidget extends {{if useRiverpod}}ConsumerWidget{{else if useBloc}}StatelessWidget{{else}}StatelessWidget{{endif}} {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context{{if useRiverpod}}, WidgetRef ref{{endif}}) {
    return Scaffold(
      body: Center(
        child: Text('Hello {{if featureName}}{{featureName}}{{else}}World{{endif}}!'),
      ),
    );
  }
}
```

## Nesting

Conditional blocks can be nested to create complex logic:

```dart
{{if useRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    {{if showLoading}}
    final isLoading = ref.watch(loadingProvider);
    
    if (isLoading) {
      return const CircularProgressIndicator();
    }
    {{endif}}
    
    {{if showError}}
    final error = ref.watch(errorProvider);
    
    if (error != null) {
      return Text('Error: $error');
    }
    {{endif}}
    
    return const Text('Content loaded!');
  }
}
{{endif}}
```

## Shell Script Templates

Shell script templates support the same conditional syntax:

```bash
#!/bin/bash

{{if enablePreCommit}}
echo "Running pre-commit hooks..."
{{else if enablePrePush}}
echo "Running pre-push hooks..."
{{else}}
echo "No hooks enabled"
{{endif}}

{{if runTests}}
echo "Running tests..."
dart test
{{endif}}

{{if enableLinting}}
echo "Running linter..."
dart analyze
{{endif}}
```

## Whitespace Handling

The template engine automatically handles whitespace around conditional directives:

- Leading and trailing whitespace inside `{{ }}` is ignored
- Empty lines resulting from conditional blocks are cleaned up
- Proper indentation is preserved for included content

## Error Handling

### Validation Errors

The VS Code extension provides real-time validation for:

- **Unmatched conditional blocks**: Missing `{{endif}}` or orphaned `{{else}}` statements
- **Unknown placeholders**: Variables not in the recognized set
- **Invalid syntax**: Malformed conditional expressions

### Common Errors and Solutions

#### Missing Endif
```dart
{{if useRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Error: Missing {{endif}}
```

**Solution**: Add the missing `{{endif}}`

#### Unmatched Else
```dart
{{else}}
// Error: Unmatched else - no corresponding if
```

**Solution**: Remove the orphaned `{{else}}` or add the missing `{{if}}`

#### Unknown Variable
```dart
{{unknownVariable}}
// Warning: Unknown placeholder
```

**Solution**: Use a recognized variable or define a custom one

## Best Practices

### 1. Use Clear Variable Names
```dart
{{if useRiverpod}}  // Good
{{if flag}}         // Less clear
```

### 2. Keep Conditional Blocks Simple
```dart
{{if useRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{endif}}

// Separate the conditional logic from the usage
class MyWidget extends {{if useRiverpod}}ConsumerWidget{{else}}StatelessWidget{{endif}} {
  // ...
}
```

### 3. Document Complex Conditions
For complex templates, consider adding comments to explain the logic:

```dart
{{if useRiverpod}}
// Riverpod is used for state management in this template
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{endif}}
```

### 4. Test with Different Variable Combinations

Always test your templates with different variable combinations:

- With and without each conditional variable
- Different combinations of true/false conditions
- Edge cases (empty strings, special characters)

## Advanced Features

### Variable Substitution in Conditions

You can use variable values inside conditional content:

```dart
{{if featureName}}
class {{FeatureName}}Screen extends StatelessWidget {
  const {{FeatureName}}Screen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('{{FeatureName}}'),
      ),
    );
  }
}
{{endif}}
```

### Complex Expressions

While the template engine primarily focuses on boolean conditions, you can create complex logic through nesting:

```dart
{{if useRiverpod}}
  {{if showLoading}}
    // Show loading indicator
  {{endif}}
  
  {{if showError}}
    // Show error message
  {{endif}}
{{endif}}
```

## Troubleshooting

### Extension Not Recognizing Conditional Keywords

If the VS Code extension doesn't recognize conditional keywords:

1. Ensure you're using the correct file extension (`.dart.template` or shell script template names)
2. Check that the extension is properly installed and activated
3. Verify the syntax matches the patterns shown in this guide
4. Restart VS Code if necessary

### Template Not Processing Correctly

If templates aren't processing as expected:

1. Check the variable names match the recognized set
2. Ensure conditional blocks are properly nested
3. Verify all `{{if}}` statements have corresponding `{{endif}}`
4. Check for typos in variable names

### Performance Considerations

For large templates:

- Minimize nesting depth where possible
- Use simple boolean conditions
- Consider breaking complex templates into smaller, reusable components

## Migration Guide

### Upgrading from Simple Variable Templates

If you're upgrading templates that only use simple variable substitution:

1. Identify areas where conditional logic would be beneficial
2. Add conditional blocks around optional imports or code sections
3. Test with both enabled and disabled conditions
4. Update documentation to reflect new conditional capabilities

### Example Migration

**Before (simple variables only):**
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';  // Always imported

class {{FeatureName}}Screen extends ConsumerWidget {
  // ...
}
```

**After (with conditional logic):**
```dart
import 'package:flutter/material.dart';

{{if useRiverpod}}
import 'package:flutter_riverpod/flutter_riverpod.dart';
{{endif}}

class {{FeatureName}}Screen extends {{if useRiverpod}}ConsumerWidget{{else}}StatelessWidget{{endif}} {
  // ...
}
```

This migration makes the template more flexible and reduces unnecessary imports for projects that don't use Riverpod.

---

For more examples, see the test templates in the `lib/src/templates/test/` directory:

- `conditional_screen.dart.template` - Basic conditional logic
- `nested_conditional.dart.template` - Complex nested conditions
- `conditional_hooks.sh.template` - Shell script conditional logic