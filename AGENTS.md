<!-- OPENSPEC:START -->
# OpenSpec Instructions

These instructions are for AI assistants working in this project.

Always open `@/openspec/AGENTS.md` when the request:
- Mentions planning or proposals (words like proposal, spec, change, plan)
- Introduces new capabilities, breaking changes, architecture shifts, or big performance/security work
- Sounds ambiguous and you need the authoritative spec before coding

Use `@/openspec/AGENTS.md` to learn:
- How to create and apply change proposals
- Spec format and conventions
- Project structure and guidelines

Keep this managed block so 'openspec update' can refresh the instructions.

<!-- OPENSPEC:END -->

# flutter_janus_client – Agent Guide

This file documents how automated coding agents should work in this repo: commands, style, and project conventions.

## OpenSpec usage

- For any change that looks like a feature, breaking change, or architectural shift, first read `openspec/AGENTS.md`.
- Follow the OpenSpec workflow there to decide whether you must create or update a proposal before touching production code.
- Bug fixes, small refactors, and test-only work usually do not need a proposal; larger behavior changes usually do.

## Build, lint, and test

### Root package (janus_client)

- Install dependencies:

```bash
flutter pub get
```

- Run static analysis for the root package:

```bash
flutter analyze
```

- Format Dart code (root only):

```bash
dart format .
```

- Run all tests for the package:

```bash
flutter test
```

- Run a single test file (recommended pattern):

```bash
flutter test test/janus_session_test.dart
```

- Run a single test by name inside a file:

```bash
flutter test test/janus_session_test.dart --plain-name "Session reclamation returns response"
```

- Use `dart test` only for pure Dart tests; prefer `flutter test` when files depend on Flutter bindings.

### Example app (`example/`)

- Install example dependencies:

```bash
cd example
flutter pub get
```

- Analyze example code:

```bash
cd example
flutter analyze
```

- Run example tests:

```bash
cd example
flutter test
```

- Build the web demo locally (matches CI workflow):

```bash
cd example
flutter pub get
flutter build web --release --base-href "/flutter_janus_client/"
```

### Networked / integration tests

- Many tests talk to real Janus servers (for example `wss://janus.conf.meetecho.com/ws` or `https://master-janus.onemandev.tech/rest`).
- Some tests (for example `test/janus_session_test.dart`) reference private endpoints such as `ws://10.17.1.31:8188/ws` and may fail outside the original environment.
- When adding new tests, prefer isolating network-heavy tests into clearly named files and document the required endpoints.
- Agents should not silently change existing endpoints; if they must change, explain why in the PR description.

## Code structure

- The public library entrypoint is `lib/janus_client.dart` with `library janus_client;` at the top.
- All other implementation files under `lib/` use `part of janus_client;` and are wired in via `part` directives from `lib/janus_client.dart`.
- High-level responsibilities:
  - `lib/janus_client.dart`: library wiring, public `JanusClient` entrypoint, shared imports.
  - `lib/janus_session.dart`, `lib/janus_transport.dart`, `lib/janus_plugin.dart`: core session, transport, and plugin abstractions.
  - `lib/wrapper_plugins/*.dart`: typed wrappers for Janus plugins (videoroom, videocall, textroom, streaming, audio bridge, sip, echo test).
  - `lib/interfaces/**`: value types and typed events used by the wrappers.
  - `lib/utils.dart`: shared helpers for UUIDs, JSON encode/decode, random strings, RTC helpers.

- When adding a new source file to the main library:
  - Add `part 'relative/path.dart';` to `lib/janus_client.dart`.
  - Start the new file with `part of janus_client;`.
  - Place domain models under `lib/interfaces/...` and plugin wrappers under `lib/wrapper_plugins/...`.

## Imports and dependencies

- In the main library file (`lib/janus_client.dart`):
  - Keep `library janus_client;` on the first line.
  - Group imports roughly as currently done:
    - Flutter and third-party packages (`package:flutter/...`, `package:logging/logging.dart`, `package:flutter_webrtc/flutter_webrtc.dart`, `package:http/http.dart`).
    - Dart SDK imports (`dart:async`, `dart:io`, `dart:convert`, `dart:developer`, `dart:math`), aliased where needed (for example `import 'dart:math' as Math;`).
    - Local packages (`package:janus_client/janus_client.dart`) only in tests and examples, not inside the library itself.
- In `part of` files:
  - Do not add new `import` statements unless strictly necessary; share imports via `lib/janus_client.dart` when possible.
  - If a file must import something unique, keep `part of janus_client;` first, then imports, then code.
