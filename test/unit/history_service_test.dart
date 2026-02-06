import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('HistoryService', () {
    late Directory tempDir;
    late HistoryService historyService;
    late BackupService backupService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('history_service_test_');
      historyService = HistoryService();
      backupService = BackupService();

      // Create minimal project
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

    group('record', () {
      test('creates history file', () async {
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'add_feature',
          description: 'Added auth feature',
          filesAffected: ['lib/src/features/auth/'],
        );

        final historyFile = File(
          p.join(tempDir.path, '.flutter_scaffold', 'history.json'),
        );
        expect(historyFile.existsSync(), isTrue);
      });

      test('stores entry with correct fields', () async {
        final entry = await historyService.record(
          projectPath: tempDir.path,
          operation: 'scaffold:init',
          description: 'Initialized project scaffold',
          filesAffected: ['lib/src/app.dart', 'lib/src/routing/'],
        );

        expect(entry.id, isNotEmpty);
        expect(entry.operation, equals('scaffold:init'));
        expect(entry.description, equals('Initialized project scaffold'));
        expect(entry.filesAffected, hasLength(2));
        expect(entry.timestamp, isNotNull);
      });

      test('links backup id when provided', () async {
        // Create backup first
        Directory(p.join(tempDir.path, 'lib')).createSync();
        File(
          p.join(tempDir.path, 'lib', 'test.dart'),
        ).writeAsStringSync('content');

        final backupResult = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/test.dart'],
          operationName: 'pre_change',
        );

        // Record with backup id
        final entry = await historyService.record(
          projectPath: tempDir.path,
          operation: 'modify',
          description: 'Modified test.dart',
          filesAffected: ['lib/test.dart'],
          backupId: backupResult.backupId,
        );

        expect(entry.backupId, equals(backupResult.backupId));
      });

      test('appends to existing history', () async {
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'op1',
          description: 'First operation',
          filesAffected: [],
        );
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'op2',
          description: 'Second operation',
          filesAffected: [],
        );

        final history = historyService.getHistory(tempDir.path);
        expect(history, hasLength(2));
      });
    });

    group('getHistory', () {
      test('returns empty list for new project', () {
        final history = historyService.getHistory(tempDir.path);
        expect(history, isEmpty);
      });

      test('returns entries in reverse chronological order', () async {
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'first',
          description: 'First',
          filesAffected: [],
        );
        await Future.delayed(Duration(milliseconds: 10));
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'second',
          description: 'Second',
          filesAffected: [],
        );

        final history = historyService.getHistory(tempDir.path);
        expect(history.first.operation, equals('second'));
        expect(history.last.operation, equals('first'));
      });
    });

    group('revertTo', () {
      test('restores files from linked backup', () async {
        // Setup: create file and backup
        Directory(p.join(tempDir.path, 'lib')).createSync();
        final testFile = File(p.join(tempDir.path, 'lib', 'app.dart'));
        testFile.writeAsStringSync('original content');

        final backupResult = await backupService.backup(
          projectPath: tempDir.path,
          paths: ['lib/app.dart'],
          operationName: 'before_modify',
        );

        final entry = await historyService.record(
          projectPath: tempDir.path,
          operation: 'modify',
          description: 'Modified app.dart',
          filesAffected: ['lib/app.dart'],
          backupId: backupResult.backupId,
        );

        // Modify file
        testFile.writeAsStringSync('modified content');
        expect(testFile.readAsStringSync(), equals('modified content'));

        // Revert
        final success = await historyService.revertTo(tempDir.path, entry.id);

        expect(success, isTrue);
        expect(testFile.readAsStringSync(), equals('original content'));
      });

      test('fails for entry without backup', () async {
        final entry = await historyService.record(
          projectPath: tempDir.path,
          operation: 'test',
          description: 'Test without backup',
          filesAffected: [],
        );

        final success = await historyService.revertTo(tempDir.path, entry.id);

        expect(success, isFalse);
      });

      test('throws for non-existent entry', () async {
        expect(
          () => historyService.revertTo(tempDir.path, 'non_existent_id'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('clearHistory', () {
      test('removes all entries', () async {
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'op1',
          description: 'Op 1',
          filesAffected: [],
        );
        await historyService.record(
          projectPath: tempDir.path,
          operation: 'op2',
          description: 'Op 2',
          filesAffected: [],
        );

        await historyService.clearHistory(tempDir.path);

        final history = historyService.getHistory(tempDir.path);
        expect(history, isEmpty);
      });
    });
  });
}
