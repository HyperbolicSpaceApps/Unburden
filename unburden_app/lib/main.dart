import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:unburden_app/core/app_database.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/chat/domain/list_tool.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/list/data/list_repository.dart';
import 'package:unburden_app/features/where_is_it/data/where_is_it_repository.dart';

void main({String? dbPath, LlmClient? llmClient}) async {
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
        whereIsItRepository: WhereIsItRepository(database: db),
        listTools: [
          ListTool(name: 'grocery', repository: ListRepository(database: db, listName: 'grocery')),
          ListTool(name: 'todo', repository: ListRepository(database: db, listName: 'todo')),
          ListTool(
            name: 'thoughts',
            repository: ListRepository(database: db, listName: 'thoughts'),
          ),
        ],
      ),
    ),
  );
}
