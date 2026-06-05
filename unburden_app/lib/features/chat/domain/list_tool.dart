import 'package:unburden_app/features/list/data/list_repository_interface.dart';

class ListTool {
  final String name;
  final ListRepositoryInterface repository;
  final String? promptDescription;

  const ListTool({required this.name, required this.repository, this.promptDescription});
}
