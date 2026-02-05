/// String utility functions for the Flutter Scaffold CLI.
library;

/// Convert a string to snake_case.
///
/// Example: 'MyFeature' -> 'my_feature'
String toSnakeCase(String input) {
  if (input.isEmpty) return input;

  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (char == char.toUpperCase() && char != char.toLowerCase()) {
      if (i > 0) buffer.write('_');
      buffer.write(char.toLowerCase());
    } else if (char == ' ' || char == '-') {
      buffer.write('_');
    } else {
      buffer.write(char.toLowerCase());
    }
  }
  return buffer.toString();
}

/// Convert a string to PascalCase.
///
/// Example: 'my_feature' -> 'MyFeature'
String toPascalCase(String input) {
  if (input.isEmpty) return input;

  final words = input.split(RegExp(r'[_\s-]+'));
  return words.map((word) {
    if (word.isEmpty) return '';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join();
}

/// Convert a string to camelCase.
///
/// Example: 'my_feature' -> 'myFeature'
String toCamelCase(String input) {
  final pascal = toPascalCase(input);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

/// Validate a Dart/Flutter identifier name.
///
/// Returns true if the name contains only lowercase letters, numbers, and underscores,
/// and starts with a letter.
bool isValidIdentifier(String name) {
  if (name.isEmpty) return false;
  final regex = RegExp(r'^[a-z][a-z0-9_]*$');
  return regex.hasMatch(name);
}

/// Normalize a feature name to snake_case and validate.
///
/// Throws [ArgumentError] if the name is invalid after normalization.
String normalizeFeatureName(String name) {
  if (name.isEmpty) {
    throw ArgumentError('Feature name cannot be empty');
  }

  final normalized = toSnakeCase(name.trim());

  if (!isValidIdentifier(normalized)) {
    throw ArgumentError(
      'Invalid feature name: "$name". Must contain only lowercase letters, '
      'numbers, and underscores, starting with a letter.',
    );
  }

  return normalized;
}

/// Normalize a project name to snake_case and validate.
///
/// Throws [ArgumentError] if the name is invalid after normalization.
String normalizeProjectName(String name) {
  if (name.isEmpty) {
    throw ArgumentError('Project name cannot be empty');
  }

  final normalized = toSnakeCase(name.trim());

  if (!isValidIdentifier(normalized)) {
    throw ArgumentError(
      'Invalid project name: "$name". Must contain only lowercase letters, '
      'numbers, and underscores, starting with a letter.',
    );
  }

  return normalized;
}
