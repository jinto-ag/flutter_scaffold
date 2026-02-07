/// Logging utilities for tests.
///
/// Provides consistent colored output and logging for test scripts.
library;

import 'dart:io';

/// ANSI color codes for terminal output.
class AnsiColors {
  static const String reset = '\x1B[0m';
  static const String red = '\x1B[31m';
  static const String green = '\x1B[32m';
  static const String yellow = '\x1B[33m';
  static const String blue = '\x1B[34m';
  static const String magenta = '\x1B[35m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String gray = '\x1B[90m';

  /// Bold variants
  static const String boldRed = '\x1B[1;31m';
  static const String boldGreen = '\x1B[1;32m';
  static const String boldYellow = '\x1B[1;33m';
  static const String boldBlue = '\x1B[1;34m';
  static const String boldCyan = '\x1B[1;36m';
}

/// Test logger with colored output and verbosity control.
class TestLogger {
  final bool verbose;
  final File? logFile;
  final StringBuffer _buffer = StringBuffer();

  TestLogger({this.verbose = false, this.logFile});

  /// Log an informational message.
  void info(String message) {
    _log(message);
  }

  /// Log a success message.
  void success(String message) {
    _log('${AnsiColors.green}✓ $message${AnsiColors.reset}');
  }

  /// Log an error message.
  void error(String message) {
    _log('${AnsiColors.red}✗ $message${AnsiColors.reset}');
  }

  /// Log a warning message.
  void warn(String message) {
    _log('${AnsiColors.yellow}⚠ $message${AnsiColors.reset}');
  }

  /// Log a debug message (only visible in verbose mode).
  void debug(String message) {
    if (verbose) {
      _log('${AnsiColors.gray}  $message${AnsiColors.reset}');
    }
    _buffer.writeln('[DEBUG] $message');
  }

  /// Log a step start.
  void stepStart(String stepName) {
    stdout.write('${AnsiColors.cyan}[STEP] $stepName... ${AnsiColors.reset}');
  }

  /// Log a step completion.
  void stepComplete() {
    print('${AnsiColors.green}✓${AnsiColors.reset}');
  }

  /// Log a step failure.
  void stepFailed() {
    print('${AnsiColors.red}✗${AnsiColors.reset}');
  }

  /// Print a header block.
  void header(String title) {
    final line = '═' * 60;
    print('\n${AnsiColors.blue}$line${AnsiColors.reset}');
    print('${AnsiColors.blue}  $title${AnsiColors.reset}');
    print('${AnsiColors.blue}$line${AnsiColors.reset}\n');
  }

  /// Print a section divider.
  void section(String title) {
    print('\n${AnsiColors.boldCyan}── $title ──${AnsiColors.reset}\n');
  }

  void _log(String message) {
    print(message);
    _buffer.writeln(message.replaceAll(RegExp(r'\x1B\[[0-9;]+m'), ''));
  }

  /// Flush buffer to log file.
  void flush() {
    if (logFile != null) {
      logFile!.writeAsStringSync(
        '${DateTime.now().toIso8601String()}\n${_buffer.toString()}\n',
        mode: FileMode.append,
      );
      _buffer.clear();
    }
  }
}