- Use existing aliases consistently:
  - `package:http/http.dart` as `http`.
  - `dart:math` as `Math` (match current code when touching that file).
- For JSON encode/decode in library code, prefer existing helpers from `utils.dart`:
  - Use `stringify(...)` and `parse(...)` instead of ad‑hoc `jsonEncode` / `jsonDecode`.

## Types and nullability

- Public APIs, class fields, and return types should be explicitly typed (no bare `dynamic` except where unavoidable for Janus payloads).
- Use `late` fields for non-null members initialised in the constructor or during setup (see `JanusClient` and `WebSocketJanusTransport`).
- Domain model classes typically expose:
  - Constructor with named parameters.
  - `copyWith(...)` for immutable-style updates.
  - `toMap()` / `fromMap()` and optionally `toJson()` / `fromJson()` when serialised.
  - `==`, `hashCode`, and `toString()` overrides when comparing instances (see `TypedEvent`, `JanusError`, `RTCIceServer`).
- When modelling Janus gateway messages:
  - Use Dart lowerCamelCase field names and map them to Janus wire keys in `toMap()` / `fromMap()`.
  - Prefer typed wrappers (for example `VideoRoomJoinedEvent`) over raw `Map<String, dynamic>` where practical.

## Naming conventions

- Classes, typedefs, and enums: PascalCase (for example `JanusVideoRoomPlugin`, `ConfigureStreamQuality`).
- Enum values: match the surrounding file; many existing enums use all-caps (`LOW`, `MEDIUM`, `HIGH`).
- Methods and functions: lowerCamelCase verbs or verb phrases (`createSession`, `getInfo`, `destroyRoom`).
- Private members: prefix with `_` (for example `_transport`, `_pendingTransactions`).
- Stream and async naming:
  - Use `...Stream` / `...Controller` / `...Sink` suffixes for streams and sinks where helpful.
  - Name futures based on their side effect (`publishMedia`, `joinSubscriber`).

## Error handling and logging

- Transport-level errors:
  - `RestJanusTransport.post` and `get` use `stringify` / `parse` and return `null` for JSON or network issues; callers must defensively handle `null`.
  - `WebSocketJanusTransport.send` throws `StateError` when not connected and `TimeoutException` on repeated response timeouts.
- Janus protocol errors:
  - Use `JanusError` (`lib/interfaces/typed_event.dart`) to represent plugin-level failures.
  - Prefer `JanusError.throwErrorFromEvent(...)` when you have a `JanusEvent` and want to surface any embedded error.
- Logging:
  - In library code, prefer `logging.Logger` (see `JanusClient`) over `print` for new functionality.
  - For new public APIs, log high-level actions at `info`, detailed diagnostics at `fine`, and failures at `severe`.
  - In tests, direct `print` is acceptable for debugging, but avoid adding new noisy logging in steady-state tests.

## Testing conventions

- Two testing styles exist:
  - Flutter tests using `package:flutter_test/flutter_test.dart` (for tests needing Flutter bindings).
  - Pure Dart tests using `package:test/test.dart` (for protocol and logic tests).
- When adding tests:
  - Prefer `package:test` for logic that does not depend on Flutter widgets or bindings.
  - Use `group` to cluster related tests and keep names descriptive (include transport, plugin, and scenario).
  - Use `expect(..., throwsA(...))` for error cases; assert on types and message prefixes rather than full strings when possible.
- Network-dependent tests should be clearly named and, where possible, separated so they can be skipped or quarantined.

## Cursor and Copilot rules

- There are currently no repo-level Cursor rules (`.cursor/rules/**` or `.cursorrules`) and no Copilot instruction file at `.github/copilot-instructions.md`.
- If such rules are added later, update this section to summarise any constraints that impact automated agents (for example files to avoid, review requirements, or style overrides).

## Agent checklist

- Before major work:
  - Check whether the request needs an OpenSpec proposal; if so, follow `openspec/AGENTS.md`.
  - Skim `lib/janus_client.dart` and the relevant `wrapper_plugins` / `interfaces` files to match existing patterns.
- When editing code:
  - Keep the `part` / `part of` structure intact and update `lib/janus_client.dart` when adding new pieces.
  - Match surrounding style for imports, naming, and logging.
  - Treat network endpoints and protocol fields as part of the public API; do not change them casually.
- After changes:
  - Run `flutter analyze` and `flutter test` (or the narrowest relevant subset) in this repo.
  - If you touched the example app, run `cd example && flutter analyze` and at least `flutter test` there.
