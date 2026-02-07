import 'package:flutter_scaffold/src/commands/add_usecase_command.dart';
import 'package:flutter_scaffold/src/commands/add_repository_command.dart';
import 'package:test/test.dart';

void main() {
  group('AddUsecaseCommand', () {
    late AddUsecaseCommand command;

    setUp(() {
      command = AddUsecaseCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('usecase'));
    });

    test('has correct description', () {
      expect(command.description, equals('Add a new use case to a feature'));
    });

    test('has required feature option', () {
      final option = command.argParser.options['feature'];
      expect(option, isNotNull);
      expect(option!.mandatory, isTrue);
      expect(option.abbr, equals('f'));
    });

    test('has with-params flag', () {
      final flag = command.argParser.options['with-params'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has return-type option with default', () {
      final option = command.argParser.options['return-type'];
      expect(option, isNotNull);
      expect(option!.defaultsTo, equals('void'));
    });

    test('has description option', () {
      final option = command.argParser.options['description'];
      expect(option, isNotNull);
      expect(option!.abbr, equals('d'));
    });

    test('has force flag', () {
      final flag = command.argParser.options['force'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has dry-run flag', () {
      final flag = command.argParser.options['dry-run'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });
  });

  group('AddRepositoryCommand', () {
    late AddRepositoryCommand command;

    setUp(() {
      command = AddRepositoryCommand();
    });

    test('has correct name', () {
      expect(command.name, equals('repository'));
    });

    test('has correct description', () {
      expect(
        command.description,
        equals('Add a repository with optional datasources to a feature'),
      );
    });

    test('has required feature option', () {
      final option = command.argParser.options['feature'];
      expect(option, isNotNull);
      expect(option!.mandatory, isTrue);
      expect(option.abbr, equals('f'));
    });

    test('has include-datasources flag', () {
      final flag = command.argParser.options['include-datasources'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has remote-only flag', () {
      final flag = command.argParser.options['remote-only'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has local-only flag', () {
      final flag = command.argParser.options['local-only'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has include-mapper flag', () {
      final flag = command.argParser.options['include-mapper'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has force flag', () {
      final flag = command.argParser.options['force'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });

    test('has dry-run flag', () {
      final flag = command.argParser.options['dry-run'];
      expect(flag, isNotNull);
      expect(flag!.isFlag, isTrue);
    });
  });
}
