import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('FileUtils', () {
    late Directory tempDir;
    late FileUtils fileUtils;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('file_utils_test_');
      fileUtils = const FileUtils();
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('joinPath joins paths correctly', () {
      final result = fileUtils.joinPath('/home', 'user', 'project');
      expect(result, contains('home'));
      expect(result, contains('user'));
      expect(result, contains('project'));
    });

    test('createDirectory creates nested directories', () {
      final path = p.join(tempDir.path, 'a', 'b', 'c');
      final created = fileUtils.createDirectory(path);

      expect(created, isTrue);
      expect(Directory(path).existsSync(), isTrue);
    });

    test('createFile creates file with content', () {
      final path = p.join(tempDir.path, 'test.txt');
      final created = fileUtils.createFile(path, 'Hello, World!');

      expect(created, isTrue);
      expect(File(path).existsSync(), isTrue);
      expect(File(path).readAsStringSync(), equals('Hello, World!'));
    });

    test('createFile does not overwrite without force', () {
      final path = p.join(tempDir.path, 'existing.txt');
      File(path).writeAsStringSync('Original');

      final created = fileUtils.createFile(path, 'New content', force: false);

      expect(created, isFalse);
      expect(File(path).readAsStringSync(), equals('Original'));
    });

    test('createFile overwrites with force', () {
      final path = p.join(tempDir.path, 'existing.txt');
      File(path).writeAsStringSync('Original');

      final created = fileUtils.createFile(path, 'New content', force: true);

      expect(created, isTrue);
      expect(File(path).readAsStringSync(), equals('New content'));
    });

    test('fileExists returns correct status', () {
      final path = p.join(tempDir.path, 'exists.txt');
      expect(fileUtils.fileExists(path), isFalse);

      File(path).writeAsStringSync('content');
      expect(fileUtils.fileExists(path), isTrue);
    });

    test('directoryExists returns correct status', () {
      final path = p.join(tempDir.path, 'subdir');
      expect(fileUtils.directoryExists(path), isFalse);

      Directory(path).createSync();
      expect(fileUtils.directoryExists(path), isTrue);
    });

    test('deleteDirectory removes recursively', () {
      final path = p.join(tempDir.path, 'to_delete');
      Directory(path).createSync();
      File(p.join(path, 'file.txt')).writeAsStringSync('content');

      fileUtils.deleteDirectory(path);
      expect(Directory(path).existsSync(), isFalse);
    });

    test('listSubdirectories returns only directories', () {
      final subdir1 = p.join(tempDir.path, 'dir1');
      final subdir2 = p.join(tempDir.path, 'dir2');
      Directory(subdir1).createSync();
      Directory(subdir2).createSync();
      File(p.join(tempDir.path, 'file.txt')).writeAsStringSync('content');

      final subdirs = fileUtils.listSubdirectories(tempDir.path);
      expect(subdirs, hasLength(2));
      expect(subdirs, contains('dir1'));
      expect(subdirs, contains('dir2'));
    });

    test('countFiles counts files recursively', () {
      Directory(p.join(tempDir.path, 'sub')).createSync();
      File(p.join(tempDir.path, 'file1.txt')).writeAsStringSync('1');
      File(p.join(tempDir.path, 'file2.txt')).writeAsStringSync('2');
      File(p.join(tempDir.path, 'sub', 'file3.txt')).writeAsStringSync('3');

      final count = fileUtils.countFiles(tempDir.path);
      expect(count, equals(3));
    });

    test('isFlutterProject detects pubspec.yaml', () {
      expect(fileUtils.isFlutterProject(tempDir.path), isFalse);

      File(
        p.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: test');
      expect(fileUtils.isFlutterProject(tempDir.path), isTrue);
    });
  });
}
