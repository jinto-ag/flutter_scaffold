import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:test/test.dart';

void main() {
  group('String utilities', () {
    test('toSnakeCase converts PascalCase', () {
      expect(toSnakeCase('MyFeature'), equals('my_feature'));
      expect(toSnakeCase('HomeScreen'), equals('home_screen'));
    });

    test('toSnakeCase handles spaces and hyphens', () {
      expect(toSnakeCase('my feature'), equals('my_feature'));
      expect(toSnakeCase('my-feature'), equals('my_feature'));
    });

    test('toPascalCase converts snake_case', () {
      expect(toPascalCase('my_feature'), equals('MyFeature'));
      expect(toPascalCase('home_screen'), equals('HomeScreen'));
    });

    test('toCamelCase converts snake_case', () {
      expect(toCamelCase('my_feature'), equals('myFeature'));
      expect(toCamelCase('home_screen'), equals('homeScreen'));
    });

    test('isValidIdentifier validates correctly', () {
      expect(isValidIdentifier('my_feature'), isTrue);
      expect(isValidIdentifier('auth'), isTrue);
      expect(isValidIdentifier('feature1'), isTrue);
      expect(isValidIdentifier('1feature'), isFalse);
      expect(isValidIdentifier('my-feature'), isFalse);
      expect(isValidIdentifier(''), isFalse);
    });

    test('normalizeFeatureName normalizes and validates', () {
      expect(normalizeFeatureName('MyFeature'), equals('my_feature'));
      expect(normalizeFeatureName('  auth  '), equals('auth'));
      expect(() => normalizeFeatureName(''), throwsArgumentError);
    });
  });

  group('Constants', () {
    test('version is 0.1.0', () {
      expect(version, equals('0.1.0'));
    });

    test('executable name is flutter_scaffold', () {
      expect(executableName, equals('flutter_scaffold'));
    });

    test('core directories are complete', () {
      expect(coreDirectories, isNotEmpty);
      expect(coreDirectories, contains('lib/src/core/errors'));
      expect(coreDirectories, contains('lib/src/core/theme'));
      expect(coreDirectories, contains('lib/src/routing'));
      expect(coreDirectories, contains('lib/src/features'));
    });

    test('core files are complete', () {
      expect(coreFiles, isNotEmpty);
      expect(coreFiles, contains('lib/src/app.dart'));
      expect(coreFiles, contains('lib/src/core/errors/exceptions.dart'));
      expect(coreFiles, contains('lib/src/routing/routes.dart'));
    });

    test('core dependencies are complete', () {
      expect(coreDependencies, isNotEmpty);
      expect(coreDependencies, contains('flutter_riverpod'));
      expect(coreDependencies, contains('go_router'));
      expect(coreDependencies, contains('freezed_annotation'));
    });

    test('dev dependencies are complete', () {
      expect(devDependencies, isNotEmpty);
      expect(devDependencies, contains('build_runner'));
      expect(devDependencies, contains('freezed'));
      expect(devDependencies, contains('riverpod_generator'));
    });

    test('feature directories are complete', () {
      expect(featureDirectories, isNotEmpty);
      expect(featureDirectories, contains('data/datasources'));
      expect(featureDirectories, contains('domain/entities'));
      expect(featureDirectories, contains('presentation/screens'));
    });
  });

  group('Errors', () {
    test('ProcessException stores message and exit code', () {
      final ex = ProcessException('Command failed', exitCode: 1);
      expect(ex.message, equals('Command failed'));
      expect(ex.exitCode, equals(1));
      expect(ex.toString(), contains('Command failed'));
      expect(ex.toString(), contains('1'));
    });

    test('FeatureException stores message', () {
      final ex = FeatureException('Feature already exists');
      expect(ex.message, equals('Feature already exists'));
      expect(ex.toString(), contains('Feature already exists'));
    });

    test('ProjectValidationException stores message', () {
      final ex = ProjectValidationException('Invalid project structure');
      expect(ex.message, equals('Invalid project structure'));
    });

    test('TemplateNotFoundException stores path', () {
      final ex = TemplateNotFoundException('core/missing.template');
      expect(ex.templatePath, equals('core/missing.template'));
      expect(ex.toString(), contains('core/missing.template'));
    });
  });
}
