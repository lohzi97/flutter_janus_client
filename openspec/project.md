# Project Context

## Purpose
**janus_client** is a feature-rich Flutter package that provides WebRTC operations with Janus WebRTC Server. The package enables developers to easily integrate real-time communication capabilities (video conferencing, audio calls, streaming, SIP, etc.) into Flutter applications with a clean and maintainable API.

Key goals:
- Provide high-level Flutter-friendly APIs for all Janus server plugins
- Support both REST and WebSocket transport protocols
- Offer typed events and plugin wrappers for excellent IDE support
- Enable cross-platform WebRTC functionality (mobile, desktop, web)
- Maintain lightweight design while providing comprehensive features

## Tech Stack

### Core Technologies
- **Dart SDK**: >=3.6.0 <4.0.0
- **Flutter**: >=3.24.0
- **WebRTC**: flutter_webrtc ^1.2.0 for all WebRTC operations
- **Communication**: HTTP (^1.6.0) and WebSocket (^3.0.3) protocols

### Key Dependencies
- **uuid**: ^4.5.2 - Unique identifier generation for sessions/transactions
- **logging**: ^1.3.0 - Structured logging throughout the library
- **path_provider**: ^2.1.5 - File system access for platform-specific needs
- **http**: ^1.6.0 - REST API communication with Janus server
- **web_socket_channel**: ^3.0.3 - WebSocket real-time communication

### Development Tools
- **flutter_test**: Built-in testing framework
- **dartdoc**: ^9.0.0 - API documentation generation
- **GitHub Actions**: CI/CD pipeline for testing and publishing

## Project Conventions

### Code Style
- **Dart Style Guide**: Follows official Dart conventions
- **Naming**:
  - Classes: PascalCase (e.g., `JanusVideoRoomPlugin`)
  - Methods: camelCase (e.g., `createSession()`)
  - Variables: camelCase with descriptive names
  - Files: snake_case (e.g., `janus_video_room_plugin.dart`)
- **Organization**:
  - Uses `part` directives for modular library structure
  - Plugin wrappers in `lib/wrapper_plugins/`
  - Typed events in `lib/interfaces/{plugin}/events/`
  - Core functionality in `lib/` root

### Architecture Patterns
- **Transport Layer Pattern**: Abstract `JanusTransport` with concrete implementations (`RestJanusTransport`, `WebSocketJanusTransport`)
- **Plugin Wrapper Pattern**: High-level Flutter-friendly classes wrapping low-level Janus protocol details
- **Event System**: Strongly-typed event classes extending base types for IDE auto-completion
- **Session Management**: Centralized session handling with lifecycle management
- **Async/Await**: All operations are asynchronous returning `Future` objects

### Testing Strategy
- **Unit Tests**: Located in `test/` directory
- **Integration Examples**: Comprehensive examples in `example/` folder
- **Platform Testing**: Matrix covers Android (fully tested), iOS/desktop (partially tested), Web (fully tested)
- **CI Testing**: Automated testing on pull requests to master branch
- **Manual Testing**: Real device testing for WebRTC functionality

### Git Workflow
- **Main Branch**: `master` - primary development branch
- **Branching**: Feature branches for new development
- **Pull Requests**: Required for merging into master
- **Release Process**: GitHub releases trigger automatic publishing to pub.dev
- **Contributor Recognition**: Uses AllContributors format for tracking contributions

## Domain Context

### WebRTC and Janus Server
This package interfaces with **Janus WebRTC Server**, a general-purpose WebRTC gateway. Key domain concepts:

- **Janus Server**: Standalone WebRTC media server supporting multiple plugins
- **Plugins**: Modular functionality (VideoRoom, VideoCall, SIP, Streaming, AudioBridge, TextRoom, EchoTest)
- **Transport Protocols**: REST HTTP API with long-polling or WebSocket for real-time events
- **Unified Plan**: WebRTC SDP semantics for modern browser compatibility
- **Sessions**: Persistent connections to Janus server with state management
- **Handles**: Plugin-specific handles for operations

### Plugin Types
- **VideoRoom**: Multi-party video conferencing (like Zoom/Meet)
- **VideoCall**: Peer-to-peer WebRTC calls
- **SIP**: VoIP integration with SIP providers
- **Streaming**: Media streaming (live broadcasting)
- **AudioBridge**: Audio-only conferencing/mixing
- **TextRoom**: Real-time text chat functionality
- **EchoTest**: Connection testing and media validation

## Important Constraints

### Technical Constraints
- **Flutter Platform Limitations**: WebRTC capabilities vary by platform (iOS/desktop limitations)
- **Network Requirements**: Requires proper network configuration for WebRTC (STUN/TURN servers)
- **Janus Server Dependency**: External Janus server required (not embedded)
- **Browser Compatibility**: Modern browsers supporting WebRTC APIs
- **Memory Management**: Proper cleanup of WebRTC resources to prevent leaks

### Business Constraints
- **Open Source**: MIT license, community-driven development
- **Pub.dev Publishing**: Must follow pub.dev packaging and versioning guidelines
- **Backward Compatibility**: Semantic versioning for stable API
- **Platform Support**: Maintains cross-platform compatibility where possible

### Performance Constraints
- **Real-time Requirements**: Low-latency audio/video processing
- **Resource Usage**: Efficient memory and CPU usage for mobile devices
- **Network Efficiency**: Optimized for mobile network conditions
- **Battery Life**: Consider power consumption for mobile applications

## External Dependencies

### Janus Server
- **Requirement**: External Janus WebRTC Server deployment
- **Configuration**: Requires proper Janus server setup with enabled plugins
- **Network**: Configurable server URLs and transport preferences

### WebRTC Infrastructure
- **STUN/TURN Servers**: Required for NAT traversal and connectivity
- **ICE Framework**: Interactive Connectivity Establishment for peer connections
- **Media Codecs**: Platform-specific codec support (VP8, VP9, H.264, Opus)

### Platform-Specific
- **Flutter SDK**: Version constraints as specified in pubspec.yaml
- **Native SDKs**: iOS SDK, Android SDK for mobile deployment
- **Browser APIs**: WebRTC APIs for web platform support

### Development Infrastructure
- **GitHub**: Source control, issue tracking, releases
- **pub.dev**: Package distribution and dependency management
- **GitHub Actions**: Continuous integration and deployment
