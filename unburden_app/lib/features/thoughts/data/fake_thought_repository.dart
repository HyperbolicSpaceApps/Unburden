import 'package:unburden_app/features/thoughts/data/thought_repository_interface.dart';
import 'package:unburden_app/features/thoughts/domain/thought_entry.dart';

class FakeThoughtRepository implements ThoughtRepositoryInterface {
  final List<ThoughtEntry> _store = [];

  @override
  Future<void> add(ThoughtEntry entry) async {
    _store.add(entry);
  }

  @override
  Future<List<ThoughtEntry>> getAll() async => List.from(_store);
}
