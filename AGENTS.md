
# flutter_janus_client - Agent Guide

This repo is a Flutter/Dart package (`janus_client`) plus an `example/` app. Agents should match existing conventions and avoid accidental API churn.

## OpenSpec (design artifacts)

- OpenSpec content lives under `openspec/` (there is no `openspec/AGENTS.md` in this repo).
- For non-trivial changes (new feature, behavior change, breaking API, protocol/transport changes): start by reading `openspec/project.md`, then check existing proposals under `openspec/changes/`.
- Small bug fixes, refactors, docs, and test-only work typically do not require a new proposal.

## Build / Lint / Test

### Root package

```bash
fvm flutter --version
fvm dart --version
fvm flutter pub get
fvm flutter analyze
fvm dart format .
fvm flutter test
```

Single test file:

```bash
fvm flutter test test/janus_transport_test.dart
```

Single test by name:

```bash
fvm flutter test test/janus_session_test.dart --plain-name "Session reclamation returns response"
```

Notes:

- Prefer `fvm flutter test` over `fvm dart test` unless a test is truly Flutter-free.
- CI/publishing uses Flutter stable (see `.github/workflows/publish_package.yaml`); `pubspec.yaml` requires Dart `>=3.6.0`.
- For release hygiene: `fvm dart pub publish --dry-run` (CI runs this on GitHub releases).
- Optional docs build: `fvm dart doc`.

### Example app (`example/`)

```bash
cd example
fvm flutter pub get
fvm flutter analyze
fvm dart format .
fvm flutter test
```

Web demo build (matches GitHub Pages workflow in `.github/workflows/main.yml`):

```bash
cd example
fvm flutter pub get
fvm flutter build web --release --base-href "/flutter_janus_client/"
```

### Network-dependent tests

- Several tests hit real Janus endpoints; some use private IPs (e.g. `ws://10.17.1.31:8188/ws` in `test/janus_session_test.dart`) and may fail in other environments.
- Do not silently change endpoints in existing tests; if you must, explain why and prefer making endpoints configurable (env var/const) or isolating them into clearly named network tests.

## Library structure (important)

- Public entrypoint: `lib/janus_client.dart` (`library janus_client;` at top).
- Most implementation files are `part of janus_client;` and are wired via `part` directives in `lib/janus_client.dart`.
- Key locations:
  - `lib/janus_session.dart`, `lib/janus_transport.dart`, `lib/janus_plugin.dart`: core session/transport/plugin abstractions.
  - `lib/wrapper_plugins/*.dart`: typed wrappers for Janus plugins.
  - `lib/interfaces/**`: value types and typed events consumed by wrappers.
  - `lib/utils.dart`: shared helpers (UUIDs, JSON parse/stringify, misc helpers).
- Add new library files by:
  - creating `lib/.../*.dart` starting with `part of janus_client;`
  - adding a matching `part '...';` line to `lib/janus_client.dart`

## Code style guidelines

### Formatting

- Use `fvm dart format` (default line width); keep diffs focused (avoid drive-by reformatting of unrelated files).
- Avoid large mechanical rewrites (import reordering, mass renames, quote changes) unless the task demands it.

### Imports

- Only `lib/janus_client.dart` should typically contain imports for the library; `part of` files should avoid adding imports.
- `part of` files inherit imports from `lib/janus_client.dart`; prefer adding dependencies there rather than scattering imports.
- Tests/examples may import `package:janus_client/janus_client.dart` directly.
- Keep existing aliases and patterns:
  - `import 'package:http/http.dart' as http;`
  - `import 'dart:math' as Math;`

### Types, nullability, and API stability

- Prefer explicit types in new code; avoid introducing new `dynamic` unless unavoidable for Janus payloads.
- Be careful changing existing `Future<dynamic>` / `Map`-shaped APIs: this package is consumed by downstream apps.
- Use `late` for non-null fields initialized during construction/setup; otherwise prefer nullable with clear checks.
- Prefer `final` for locals; avoid using `var` when the type matters for readability.

### Naming

- Dart identifiers: classes/enums `PascalCase`, methods/vars `lowerCamelCase`, private members prefixed `_`.
- Wire-format keys are Janus-defined and often `snake_case`; keep them in payload maps (e.g. `"session_id"`, `"audio_level_average"`).
- File names are `snake_case` (see `lib/wrapper_plugins/*.dart`).
- Match surrounding style for enum values (many wrappers use `LOW`/`MEDIUM`/`HIGH`).

### JSON and map conversions

- Shared helpers live in `lib/utils.dart`: prefer `stringify(...)` and `parse(...)` when interacting with Janus transport payloads.
- `parse(...)` treats `null`/empty payloads as `{}`; keep this behavior in mind when tightening types.
- For models/events, follow the existing pattern: constructor + `toMap()`/`fromMap()` (+ optional `toJson()`/`fromJson()`), and implement `==`/`hashCode` when instances are compared.

### Error handling

- `RestJanusTransport.post/get` may return `null` on network/JSON issues; callers must handle `null` defensively.
- `WebSocketJanusTransport.send` throws:
  - `StateError` when not connected
  - `TimeoutException` when a transaction times out after retries
- For plugin-level failures surfaced by Janus, use `JanusError` and `JanusError.throwErrorFromEvent(...)` (`lib/interfaces/typed_event.dart`).
- Avoid introducing new APIs that throw raw `String`; prefer `Exception`/`StateError`/`JanusError`.

### Logging

- Prefer `package:logging` (`Logger`) in library code; avoid adding new `print` calls except in tests/examples.
- Log levels: `info` for high-level actions, `fine` for diagnostics, `severe` for failures.

### Testing conventions

- Tests live in `test/` and mostly use `package:test/test.dart`.
- Prefer `group(...)` and descriptive test names; for error cases, assert on type + a stable message prefix rather than full strings.

## Cursor / Copilot rules

- No Cursor rules found (`.cursor/rules/**` absent, `.cursorrules` absent).
- No Copilot rules found (`.github/copilot-instructions.md` absent).

## Quick agent checklist

- Before a big change: review `openspec/project.md` and related proposals under `openspec/changes/`.
- When adding files under `lib/`: keep the `part`/`part of` structure consistent and update `lib/janus_client.dart`.
- Before sending a PR: run `fvm flutter analyze` + the narrowest relevant `fvm flutter test` command(s); run example checks if you touched `example/`.
