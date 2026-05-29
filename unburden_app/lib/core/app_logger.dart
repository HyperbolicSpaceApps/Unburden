import 'package:flutter/material.dart';

/// Simple logger. Set [AppLogger.enabled] to true during development.
class AppLogger {
  static bool enabled = false;

  static void ui(String message) => _log('🟢 [UI]', message);
  static void build(String message) => _log('🟣 [BUILD]', message);
  static void llm(String message) => _log('🟡 [LLM]', message);
  static void mock(String message) => _log('🔵 [MOCK]', message);
  static void groq(String message) => _log('🟠 [GROQ]', message);

  static void _log(String prefix, String message) {
    if (enabled) {
      debugPrint('$prefix $message');
    }
  }
}
