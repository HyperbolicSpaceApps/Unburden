import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:unburden_app/core/groq_llm_client.dart';
import 'package:unburden_app/core/llm_client.dart';
import 'package:unburden_app/features/chat/presentation/chat_screen.dart';
import 'package:unburden_app/features/space_manager/data/space_repository.dart';

void main({String? dbPath, LlmClient? llmClient}) async {
  // uncomment for verbose logging
  //AppLogger.enabled = kDebugMode;

  WidgetsFlutterBinding.ensureInitialized();
  final path = dbPath ?? join(await getDatabasesPath(), 'unburden.db');

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
        repository: SpaceRepository(dbPath: path),
      ),
    ),
  );
}
