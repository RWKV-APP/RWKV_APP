import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zone/func/sensitive_filter.dart';

void main() {
  group('parseSensitiveFilterRules', () {
    test('splits plain words and compound rules', () {
      const filter = '''
plain
Alpha|Beta
中|央

''';

      final rules = parseSensitiveFilterRules(filter);

      expect(rules.plainWords, contains('plain'));
      expect(rules.compoundRules, contains(equals(<String>['Alpha', 'Beta'])));
      expect(rules.compoundRules, contains(equals(<String>['中', '央'])));
      expect(rules.unorderedCompoundRules, contains(equals(<String>['Alpha', 'Beta'])));
      expect(rules.orderedCompoundRules, contains(equals(<String>['中', '央'])));
      expect(rules.index.patterns, containsAll(<String>['plain', 'Alpha', 'Beta', '中', '央']));
      expect(rules.maxLength, 10);
    });

    test('keeps malformed pipe rules as plain words', () {
      const filter = '''
A|
|B
A|A
''';

      final rules = parseSensitiveFilterRules(filter);

      expect(rules.plainWords, containsAll(<String>['A|', '|B', 'A|A']));
      expect(rules.compoundRules, isEmpty);
    });

    test('deduplicates equivalent compound rules', () {
      const filter = '''
Alpha|Beta
Alpha|Beta
Alpha | Beta
''';

      final rules = parseSensitiveFilterRules(filter);

      expect(rules.compoundRules, hasLength(1));
      expect(rules.compoundRules.single, <String>['Alpha', 'Beta']);
    });
  });

  group('findSensitiveFilterMatch', () {
    test('matches plain words as before', () {
      final rules = parseSensitiveFilterRules('plain\nAlpha|Beta');

      final match = findSensitiveFilterMatch((
        index: rules.index,
        text: 'text with plain word',
      ));

      expect(match, 'plain');
    });

    test('keeps plain word priority before compound rules', () {
      final rules = parseSensitiveFilterRules('Alpha\nAlpha|Beta');

      final match = findSensitiveFilterMatch((
        index: rules.index,
        text: 'Beta and Alpha',
      ));

      expect(match, 'Alpha');
    });

    test('requires every part of a compound rule', () {
      final rules = parseSensitiveFilterRules('Alpha|Beta');

      final onlyA = findSensitiveFilterMatch((
        index: rules.index,
        text: 'Alpha appears alone',
      ));
      final onlyB = findSensitiveFilterMatch((
        index: rules.index,
        text: 'Beta appears alone',
      ));
      final both = findSensitiveFilterMatch((
        index: rules.index,
        text: 'Beta appears before Alpha',
      ));

      expect(onlyA, isNull);
      expect(onlyB, isNull);
      expect(both, 'Alpha|Beta');
    });

    test('requires ordered parts for a single-character compound rule', () {
      final rules = parseSensitiveFilterRules('A|B|C');

      final partial = findSensitiveFilterMatch((
        index: rules.index,
        text: 'A and C appear',
      ));
      final reversed = findSensitiveFilterMatch((
        index: rules.index,
        text: 'C, B, then A',
      ));
      final complete = findSensitiveFilterMatch((
        index: rules.index,
        text: 'A, B, then C',
      ));

      expect(partial, isNull);
      expect(reversed, isNull);
      expect(complete, 'A|B|C');
    });

    test('matches malformed pipe rules only as literal text', () {
      final rules = parseSensitiveFilterRules('A|');

      final partial = findSensitiveFilterMatch((
        index: rules.index,
        text: 'A appears alone',
      ));
      final literal = findSensitiveFilterMatch((
        index: rules.index,
        text: 'literal A| appears',
      ));

      expect(partial, isNull);
      expect(literal, 'A|');
    });
  });

  group('findSensitiveFilterMatchInWindows', () {
    test('matches a plain word before the tail of a long text', () {
      final rules = parseSensitiveFilterRules('blocked\nAlpha|Beta\n0123456789');
      final text = 'blocked ${List<String>.filled(80, 'x').join()}';

      final match = findSensitiveFilterMatchInWindows((
        index: rules.index,
        maxLength: rules.maxLength,
        text: text,
      ));

      expect(match, 'blocked');
    });

    test('matches compound parts in an early window of a long text', () {
      final rules = parseSensitiveFilterRules('Alpha|Beta\n01234567890123456789');
      final text = 'Beta${List<String>.filled(8, 'x').join()}Alpha${List<String>.filled(80, 'z').join()}';

      final match = findSensitiveFilterMatchInWindows((
        index: rules.index,
        maxLength: rules.maxLength,
        text: text,
      ));

      expect(match, 'Alpha|Beta');
    });

    test('does not match compound parts outside the same window', () {
      final rules = parseSensitiveFilterRules('Alpha|Beta\n01234567890123456789');
      final text = 'Alpha${List<String>.filled(80, 'x').join()}Beta';

      final match = findSensitiveFilterMatchInWindows((
        index: rules.index,
        maxLength: rules.maxLength,
        text: text,
      ));

      expect(match, isNull);
    });

    test('matches ordered single-character rules in a window', () {
      final rules = parseSensitiveFilterRules('A|B|C\n0123456789');
      final text = 'A${List<String>.filled(3, 'x').join()}B${List<String>.filled(3, 'x').join()}C';

      final match = findSensitiveFilterMatchInWindows((
        index: rules.index,
        maxLength: rules.maxLength,
        text: text,
      ));

      expect(match, 'A|B|C');
    });

    test('does not match reversed single-character rules in a window', () {
      final rules = parseSensitiveFilterRules('A|B|C\n0123456789');
      const text = 'C then B then A';

      final match = findSensitiveFilterMatchInWindows((
        index: rules.index,
        maxLength: rules.maxLength,
        text: text,
      ));

      expect(match, isNull);
    });
  });

  group('compute compatibility', () {
    test('parses rules through compute', () async {
      final rules = await compute(parseSensitiveFilterRules, 'plain\nAlpha|Beta\nA|B');

      expect(rules.plainWords, contains('plain'));
      expect(rules.unorderedCompoundRules, contains(equals(<String>['Alpha', 'Beta'])));
      expect(rules.orderedCompoundRules, contains(equals(<String>['A', 'B'])));
      expect(rules.index.patterns, containsAll(<String>['plain', 'Alpha', 'Beta', 'A', 'B']));
    });

    test('matches rules through compute', () async {
      final rules = parseSensitiveFilterRules('Alpha|Beta');

      final match = await compute(
        findSensitiveFilterMatch,
        (
          index: rules.index,
          text: 'Beta and Alpha',
        ),
      );

      expect(match, 'Alpha|Beta');
    });

    test('matches window rules through compute', () async {
      final rules = parseSensitiveFilterRules('Alpha|Beta\n01234567890123456789');
      final text = 'Beta${List<String>.filled(8, 'x').join()}Alpha${List<String>.filled(80, 'z').join()}';

      final match = await compute(
        findSensitiveFilterMatchInWindows,
        (
          index: rules.index,
          maxLength: rules.maxLength,
          text: text,
        ),
      );

      expect(match, 'Alpha|Beta');
    });
  });
}
