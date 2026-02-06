import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SandboxService', () {
    late Directory tempDir;
    late SandboxService sandboxService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sandbox_service_test_');
      sandboxService = SandboxService();

      // Create minimal project structure
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.0.0
''');
      Directory(p.join(tempDir.path, 'lib')).createSync();
      File(p.join(tempDir.path, 'lib', 'main.dart')).writeAsStringSync('''
void main() {
  print('Hello');
}
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('createSandbox', () {
      test('creates sandbox directory', () async {
        final sandboxPath = await sandboxService.createSandbox(tempDir.path);

        expect(Directory(sandboxPath).existsSync(), isTrue);
        expect(sandboxPath, isNot(equals(tempDir.path)));

        // Cleanup
        sandboxService.cleanup(sandboxPath);
      });

      test('copies project files to sandbox', () async {
        final sandboxPath = await sandboxService.createSandbox(tempDir.path);

        expect(File(p.join(sandboxPath, 'pubspec.yaml')).existsSync(), isTrue);
        expect(
          File(p.join(sandboxPath, 'lib', 'main.dart')).existsSync(),
          isTrue,
        );

        // Cleanup
        sandboxService.cleanup(sandboxPath);
      });
    });

    group('executeWithVerification', () {
      test('executes operation in sandbox', () async {
        var operationExecuted = false;

        await sandboxService.executeWithVerification(
          projectPath: tempDir.path,
          operation: (sandboxPath) async {
            operationExecuted = true;
            // Create new file in sandbox
            File(
              p.join(sandboxPath, 'lib', 'new_file.dart'),
            ).writeAsStringSync('new content');
          },
          verifySuccess: (sandboxPath) async {
            return File(
              p.join(sandboxPath, 'lib', 'new_file.dart'),
            ).existsSync();
          },
          applyOnSuccess: false,
        );

        expect(operationExecuted, isTrue);

        // Original should not be affected when applyOnSuccess is false
        expect(
          File(p.join(tempDir.path, 'lib', 'new_file.dart')).existsSync(),
          isFalse,
        );
      });

      test('applies changes on success when applyOnSuccess is true', () async {
        final result = await sandboxService.executeWithVerification(
          projectPath: tempDir.path,
          operation: (sandboxPath) async {
            File(
              p.join(sandboxPath, 'lib', 'applied.dart'),
            ).writeAsStringSync('applied content');
          },
          verifySuccess: (path) async => true,
          applyOnSuccess: true,
        );

        expect(result, isA<SandboxSuccess>());
        expect(
          File(p.join(tempDir.path, 'lib', 'applied.dart')).existsSync(),
          isTrue,
        );
        expect(
          File(p.join(tempDir.path, 'lib', 'applied.dart')).readAsStringSync(),
          equals('applied content'),
        );
      });

      test('returns failure when verification fails', () async {
        final result = await sandboxService.executeWithVerification(
          projectPath: tempDir.path,
          operation: (sandboxPath) async {
            File(
              p.join(sandboxPath, 'lib', 'should_not_apply.dart'),
            ).writeAsStringSync('content');
          },
          verifySuccess: (path) async => false, // Verification fails
          applyOnSuccess: true,
        );

        expect(result, isA<SandboxFailure>());
        expect(
          File(
            p.join(tempDir.path, 'lib', 'should_not_apply.dart'),
          ).existsSync(),
          isFalse,
        );
      });

      test('preserves original files on failure', () async {
        final originalContent = File(
          p.join(tempDir.path, 'lib', 'main.dart'),
        ).readAsStringSync();

        await sandboxService.executeWithVerification(
          projectPath: tempDir.path,
          operation: (sandboxPath) async {
            // Modify in sandbox
            File(
              p.join(sandboxPath, 'lib', 'main.dart'),
            ).writeAsStringSync('modified');
          },
          verifySuccess: (path) async => false, // Verification fails
          applyOnSuccess: true,
        );

        // Original unchanged
        expect(
          File(p.join(tempDir.path, 'lib', 'main.dart')).readAsStringSync(),
          equals(originalContent),
        );
      });
    });

    group('cleanup', () {
      test('removes sandbox directory', () async {
        final sandboxPath = await sandboxService.createSandbox(tempDir.path);
        expect(Directory(sandboxPath).existsSync(), isTrue);

        sandboxService.cleanup(sandboxPath);
        expect(Directory(sandboxPath).existsSync(), isFalse);
      });
    });

    group('verifyWithFlutterAnalyze', () {
      test('handles analyze failures gracefully', () async {
        // Create a sandbox with invalid Dart code
        final sandboxPath = await sandboxService.createSandbox(tempDir.path);
        File(
          p.join(sandboxPath, 'lib', 'broken.dart'),
        ).writeAsStringSync('invalid dart code {{');

        // This should not throw, just return false
        final result = await sandboxService.verifyWithFlutterAnalyze(
          sandboxPath,
        );
        // Result depends on environment, just ensure no exception
        expect(result, isA<bool>());

        sandboxService.cleanup(sandboxPath);
      });
    });
  });
}
