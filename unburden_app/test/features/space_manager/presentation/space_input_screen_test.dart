import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/features/space_manager/data/space_repository_interface.dart';
import 'package:unburden_app/features/space_manager/domain/storage_location.dart';
import 'package:unburden_app/features/space_manager/presentation/space_input_screen.dart';

class FakeSpaceRepository implements SpaceRepositoryInterface {
  final List<StorageLocation> _store = [];

  @override
  Future<void> init() async {}

  @override
  Future<void> add(StorageLocation location) async => _store.add(location);

  @override
  Future<List<StorageLocation>> getAll() async => List.from(_store);
}

void main() {
  group('SpaceInputScreen', () {
    testWidgets('user types a description and sees parsed result', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: SpaceInputScreen(
          llm: MockLlmClient(fixedResponse: '''
{
  "name": "top wardrobe shelf",
  "width_cm": 80.0,
  "depth_cm": 40.0,
  "height_cm": 30.0,
  "contents": ["winter coats", "Christmas deco"],
  "access_note": "need the escabeau to reach it"
}
'''),
          repository: FakeSpaceRepository(),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'top wardrobe shelf, 80x40x30cm');

      await tester.runAsync(() async {
        await tester.tap(find.byType(ElevatedButton));
      });

      await tester.pumpAndSettle();

      expect(find.text('top wardrobe shelf'), findsOneWidget);
      expect(find.text('winter coats'), findsOneWidget);
    });
  });
}