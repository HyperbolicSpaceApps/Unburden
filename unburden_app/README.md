# unburden_app

Flutter app for Unburden. Android-first, local-first, AI-assisted.

---

## Tech stack

* Flutter / Dart
* SQLite via `sqflite`
* Groq API (`llama-3.1-8b-instant`) via `GroqLlmClient`
* `flutter_dotenv` for API key management

---

## Architecture
ChatScreen
↓
buildChatPrompt (chat_prompt_builder.dart)
↓
LlmClient (abstract)
├── MockLlmClient (tests)
└── GroqLlmClient (production)
↓
SpaceRepositoryInterface (abstract)
├── FakeSpaceRepository (tests)
└── SpaceRepository (SQLite, production)
↓
buildConfirmationMessage (confirmation_builder.dart)

---

## File inventory
lib/
main.dart                          ← composition root, wires LlmClient + repository + ChatScreen
core/
llm_client.dart                  ← abstract LlmClient interface
mock_llm_client.dart             ← fixed/echo responses, used in tests
groq_llm_client.dart             ← production Groq API via http
app_logger.dart                  ← debug logging, silent in release
features/
chat/
domain/
chat_prompt_builder.dart     ← builds the prompt string sent to LLM
confirmation_builder.dart    ← builds deterministic confirmation message from saved names
presentation/
chat_screen.dart             ← main UI, wires prompt + LLM + repository
space_manager/
  domain/
    storage_location.dart        ← core data model
    space_parser.dart            ← natural language → List<StorageLocation> via LLM
  data/
    space_repository_interface.dart  ← abstract repository contract
    space_repository.dart            ← SQLite implementation
    fake_space_repository.dart       ← in-memory implementation for tests
test/
features/
chat/
llm/
chat_prompt_test.dart        ← prompt contract tests (fast, no network)
presentation/
chat_screen_test.dart        ← widget behavior tests
space_manager/
  data/
    space_repository_test.dart   ← SQLite persistence tests
  domain/
    space_parser_test.dart       ← parser unit tests
integration_test/
app_test.dart                      ← full app smoke tests + scroll test
llm_behavior_test.dart             ← real LLM behavioral contracts with LLM-as-judge

---

## Running the app

Copy `.env.example` to `.env` and set your Groq API key:
UNBURDEN_GROQ_API_KEY=your_key_here

Then:

```bash
flutter run
```

---

## Testing

Fast (unit + widget, no network):

```bash
flutter test
```

Full (integration, requires device or Linux desktop):

```bash
flutter test integration_test/app_test.dart
```

LLM behavior tests (requires `UNBURDEN_GROQ_API_KEY` in environment):

```bash
flutter test integration_test/llm_behavior_test.dart
```

---

## Session history

### Session 1 — domain model + persistence
* `StorageLocation` domain model
* `SpaceRepository` with SQLite, `add()` + `getAll()`
* `LlmClient` abstraction, `MockLlmClient`, `GroqLlmClient`
* `SpaceParser` with `parseMany()`
* `SpaceInputScreen` (later replaced by `ChatScreen`)
* Duplicate prevention at repository level
* Integration test with sqflite FFI on Linux

### Session 2 — chat refactor
* `ChatScreen` replaced `SpaceInputScreen` — chat is now the app
* Structured LLM response contract: `action` + `locations` + `message`
* `AppLogger` introduced
* `FakeSpaceRepository` moved to `lib/` as shared test infrastructure
* All tests migrated to chat screen

### Session 3 — prompt quality + TDD discipline
* `buildChatPrompt` extracted to `chat_prompt_builder.dart`
* `chat_prompt_test.dart` introduced — prompt contract tests (fast, no network)
* `llm_behavior_test.dart` introduced — real LLM behavioral contracts with LLM-as-judge pattern
* Prompt fixed: each physical zone saved as a separate location
* Prompt fixed: LLM grounded to stored data only when answering
* `buildConfirmationMessage` extracted to `confirmation_builder.dart`
* Confirmation message now built deterministically by the app, not the LLM
* Auto-scroll to latest message
* Selectable text on LLM responses
* All 21 unit tests green, 4 integration tests green

---

## Next session start point

* All 21 unit tests green, 4 integration tests green
* Run app on physical Android device
* Note friction points → drive next failing test from real usage
* Known candidates: grocery list use case, voice input, model selection