abstract class ListRepositoryInterface {
  Future<void> addAll(List<String> items);
  Future<List<String>> getAll();
}
