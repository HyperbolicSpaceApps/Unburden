import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/features/thoughts/data/fake_thought_repository.dart';
import 'package:unburden_app/features/thoughts/domain/thought_entry.dart';

void main() {
  group('ThoughtRepository', () {
    test('stored thought is returned by getAll', () async {
      final repo = FakeThoughtRepository();
      await repo.add(ThoughtEntry(text: 'I like the sunset today'));

      final entries = await repo.getAll();

      expect(entries.length, equals(1));
      expect(entries.first.text, equals('I like the sunset today'));
    });

    test('multiple thoughts are all stored and ordered by insertion', () async {
      final repo = FakeThoughtRepository();
      await repo.add(ThoughtEntry(text: 'first thought'));
      await repo.add(ThoughtEntry(text: 'second thought'));

      final entries = await repo.getAll();

      expect(entries.length, equals(2));
      expect(entries.first.text, equals('first thought'));
      expect(entries.last.text, equals('second thought'));
    });
  });
}
