import 'dart:io';

import 'package:flutter_scaffold/src/utils/templates.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

// Mock loader for unit testing logic without file system
class MockTemplateLoader extends TemplateLoader {
  MockTemplateLoader(this.templates);
  final Map<String, String> templates;

  @override
  String? loadTemplate(String relativePath) => templates[relativePath];

  @override
  String loadTemplateOrThrow(String relativePath) {
    if (templates.containsKey(relativePath)) return templates[relativePath]!;
    throw TemplateNotFoundException(relativePath);
  }
}

void main() {
  const coreFiles = [
    'lib/main.dart',
    'lib/src/app.dart',
    'lib/src/core/errors/exceptions.dart',
    'lib/src/core/errors/failures.dart',
    'lib/src/core/theme/app_theme.dart',
    'lib/src/routing/routes.dart',
  ];

  group('TemplateLoader Logic (Conditional Tokens)', () {
    test('Basic if condition (true)', () {
      final templates = {
        'test.template': '''
Start
{{if show}}
Shown
{{endif}}
End''',
      };

      final loader = MockTemplateLoader(templates);
      final result = loader.loadAndApplyTemplate('test.template', {
        'show': true,
      });

      expect(result, 'Start\nShown\nEnd');
    });

    test('Basic if condition (false)', () {
      final templates = {
        'test.template': '''
Start
{{if show}}
Shown
{{endif}}
End''',
      };

      final loader = MockTemplateLoader(templates);
      final result = loader.loadAndApplyTemplate('test.template', {
        'show': false,
      });

      expect(result, 'Start\nEnd');
    });

    test('If-Else condition (true)', () {
      final templates = {
        'test.template': '''
{{if show}}
True
{{else}}
False
{{endif}}''',
      };

      final loader = MockTemplateLoader(templates);
      final result = loader.loadAndApplyTemplate('test.template', {
        'show': true,
      });

      expect(result, 'True');
    });

    test('If-Else condition (false)', () {
      final templates = {
        'test.template': '''
{{if show}}
True
{{else}}
False
{{endif}}''',
      };

      final loader = MockTemplateLoader(templates);
      final result = loader.loadAndApplyTemplate('test.template', {
        'show': false,
      });

      expect(result, 'False');
    });

    test('If-ElseIf-Else chain', () {
      final templates = {
        'test.template': '''
{{if cond1}}
One
{{else if cond2}}
Two
{{else}}
Three
{{endif}}''',
      };

      final loader = MockTemplateLoader(templates);

      // Case 1
      expect(
        loader.loadAndApplyTemplate('test.template', {
          'cond1': true,
          'cond2': false,
        }),
        'One',
      );

      // Case 2
      expect(
        loader.loadAndApplyTemplate('test.template', {
          'cond1': false,
          'cond2': true,
        }),
        'Two',
      );

      // Case 3
      expect(
        loader.loadAndApplyTemplate('test.template', {
          'cond1': false,
          'cond2': false,
        }),
        'Three',
      );
    });

    test('Nested conditions', () {
      final templates = {
        'test.template': '''
{{if outer}}
Outer
{{if inner}}
Inner
{{endif}}
{{endif}}''',
      };

      final loader = MockTemplateLoader(templates);

      expect(
        loader.loadAndApplyTemplate('test.template', {
          'outer': true,
          'inner': true,
        }),
        'Outer\nInner',
      );

      expect(
        loader.loadAndApplyTemplate('test.template', {
          'outer': true,
          'inner': false,
        }),
        'Outer',
      );

      expect(
        loader.loadAndApplyTemplate('test.template', {
          'outer': false,
          'inner': true,
        }),
        '', // Inner ignored because outer is false
      );
    });

    test('Variable substitution with logic', () {
      final templates = {
        'test.template': '''
{{if show}}
Hello {{name}}
{{endif}}''',
      };

      final loader = MockTemplateLoader(templates);
      final result = loader.loadAndApplyTemplate('test.template', {
        'show': true,
        'name': 'World',
      });

      expect(result, 'Hello World');
    });

    test('Whitespace handling', () {
      final templates = {
        'test.template': '''
  {{ if show }}  
    Shown
  {{ endif }}  ''',
      };

      final loader = MockTemplateLoader(templates);
      final result = loader.loadAndApplyTemplate('test.template', {
        'show': true,
      });

      // The implementation preserves content lines indentation but logic lines are removed.
      expect(result, '    Shown');
    });
  });

  // Original Integration Tests
  group('TemplateLoader integration', () {
    late TemplateLoader loader;
    late String templatesPath;

    setUpAll(() {
      templatesPath = p.join(Directory.current.path, 'lib', 'src', 'templates');
      loader = TemplateLoader(templatesPath: templatesPath);
    });

    test('getTemplatesDirectory returns valid path', () {
      final dir = loader.getTemplatesDirectory();
      expect(Directory(dir).existsSync(), isTrue);
    });

    test('loadTemplate returns content for existing core template', () {
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
