import 'dart:io';

import 'package:flutter_scaffold/flutter_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('TemplateLoader', () {
    late TemplateLoader loader;
    late String templatesPath;

    setUpAll(() {
      // Use the actual templates directory from the package
      templatesPath = p.join(Directory.current.path, 'lib', 'src', 'templates');

      // Verify templates directory exists for these tests
      if (!Directory(templatesPath).existsSync()) {
        fail('Templates directory not found at: $templatesPath');
      }

      loader = TemplateLoader(templatesPath: templatesPath);
    });

    test('getTemplatesDirectory returns correct path', () {
      final dir = loader.getTemplatesDirectory();
      expect(dir, equals(templatesPath));
      expect(Directory(dir).existsSync(), isTrue);
    });

    test('loadTemplate returns content for existing core templates', () {
      final content = loader.loadTemplate('core/app.dart.template');
      expect(content, isNotNull);
      expect(content, isNotEmpty);
      expect(content, contains('MaterialApp'));
    });

    test('loadTemplate returns content for existing feature templates', () {
      final content = loader.loadTemplate('feature/screen.dart.template');
      expect(content, isNotNull);
      expect(content, isNotEmpty);
      expect(content, contains('{{PASCAL_NAME}}'));
    });

    test('loadTemplate returns null for missing template', () {
      final content = loader.loadTemplate('nonexistent/file.template');
      expect(content, isNull);
    });

    test('loadTemplateOrThrow throws for missing template', () {
      expect(
        () => loader.loadTemplateOrThrow('nonexistent/file.template'),
        throwsA(isA<TemplateNotFoundException>()),
      );
    });

    test('loadAndApplyTemplate substitutes variables correctly', () {
      final content = loader.loadAndApplyTemplate(
        'feature/screen.dart.template',
        {'FEATURE_NAME': 'auth', 'PASCAL_NAME': 'Auth'},
      );

      expect(content, isNotNull);
      expect(content, contains('AuthScreen'));
      expect(content, isNot(contains('{{FEATURE_NAME}}')));
      expect(content, isNot(contains('{{PASCAL_NAME}}')));
    });

    test('listTemplates returns template files in directory', () {
      final coreTemplates = loader.listTemplates('core');
      expect(coreTemplates, isNotEmpty);
      expect(coreTemplates, contains('app.dart.template'));
      expect(coreTemplates, contains('exceptions.dart.template'));
    });

    test('listTemplates returns empty for non-existent directory', () {
      final templates = loader.listTemplates('nonexistent');
      expect(templates, isEmpty);
    });

    test('validateTemplatesExist returns true when templates present', () {
      expect(loader.validateTemplatesExist(), isTrue);
    });
  });

  group('TemplateRegistry', () {
    late TemplateRegistry registry;
    late String templatesPath;

    setUpAll(() {
      templatesPath = p.join(Directory.current.path, 'lib', 'src', 'templates');
      final loader = TemplateLoader(templatesPath: templatesPath);
      registry = TemplateRegistry(loader: loader);
    });

    group('Core Templates', () {
      test('getTemplate returns content for all core files', () {
        for (final file in coreFiles) {
          final template = registry.getTemplate(file);
          expect(
            template,
            isNotNull,
            reason: 'Template for $file should not be null',
          );
          expect(
            template,
            isNotEmpty,
            reason: 'Template for $file should not be empty',
          );
        }
      });

      test('getTemplate returns null for unknown path', () {
        final template = registry.getTemplate('unknown/path.dart');
        expect(template, isNull);
      });

      test('getTemplateOrThrow throws for unknown path', () {
        expect(
          () => registry.getTemplateOrThrow('unknown/path.dart'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });

      test('app.dart template has correct content', () {
        final template = registry.getTemplate('lib/src/app.dart');
        expect(template, contains('MaterialApp.router'));
        expect(template, contains('ConsumerWidget'));
        expect(template, contains('AppTheme'));
      });

      test('exceptions.dart template has correct content', () {
        final template = registry.getTemplate(
          'lib/src/core/errors/exceptions.dart',
        );
        expect(template, contains('AppException'));
        expect(template, contains('ServerException'));
        expect(template, contains('CacheException'));
        expect(template, contains('NetworkException'));
      });

      test('failures.dart template has correct content', () {
        final template = registry.getTemplate(
          'lib/src/core/errors/failures.dart',
        );
        expect(template, contains('Failure'));
        expect(template, contains('ServerFailure'));
        expect(template, contains('NetworkFailure'));
      });

      test('app_theme.dart template has light and dark themes', () {
        final template = registry.getTemplate(
          'lib/src/core/theme/app_theme.dart',
        );
        expect(template, contains('static ThemeData get light'));
        expect(template, contains('static ThemeData get dark'));
        expect(template, contains('useMaterial3: true'));
      });

      test('routes.dart template has route definitions', () {
        final template = registry.getTemplate('lib/src/routing/routes.dart');
        expect(template, contains('class Routes'));
        expect(template, contains('homeName'));
        expect(template, contains("static const String home = '/'"));
      });
    });

    group('Feature Templates', () {
      test('getFeatureTemplate returns screen with substitution', () {
        final template = registry.getFeatureTemplate('screen', 'auth');
        expect(template, isNotNull);
        expect(template, contains('AuthScreen'));
        expect(template, contains('ConsumerWidget'));
        expect(template, isNot(contains('{{PASCAL_NAME}}')));
      });

      test('getFeatureTemplate returns providers with substitution', () {
        final template = registry.getFeatureTemplate('providers', 'user');
        expect(template, isNotNull);
        expect(template, contains('UserNotifier'));
        expect(template, contains("part 'user_providers.g.dart'"));
        expect(template, isNot(contains('{{FEATURE_NAME}}')));
      });

      test('getFeatureTemplate returns entity with Freezed', () {
        final template = registry.getFeatureTemplate('entity', 'product');
        expect(template, isNotNull);
        expect(template, contains('ProductEntity'));
        expect(template, contains('@freezed'));
        expect(template, contains("part 'product_entity.freezed.dart'"));
      });

      test('getFeatureTemplate returns repository interface', () {
        final template = registry.getFeatureTemplate('repository', 'order');
        expect(template, isNotNull);
        expect(template, contains('OrderRepository'));
        expect(template, contains('OrderEntity'));
        expect(template, contains('Future<OrderEntity?>'));
      });

      test('getFeatureTemplate handles snake_case names', () {
        final template = registry.getFeatureTemplate('screen', 'user_profile');
        expect(template, isNotNull);
        expect(template, contains('UserProfileScreen'));
      });

      test('getFeatureTemplate returns null for unknown type', () {
        final template = registry.getFeatureTemplate('unknown', 'feature');
        expect(template, isNull);
      });

      test('getFeatureTemplateOrThrow throws for unknown type', () {
        expect(
          () => registry.getFeatureTemplateOrThrow('unknown', 'feature'),
          throwsA(isA<TemplateNotFoundException>()),
        );
      });
    });

    group('Validation', () {
      test('validateAllTemplatesExist returns true', () {
        expect(registry.validateAllTemplatesExist(), isTrue);
      });

      test('allOutputPaths contains expected paths', () {
        final paths = registry.allOutputPaths;
        expect(paths, contains('lib/src/app.dart'));
        expect(paths, contains('lib/src/routing/routes.dart'));
        expect(paths, contains('lib/src/core/theme/app_theme.dart'));
      });

      test('featureTemplateTypes contains expected types', () {
        expect(TemplateRegistry.featureTemplateTypes, contains('screen'));
        expect(TemplateRegistry.featureTemplateTypes, contains('entity'));
        expect(TemplateRegistry.featureTemplateTypes, contains('repository'));
        expect(TemplateRegistry.featureTemplateTypes, contains('providers'));
      });
    });
  });

  group('TemplateNotFoundException', () {
    test('stores template path', () {
      final ex = TemplateNotFoundException('path/to/template');
      expect(ex.templatePath, equals('path/to/template'));
    });

    test('toString includes path', () {
      final ex = TemplateNotFoundException('missing.template');
      expect(ex.toString(), contains('missing.template'));
    });
  });
}
