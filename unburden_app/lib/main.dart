import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/grocery/data/grocery_repository.dart';
import 'package:unburden_app/features/space_manager/data/space_repository.dart';
import 'package:unburden_app/features/thoughts/data/thought_repository.dart';
import 'package:unburden_app/features/todo/data/todo_repository.dart';

void main({String? dbPath, LlmClient? llmClient}) async {
  // see app_logger to force verbose test logs

  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final path = dbPath ?? join(await getDatabasesPath(), 'unburden.db');
  final db = AppDatabase(dbPath: path);

  final LlmClient resolvedLlm;
  if (llmClient != null) {
    resolvedLlm = llmClient;
  } else {
    await dotenv.load(fileName: ".env");
    final apiKey = dotenv.env['UNBURDEN_GROQ_API_KEY'] ?? '';
    resolvedLlm = GroqLlmClient(apiKey: apiKey);
  }

  runApp(
    MaterialApp(
      home: ChatScreen(
        llm: resolvedLlm,
        spaceRepository: SpaceRepository(database: db),
        groceryRepository: GroceryRepository(database: db),
        thoughtRepository: ThoughtRepository(database: db),
        todoRepository: TodoRepository(database: db),
      ),
    ),
  );
}
