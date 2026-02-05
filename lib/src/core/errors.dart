/// Custom exceptions for the Flutter Scaffold CLI.
library;

/// Base exception for scaffold operations.
sealed class ScaffoldException implements Exception {
  const ScaffoldException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when file system operations fail.
class FileSystemException extends ScaffoldException {
  const FileSystemException(super.message);
}

/// Thrown when a project validation fails.
class ProjectValidationException extends ScaffoldException {
  const ProjectValidationException(super.message);
}

/// Thrown when a process execution fails.
class ProcessException extends ScaffoldException {
  const ProcessException(super.message, {this.exitCode});

  final int? exitCode;

  @override
  String toString() =>
      '$message${exitCode != null ? ' (exit code: $exitCode)' : ''}';
}

/// Thrown when a feature operation fails.
class FeatureException extends ScaffoldException {
  const FeatureException(super.message);
}

/// Thrown when user input validation fails.
class ValidationException extends ScaffoldException {
  const ValidationException(super.message);
}
