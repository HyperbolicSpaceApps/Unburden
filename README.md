# Unburden
Context-aware lists designed to reduce mental load.

---
## Adding a new tool

1. **Domain model** — `lib/features/<tool>/domain/<model>.dart`
   Define the data class for this tool's entries.

2. **Repository interface** — `lib/features/<tool>/data/<tool>_repository_interface.dart`
   Declare `add()` and `getAll()` against your model.

3. **Fake repository** — `lib/features/<tool>/data/fake_<tool>_repository.dart`
   In-memory implementation of the interface. Used in tests.

4. **Real repository** — `lib/features/<tool>/data/<tool>_repository.dart`
   SQLite implementation. Takes `AppDatabase`, queries its own table.

5. **Database table** — `lib/core/app_database.dart`
   Add a `CREATE TABLE` statement in `onCreate`.

6. **Agent routing** — `lib/features/agent/agent_router.dart`
   Add the new `Tool` enum value and keywords.

7. **Action handler** — `lib/features/chat/presentation/chat_screen.dart`
   Add the new `action` branch in `_onSend()`, the repository param in the
   constructor, and update all existing `ChatScreen(...)` calls in
   `test/features/chat/presentation/chat_screen_test.dart` to pass the new
   fake repository.

8. **Wiring** — `lib/main.dart`
   Instantiate the real repository and pass it to `ChatScreen`.

9. **Tests**
   - Repository test: add/getAll via fake, duplicate behaviour
   - Agent routing test: keywords route to the new tool
   - Widget test: action handled, item stored, confirmation shown

---

## Vision

Most list apps are passive.

They store information, but they do not understand context.

This project explores a different approach:

* lists that adapt to context,
* rules defined by the user,
* AI-assisted prioritization and organization,
* local-first storage and model selection.

The goal is to reduce mental load and help fight procrastination in everyday life.

---

# Core Ideas

## Context-aware lists

A list should behave differently depending on the situation.

Example of contexts:

* "I go shopping" implicitly means Lidl + dm
* some products should be hidden depending on the store
* grocery items should be ordered according to the physical store layout
* electronics purchases should default to Amazon-related workflows

The app should help surface only the relevant information at the right moment.

---

## User-defined rules

Rules are explicit and owned by the user.

Examples:

* "Beurre breton is not available at Lidl"
* "Frozen food should appear last in the grocery list"
* "Laundry supplies belong to dm"

The system should combine:

* deterministic rules stored locally and managed by the user,
* contextual understanding,
* AI reasoning as top layer (agent role).

---

## Local-first philosophy

The project is intentionally designed around:

* local storage,
* user-configurable models and API keys,
* minimal infrastructure.

Personal data should remain on-device whenever possible.

Different models can be selected depending on:

* privacy requirements,
* task complexity,
* speed/cost tradeoffs.

Examples:

* local model for sensitive information,
* stronger hosted model for planning or reasoning tasks.

---

# Example Use Cases

## Grocery management

* Context-aware shopping lists
* Store-specific filtering
* Route optimization inside stores
* Smart grouping and deduplication
* Priority suggestions

---

## Everyday maintenance

Track recurring mental load:

* paperwork,
* dishes,
* laundry,
* cleaning,
* small unresolved tasks.

The system can suggest practical improvements to maintain a functional environment:

* extra laundry baskets if clothes are piling up everywhere,
* better storage organization,
* appliance recommendations.

---

## Idea capture

Store:

* thoughts,
* project ideas,
* future plans,
* references,
* unfinished concepts.

---

## Therapy / health support

Dedicated spaces for:

* psychotherapy notes,
* dietician follow-up,
* habits,
* recurring observations,
* self-management.

---

## Space management

A practical inventory of:

* storage locations,
* rough dimensions,
* object placement,
* accessibility.

Use cases:
* move low-frequency items higher or farther away (less premium location),
* optimize frequently used zones,
* remember where rarely-used items are stored.

This is the first MVP feature, currently in active development.

---

# AI Philosophy

AI is treated as a tool dispatcher, not as a personality.

Possible responsibilities:

* interpret user intent,
* choose the correct list/tool,
* prioritize information,
* simplify duplicate entries,
* ask clarification questions,
* suggest optimizations.

The user remains in control.

---

# Tech Stack

## Mobile

* Dart
* Flutter (Android-first)

## AI

* Groq API (OpenAI-compatible, `llama-3.1-8b-instant`)
* LlmClient abstraction — swap-ready for any provider

## Storage

* SQLite (via sqflite)
* Local-first, no cloud backend required

---

# Development Style

The project is built with AI-assisted TDD.

Workflow:

1. write failing test (red),
2. implement minimal fix (green),
3. refactor (blue),
4. iterate.

The objective is to keep the architecture simple, modular, and testable.

---

# Status

Active development. Space management is the first MVP use case.
The primary goal is solving real everyday friction, for me first.


