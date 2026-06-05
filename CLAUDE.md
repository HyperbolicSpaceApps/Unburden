# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

All commands run from the `unburden_app/` directory.

```bash
flutter pub get                          # install dependencies
flutter test                             # run all unit tests
flutter test test/path/to/test.dart      # run a single test file
flutter analyze                          # lint
flutter run -d linux                     # run on Linux desktop

# Integration tests (require a connected device or Linux desktop target)
flutter test integration_test/app_test.dart -d linux

# LLM behaviour tests (require UNBURDEN_GROQ_API_KEY in environment)
flutter test integration_test/llm_behaviour_test.dart -d linux
```

Environment: create `unburden_app/.env` with `UNBURDEN_GROQ_API_KEY=<your-key>`. The file is bundled as a Flutter asset and loaded at startup via `flutter_dotenv`.

## Architecture

The app is a single-screen Flutter chat interface. Every user message is sent to an LLM, which must return a structured JSON action. The action is dispatched to one of three tools.

### Request flow

1. `ChatScreen._onSend()` reads all repositories, calls `buildChatPrompt()` to construct the system prompt with current data context, then calls `LlmClient.complete()`.
2. The LLM returns a JSON object with an `action` field: `save_locations`, `add_items`, `add_thought`, or `answer`.
3. `ChatScreen` parses the JSON and dispatches to the appropriate repository or displays the message.
4. Conversation history (`_history`) is maintained in memory and passed on every turn for multi-turn context.

### LLM abstraction (`lib/core/`)

`LlmClient` is a one-method interface (`complete(systemPrompt, messages)`). Implementations:

- `GroqLlmClient` — production; calls Groq API with `llama-3.1-8b-instant`
- `MockLlmClient` — returns a fixed JSON response; used in widget/integration tests
- `CapturingLlmClient` — records all `messages` arguments; used to assert conversation history in tests
- `ThrowingLlmClient` — always throws; used to test error handling

`main()` accepts optional `dbPath` and `llmClient` parameters so tests can inject both without touching the real database or network.

### System prompt (`lib/features/chat/domain/chat_prompt_builder.dart`)

`buildChatPrompt()` is the single source of truth for what the LLM can do. It injects current repository state (locations, grocery items) and optional user-defined rules per tool into the prompt. When adding a new tool, add its JSON schema and instructions here.

### Feature layout

Each feature under `lib/features/<tool>/` follows:

```
domain/<model>.dart                  — data class
data/<tool>_repository_interface.dart — abstract interface
data/fake_<tool>_repository.dart     — in-memory impl (tests)
data/<tool>_repository.dart          — SQLite impl (production)
```

Real repositories take `AppDatabase`; `AppDatabase` holds the SQLite connection and all `CREATE TABLE` statements in `onCreate`.

### Adding a new tool

Follow the steps in README.md: domain model → repository interface → fake repo → real repo → database table → agent routing → `ChatScreen` action branch → `main.dart` wiring → tests.

The key files to touch: `app_database.dart` (schema), `agent_router.dart` (enum + keywords), `chat_prompt_builder.dart` (system prompt), `chat_screen.dart` (action dispatch + constructor param), `main.dart` (instantiation).

### Development workflow

TDD: write a failing test, implement the minimal fix, refactor. `agent_router.dart` uses keyword matching as a placeholder — the test contract in `agent_router_test.dart` defines expected behaviour and must stay stable when the implementation is replaced with LLM-based routing.
