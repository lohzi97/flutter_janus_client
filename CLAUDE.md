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

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **janus_client** - a feature-rich Flutter package for WebRTC operations with Janus WebRTC Server. The package provides a clean, maintainable API for integrating WebRTC functionality into Flutter applications.

## Architecture

The codebase follows a modular architecture with clear separation of concerns:

### Core Components

- **`janus_client.dart`**: Main library file that exports all public APIs using Dart's `part` directive
- **`janus_transport.dart`**: Abstract transport layer with two implementations:
  - `RestJanusTransport`: HTTP-based communication with polling for events
  - `WebSocketJanusTransport`: WebSocket-based communication for real-time events
- **`janus_session.dart`**: Manages Janus server sessions and handles session lifecycle
- **`janus_plugin.dart`**: Base plugin functionality and plugin management

### Plugin System

The library uses a wrapper plugin pattern with typed events for better IDE support:

- **Wrapper Plugins** (`lib/wrapper_plugins/`):
  - `janus_video_room_plugin.dart`: Video conferencing functionality
  - `janus_video_call_plugin.dart`: Peer-to-peer video calling
  - `janus_sip_plugin.dart`: SIP integration for VoIP calls
  - `janus_streaming_plugin.dart`: Media streaming capabilities
  - `janus_audio_bridge_plugin.dart`: Audio bridging and conferencing
  - `janus_text_room_plugin.dart`: Text-based chat rooms
  - `janus_echo_test_plugin.dart`: Echo testing for connectivity

### Typed Events System

- **Interfaces** (`lib/interfaces/`): Strongly-typed event classes for auto-completion
- Events are organized by plugin type (video_room, sip, streaming, etc.)
- Each plugin has specific event types extending base event classes

## Development Commands

### Building and Testing
```bash
# Run tests (using fvm)
fvm flutter test

# Analyze code (using fvm)
fvm flutter analyze

# Generate documentation
fvm dartdoc

# Build example app (using fvm)
cd example && fvm flutter build apk
cd example && fvm flutter build ios
```

### Dependencies Management
```bash
# Get dependencies (using fvm)
fvm flutter pub get

# Upgrade dependencies (using fvm)
fvm flutter pub upgrade
```

## Key Dependencies

- `flutter_webrtc: ^0.14.2`: Core WebRTC functionality
- `web_socket_channel: ^3.0.3`: WebSocket communication
- `http: ^1.4.0`: HTTP requests for REST API
- `uuid: ^4.5.1`: Unique identifier generation
- `logging: ^1.3.0`: Logging utilities
- `path_provider: ^2.1.5`: File system access

## Code Structure Patterns

### Transport Layer Pattern
Both transport implementations (`RestJanusTransport` and `WebSocketJanusTransport`) extend the abstract `JanusTransport` class, ensuring consistent API regardless of communication method.

### Plugin Wrapper Pattern
Each Janus plugin is wrapped in a Flutter-friendly class that:
- Provides high-level methods for common operations
- Handles low-level Janus protocol details
- Emits strongly-typed events for better developer experience

### Event System
The library uses Dart's `part` directive to organize related classes:
- Main functionality in `lib/` root
- Plugin-specific events in `lib/interfaces/{plugin}/events/`
- Typed event classes extending base event types

## Platform Support

The library supports all major platforms:
- **Mobile**: Android (fully tested), iOS (partially tested)
- **Desktop**: Windows, Linux, macOS (partially tested)
- **Web**: Browsers (fully tested)

## Important Notes

- The library uses **Unified Plan** for WebRTC SDP semantics
- WebSocket transport includes automatic reconnection and transaction timeout handling
- REST transport uses long-polling for real-time events
- All plugin operations are asynchronous and return `Future` objects
- Error handling is built into the transport layer with proper exception propagation

## Testing

Test files should be organized under `test/` directory. The library includes comprehensive examples in the `example/` folder that serve as integration tests and usage demonstrations.

## Version Requirements

- **Dart SDK**: >=3.6.0 <4.0.0
- **Flutter**: >=3.24.0 (currently using 3.32.8 via fvm)
- Package follows semantic versioning with current version 2.4.0