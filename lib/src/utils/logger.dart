/// Logging utilities for the Flutter Scaffold CLI.
library;

import 'package:mason_logger/mason_logger.dart';

/// Logger instance for the scaffold CLI.
class ScaffoldLogger {
  ScaffoldLogger({Logger? logger, bool verbose = false})
    : _logger = logger ?? Logger(),
      _verbose = verbose;

  final Logger _logger;
  final bool _verbose;

  /// Global verbose flag for singleton usage.
  static bool globalVerbose = false;

  /// Whether verbose logging is enabled.
  bool get isVerbose => _verbose || globalVerbose;

  /// Log info message.
  void info(String message) => _logger.info(message);

  /// Log success message.
  void success(String message) => _logger.success(message);

  /// Log warning message.
  void warn(String message) => _logger.warn(message);

  /// Log error message.
  void error(String message) => _logger.err(message);

  /// Log debug message (only in verbose mode).
  void debug(String message) {
    if (isVerbose) {
      _logger.detail('[DEBUG] $message');
    }
  }

  /// Log verbose info (only in verbose mode).
  void verbose(String message) {
    if (isVerbose) {
      _logger.info(lightGray.wrap('  [VERBOSE] $message'));
    }
  }

  /// Log a file creation.
  void created(String path) => _logger.success('  + $path');

  /// Log a file skip.
  void skipped(String path) => _logger.info('  ○ $path (exists)');

  /// Log a would-be action (dry run).
  void would(String action) => _logger.info('  → $action');

  /// Log a deletion.
  void deleted(String path) => _logger.warn('  - $path');

  /// Start a progress indicator.
  Progress progress(String message) => _logger.progress(message);

  /// Prompt for confirmation.
  bool confirm(String message, {bool defaultValue = false}) {
    return _logger.confirm(message, defaultValue: defaultValue);
  }

  /// Prompt for input.
  String prompt(String message, {String? defaultValue}) {
    return _logger.prompt(message, defaultValue: defaultValue);
  }

  /// Choose from options.
  String chooseOne(
    String message, {
    required List<String> choices,
    String? defaultValue,
  }) {
    return _logger.chooseOne(
      message,
      choices: choices,
      defaultValue: defaultValue,
    );
  }

  /// Print a styled header.
  void header(String title) {
    _logger.info('');
    _logger.info(styleBold.wrap('═' * 60));
    _logger.info(styleBold.wrap('  $title'));
    _logger.info(styleBold.wrap('═' * 60));
    _logger.info('');
  }

  /// Print a divider.
  void divider() {
    _logger.info('');
    _logger.info('─' * 60);
    _logger.info('');
  }

  /// Print a section title.
  void section(String title) {
    _logger.info('');
    _logger.info(styleBold.wrap(title));
  }

  /// Flush output.
  void flush() => _logger.flush();
}
