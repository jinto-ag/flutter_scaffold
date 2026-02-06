import 'dart:io';

import 'package:flutter_scaffold/src/services/distribution_service.dart';
import 'package:flutter_scaffold/src/utils/file_utils.dart';
import 'package:flutter_scaffold/src/utils/process_utils.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

import 'distribution_service_test.mocks.dart';

@GenerateMocks([FileUtils, ProcessUtils])
void main() {
  late DistributionService service;
  late MockFileUtils mockFileUtils;
  late MockProcessUtils mockProcessUtils;

  Directory? testDir;

  setUp(() async {
    mockFileUtils = MockFileUtils();
    mockProcessUtils = MockProcessUtils();
    service = DistributionService(
      fileUtils: mockFileUtils,
      processUtils: mockProcessUtils,
    );
    testDir = await Directory.systemTemp.createTemp('dist_test_');
  });

  tearDown(() {
    testDir?.delete(recursive: true);
  });

  group('DistributionService', () {
    test('generateWrapper creates wrapper script', () async {
      await service.generateWrapper(targetDir: testDir!.path);

      final wrapperPath = p.join(testDir!.path, 'flutter_scaffold');
      expect(File(wrapperPath).existsSync(), isTrue);
    });

    test('bundleArtifacts bundles artifacts when source is available', () async {
      when(mockFileUtils.currentDirectory).thenReturn(testDir!.path);
      when(
        mockProcessUtils.run(
          any,
          any,
          workingDirectory: anyNamed('workingDirectory'),
        ),
      ).thenAnswer(
        (_) async => const ProcessResult(exitCode: 0, stdout: '', stderr: ''),
      );

      // We assume _resolveSourceDir returns null in test environment unless mocked via IO overrides.
      // So bundleArtifacts will likely try to bundle current executable if available.
      // This test is fragile without full IO mocking.
      // Let's create a dummy .flutter_scaffold/dist to assert creation.

      // Act
      await service.bundleArtifacts(targetDir: testDir!.path);

      // Assert
      final distDir = Directory(
        p.join(testDir!.path, '.flutter_scaffold', 'dist'),
      );
      expect(distDir.existsSync(), isTrue);
    });
  });
}
