import 'package:unburden_app/features/thoughts/domain/thought_entry.dart';

abstract class ThoughtRepositoryInterface {
  Future<void> add(ThoughtEntry entry);
  Future<List<ThoughtEntry>> getAll();
}
