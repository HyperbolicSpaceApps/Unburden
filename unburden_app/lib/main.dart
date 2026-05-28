import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:unburden_app/core/mock_llm_client.dart';
import 'package:unburden_app/features/space_manager/data/space_repository.dart';
import 'package:unburden_app/features/space_manager/presentation/space_input_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbPath = join(await getDatabasesPath(), 'unburden.db');

  runApp(MaterialApp(
    home: SpaceInputScreen(
      llm: MockLlmClient(fixedResponse: '''
{
  "name": "mocked location",
  "width_cm": 80.0,
  "depth_cm": 40.0,
  "height_cm": 30.0,
  "contents": ["item one", "item two"],
  "access_note": "easy to reach"
}
'''),
      repository: SpaceRepository(dbPath: dbPath),
    ),
  ));
}