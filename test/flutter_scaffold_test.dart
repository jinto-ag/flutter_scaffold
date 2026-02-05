import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:test/test.dart';

void main() {
  group('String utilities', () {
    test('toSnakeCase converts PascalCase', () {
      expect(toSnakeCase('MyFeature'), equals('my_feature'));
      expect(toSnakeCase('HomeScreen'), equals('home_screen'));
      expect(toSnakeCase('HTTPServer'), equals('h_t_t_p_server'));
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
      expect(isValidIdentifier('MyFeature'), isFalse);
      expect(isValidIdentifier(''), isFalse);
    });

    test('normalizeFeatureName normalizes and validates', () {
      expect(normalizeFeatureName('MyFeature'), equals('my_feature'));
      expect(normalizeFeatureName('  auth  '), equals('auth'));
      expect(() => normalizeFeatureName(''), throwsArgumentError);
    });
  });

  group('Templates', () {
    test('TemplateRegistry returns core templates', () {
      const registry = TemplateRegistry();

      final appTemplate = registry.getTemplate('lib/src/app.dart');
      expect(appTemplate, isNotNull);
      expect(appTemplate, contains('MaterialApp.router'));

      final routesTemplate = registry.getTemplate(
        'lib/src/routing/routes.dart',
      );
      expect(routesTemplate, isNotNull);
      expect(routesTemplate, contains('class Routes'));
    });

    test('TemplateRegistry returns feature templates', () {
      const registry = TemplateRegistry();

      final screenTemplate = registry.getFeatureTemplate('screen', 'auth');
      expect(screenTemplate, isNotNull);
      expect(screenTemplate, contains('AuthScreen'));

      final entityTemplate = registry.getFeatureTemplate('entity', 'user');
      expect(entityTemplate, isNotNull);
      expect(entityTemplate, contains('UserEntity'));
    });
  });

  group('Constants', () {
    test('version is defined', () {
      expect(version, equals('0.1.0'));
    });

    test('core directories are defined', () {
      expect(coreDirectories, isNotEmpty);
      expect(coreDirectories, contains('lib/src/core/errors'));
    });

    test('core files are defined', () {
      expect(coreFiles, isNotEmpty);
      expect(coreFiles, contains('lib/src/app.dart'));
    });
  });
}
