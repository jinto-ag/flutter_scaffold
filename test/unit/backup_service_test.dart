import 'dart:convert';
import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('BackupService', () {
    late Directory tempDir;
    late BackupService backupService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('backup_service_test_');
      backupService = BackupService();

      // Create a minimal project structure
      File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('''
name: test_project
environment:
  sdk: ^3.0.0
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    group('backup', () {
      test('creates backup directory', () async {
        // Create a file to backup
        final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
        File(
          p.join(libDir.path, 'main.dart'),
        ).writeAsStringSync('void main() {}');

        final result = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/main.dart'],
          operationName: 'test_backup',
        );

        expect(result.backupId, isNotEmpty);
        expect(result.backupPath, isNotEmpty);

        // Check backup directory exists
        final backupsDir = Directory(
          p.join(tempDir.path, '.flutter_scaffold', 'backups'),
        );
        expect(backupsDir.existsSync(), isTrue);
      });

      test('stores file content correctly', () async {
        final content = 'original content';
        Directory(p.join(tempDir.path, 'lib')).createSync();
        File(
          p.join(tempDir.path, 'lib', 'test.dart'),
        ).writeAsStringSync(content);

        final result = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/test.dart'],
          operationName: 'test_backup',
        );

        expect(result.filesBackedUp, contains('lib/test.dart'));

        // Verify backed up content
        final backupDir = Directory(result.backupPath);
        final backedUpFile = File(p.join(backupDir.path, 'lib', 'test.dart'));
        expect(backedUpFile.existsSync(), isTrue);
        expect(backedUpFile.readAsStringSync(), equals(content));
      });

      test('creates backup index', () async {
        Directory(p.join(tempDir.path, 'lib')).createSync();
        File(
          p.join(tempDir.path, 'lib', 'app.dart'),
        ).writeAsStringSync('content');

        await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/app.dart'],
          operationName: 'test_operation',
        );

        final indexFile = File(
          p.join(tempDir.path, '.flutter_scaffold', 'backups', 'index.json'),
        );
        expect(indexFile.existsSync(), isTrue);

        final indexContent = jsonDecode(indexFile.readAsStringSync()) as List;
        expect(indexContent, isNotEmpty);
      });

      test('handles multiple files', () async {
        Directory(
          p.join(tempDir.path, 'lib', 'src'),
        ).createSync(recursive: true);
        File(p.join(tempDir.path, 'lib', 'a.dart')).writeAsStringSync('file a');
        File(
          p.join(tempDir.path, 'lib', 'src', 'b.dart'),
        ).writeAsStringSync('file b');

        final result = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/a.dart', 'lib/src/b.dart'],
          operationName: 'multi_file_backup',
        );

        expect(result.filesBackedUp, hasLength(2));
      });

      test('handles non-existent files gracefully', () async {
        // Should complete without error, just with 0 files backed up
        final result = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['non_existent.dart'],
          operationName: 'test_backup',
        );

        expect(result.filesBackedUp, isEmpty);
      });
    });

    group('restore', () {
      test('restores backed up files', () async {
        // Create original file
        Directory(p.join(tempDir.path, 'lib')).createSync();
        final originalFile = File(p.join(tempDir.path, 'lib', 'test.dart'));
        originalFile.writeAsStringSync('original');

        // Backup
        final backupResult = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/test.dart'],
          operationName: 'test_backup',
        );

        // Modify file
        originalFile.writeAsStringSync('modified');
        expect(originalFile.readAsStringSync(), equals('modified'));

        // Restore
        await backupService.restore(
          projectPath: tempDir.path,
          backupId: backupResult.backupId,
        );

        // Verify restored
        expect(originalFile.readAsStringSync(), equals('original'));
      });

      test('throws on invalid backup id', () async {
        expect(
          () => backupService.restore(
            projectPath: tempDir.path,
            backupId: 'invalid_id',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('listBackups', () {
      test('returns empty list when no backups', () {
        final backups = backupService.listBackups(tempDir.path);
        expect(backups, isEmpty);
      });

      test('returns all backups', () async {
        Directory(p.join(tempDir.path, 'lib')).createSync();
        File(
          p.join(tempDir.path, 'lib', 'test.dart'),
        ).writeAsStringSync('test');

        await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/test.dart'],
          operationName: 'backup1',
        );
        await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/test.dart'],
          operationName: 'backup2',
        );

        final backups = backupService.listBackups(tempDir.path);
        expect(backups, hasLength(2));
      });
    });

    group('cleanup', () {
      test('keeps only last 10 backups', () async {
        Directory(p.join(tempDir.path, 'lib')).createSync();
        File(
          p.join(tempDir.path, 'lib', 'test.dart'),
        ).writeAsStringSync('test');

        // Create 12 backups (limit is 10)
        for (var i = 0; i < 12; i++) {
          await backupService.backup(
            projectPath: tempDir.path,
            paths: ['lib/test.dart'],
            operationName: 'backup_$i',
          );
        }

        final backups = backupService.listBackups(tempDir.path);
        expect(backups.length, lessThanOrEqualTo(10));
      });
    });
  });
}
