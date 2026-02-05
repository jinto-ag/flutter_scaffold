library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('CLI End-to-End Tests', () {
    late Directory tempDir;
    late String cliPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cli_e2e_test_');
      cliPath = p.join(Directory.current.path, 'bin', 'flutter_scaffold.dart');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<ProcessResult> runCli(List<String> args) async {
      return Process.run('dart', [
        'run',
        cliPath,
        ...args,
      ], workingDirectory: Directory.current.path);
    }

    test('--version prints version', () async {
      final result = await runCli(['--version']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('flutter_scaffold version'));
      expect(result.stdout.toString(), contains('0.1.0'));
    });

    test('--help shows usage', () async {
      final result = await runCli(['--help']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('Available commands'));
      expect(result.stdout.toString(), contains('create'));
      expect(result.stdout.toString(), contains('scaffold'));
      expect(result.stdout.toString(), contains('add'));
      expect(result.stdout.toString(), contains('remove'));
      expect(result.stdout.toString(), contains('reset'));
      expect(result.stdout.toString(), contains('info'));
    });

    test('help create shows create command usage', () async {
      final result = await runCli(['help', 'create']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('new Flutter project'));
      expect(result.stdout.toString(), contains('--org'));
      expect(result.stdout.toString(), contains('--force'));
    });

    test('help add feature shows add feature usage', () async {
      final result = await runCli(['help', 'add']);
      expect(result.exitCode, equals(0));
      expect(result.stdout.toString(), contains('feature'));
    });

    test('scaffold command in non-flutter project fails gracefully', () async {
      final nonFlutterDir = Directory(p.join(tempDir.path, 'non_flutter'))
        ..createSync();

      final result = await Process.run('dart', [
        'run',
        cliPath,
        'scaffold',
      ], workingDirectory: nonFlutterDir.path);

      expect(result.exitCode, isNot(0));
      expect(
        result.stdout.toString().toLowerCase() +
            result.stderr.toString().toLowerCase(),
        anyOf(
          contains('not a flutter project'),
          contains('pubspec'),
          contains('error'),
        ),
      );
    });

    test('add feature with no name shows error', () async {
      final result = await runCli(['add', 'feature']);
      expect(result.exitCode, isNot(0));
      expect(
        result.stdout.toString().toLowerCase() +
            result.stderr.toString().toLowerCase(),
        contains('required'),
      );
    });

    test('info command in non-scaffold project shows message', () async {
      final nonScaffoldDir = Directory(p.join(tempDir.path, 'no_scaffold'))
        ..createSync();
      File(
        p.join(nonScaffoldDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: test');

      final result = await Process.run('dart', [
        'run',
        cliPath,
        'info',
      ], workingDirectory: nonScaffoldDir.path);

      expect(
        result.stdout.toString(),
        anyOf(
          contains('not found'),
          contains('No features'),
          contains('scaffold'),
        ),
      );
    });
  });

  group('Template Files E2E Validation', () {
    test('all template files are valid Dart syntax', () {
      final templatesDir = Directory(
        p.join(Directory.current.path, 'lib', 'src', 'templates'),
      );

      if (!templatesDir.existsSync()) {
        fail('Templates directory does not exist');
      }

      final templateFiles = templatesDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.template'));

      expect(templateFiles, isNotEmpty, reason: 'Should have template files');

      for (final file in templateFiles) {
        final content = file.readAsStringSync();
        expect(
          content,
          isNotEmpty,
          reason: '${p.basename(file.path)} should not be empty',
        );

        // Check for common Dart syntax elements (basic validation)
        if (file.path.contains('.dart.template')) {
          final hasClass = content.contains('class ');
          final hasImport = content.contains('import ');
          final hasConst = content.contains('const ');
          final hasAbstract = content.contains('abstract ');

          expect(
            hasClass || hasImport || hasConst || hasAbstract,
            isTrue,
            reason: '${p.basename(file.path)} should contain valid Dart syntax',
          );
        }
      }
    });

    test('feature templates have required placeholders', () {
      final featureDir = Directory(
        p.join(Directory.current.path, 'lib', 'src', 'templates', 'feature'),
      );

      if (!featureDir.existsSync()) {
        fail('Feature templates directory does not exist');
      }

      final templates = featureDir.listSync().whereType<File>();

      for (final file in templates) {
        final content = file.readAsStringSync();

        expect(
          content.contains('{{FEATURE_NAME}}') ||
              content.contains('{{PASCAL_NAME}}'),
          isTrue,
          reason: '${p.basename(file.path)} should have variable placeholders',
        );
      }
    });

    test(
      'core templates are standalone (no placeholders) except main.dart and app.dart',
      () {
        final coreDir = Directory(
          p.join(Directory.current.path, 'lib', 'src', 'templates', 'core'),
        );

        if (!coreDir.existsSync()) {
          fail('Core templates directory does not exist');
        }

        final templates = coreDir.listSync().whereType<File>();

        for (final file in templates) {
          final content = file.readAsStringSync();
          final basename = p.basename(file.path);

          // main.dart.template and app.dart.template are allowed to have {{projectName}}
          // for package import and app title
          if (basename == 'main.dart.template' ||
              basename == 'app.dart.template') {
            expect(
              content.contains('{{projectName}}'),
              isTrue,
              reason: '$basename should have {{projectName}} placeholder',
            );
          } else {
            expect(
              content.contains('{{'),
              isFalse,
              reason: '$basename should not have variable placeholders',
            );
          }
        }
      },
    );
  });
}
