import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ScaffoldService Integration', () {
    late Directory tempDir;
    late ScaffoldService scaffoldService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('scaffold_service_test_');
      scaffoldService = ScaffoldService();

      // Create a minimal Flutter project structure
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

    test('createScaffold creates all core directories', () {
      scaffoldService.createScaffold(projectPath: tempDir.path);

      for (final dir in coreDirectories) {
        final fullPath = p.join(tempDir.path, dir);
        expect(
          Directory(fullPath).existsSync(),
          isTrue,
          reason: 'Directory $dir should exist',
        );
      }
    });

    test('createScaffold creates all core files', () {
      scaffoldService.createScaffold(projectPath: tempDir.path);

      for (final file in coreFiles) {
        final fullPath = p.join(tempDir.path, file);
        expect(
          File(fullPath).existsSync(),
          isTrue,
          reason: 'File $file should exist',
        );
      }
    });

    test('createScaffold does not overwrite existing files without force', () {
      final appPath = p.join(tempDir.path, 'lib', 'src', 'app.dart');
      Directory(p.dirname(appPath)).createSync(recursive: true);
      File(appPath).writeAsStringSync('// Existing content');

      final result = scaffoldService.createScaffold(
        projectPath: tempDir.path,
        force: false,
      );

      expect(File(appPath).readAsStringSync(), equals('// Existing content'));
      expect(result.filesSkipped, greaterThan(0));
    });

    test('createScaffold overwrites with force', () {
      final appPath = p.join(tempDir.path, 'lib', 'src', 'app.dart');
      Directory(p.dirname(appPath)).createSync(recursive: true);
      File(appPath).writeAsStringSync('// Old content');

      scaffoldService.createScaffold(projectPath: tempDir.path, force: true);

      expect(File(appPath).readAsStringSync(), contains('MaterialApp'));
    });

    test('verifyScaffold returns true when all files exist', () {
      scaffoldService.createScaffold(projectPath: tempDir.path);
      final valid = scaffoldService.verifyScaffold(projectPath: tempDir.path);
      expect(valid, isTrue);
    });

    test('verifyScaffold returns false when files missing', () {
      // Don't create scaffold, just check
      final valid = scaffoldService.verifyScaffold(projectPath: tempDir.path);
      expect(valid, isFalse);
    });

    test('resetScaffold removes src directory', () {
      // Create scaffold first
      scaffoldService.createScaffold(projectPath: tempDir.path);
      final srcPath = p.join(tempDir.path, 'lib', 'src');
      expect(Directory(srcPath).existsSync(), isTrue);

      // Reset it
      scaffoldService.resetScaffold(projectPath: tempDir.path);
      expect(Directory(srcPath).existsSync(), isFalse);
    });
  });

  group('FeatureService Integration', () {
    late Directory tempDir;
    late FeatureService featureService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('feature_service_test_');
      featureService = FeatureService();

      // Create minimal project structure
      File(
        p.join(tempDir.path, 'pubspec.yaml'),
      ).writeAsStringSync('name: test');
      Directory(
        p.join(tempDir.path, 'lib', 'src', 'features'),
      ).createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('addFeature creates feature structure', () {
      featureService.addFeature(projectPath: tempDir.path, featureName: 'auth');

      final featurePath = p.join(
        tempDir.path,
        'lib',
        'src',
        'features',
        'auth',
      );
      expect(Directory(featurePath).existsSync(), isTrue);

      // Check directories
      expect(
        Directory(p.join(featurePath, 'data', 'datasources')).existsSync(),
        isTrue,
      );
      expect(
        Directory(p.join(featurePath, 'domain', 'entities')).existsSync(),
        isTrue,
      );
      expect(
        Directory(p.join(featurePath, 'presentation', 'screens')).existsSync(),
        isTrue,
      );
    });

    test('addFeature creates feature files', () {
      featureService.addFeature(projectPath: tempDir.path, featureName: 'user');

      final featurePath = p.join(
        tempDir.path,
        'lib',
        'src',
        'features',
        'user',
      );

      expect(
        File(
          p.join(featurePath, 'presentation', 'screens', 'user_screen.dart'),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(featurePath, 'domain', 'entities', 'user_entity.dart'),
        ).existsSync(),
        isTrue,
      );
    });

    test('addFeature normalizes feature name', () {
      featureService.addFeature(
        projectPath: tempDir.path,
        featureName: 'MyFeature',
      );

      final featurePath = p.join(
        tempDir.path,
        'lib',
        'src',
        'features',
        'my_feature',
      );
      expect(Directory(featurePath).existsSync(), isTrue);
    });

    test('addFeature throws if feature exists without force', () {
      featureService.addFeature(
        projectPath: tempDir.path,
        featureName: 'existing',
      );

      expect(
        () => featureService.addFeature(
          projectPath: tempDir.path,
          featureName: 'existing',
          force: false,
        ),
        throwsA(isA<FeatureException>()),
      );
    });

    test('listFeatures returns all features', () {
      featureService.addFeature(projectPath: tempDir.path, featureName: 'auth');
      featureService.addFeature(projectPath: tempDir.path, featureName: 'home');

      final features = featureService.listFeatures(tempDir.path);
      expect(features, hasLength(2));
      expect(features, contains('auth'));
      expect(features, contains('home'));
    });

    test('removeFeature deletes feature directory', () {
      featureService.addFeature(projectPath: tempDir.path, featureName: 'temp');
      final featurePath = p.join(
        tempDir.path,
        'lib',
        'src',
        'features',
        'temp',
      );
      expect(Directory(featurePath).existsSync(), isTrue);

      featureService.removeFeature(
        projectPath: tempDir.path,
        featureName: 'temp',
      );
      expect(Directory(featurePath).existsSync(), isFalse);
    });

    test('getFeatureInfo returns correct information', () {
      featureService.addFeature(projectPath: tempDir.path, featureName: 'info');

      final info = featureService.getFeatureInfo(tempDir.path, 'info');
      expect(info.name, equals('info'));
      expect(info.fileCount, greaterThan(0));
      expect(info.dirCount, greaterThan(0));
      expect(info.components, contains('screen'));
      expect(info.components, contains('entity'));
    });
  });
}
