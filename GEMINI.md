### Project Overview

This project is a Flutter package named `janus_client`. It provides a client for the Janus WebRTC server, enabling developers to integrate WebRTC functionalities into their Flutter applications. The package supports various Janus plugins, including Video Room, Audio Bridge, SIP, and more. It offers both REST and WebSocket transport options for communicating with the Janus server.

The project is well-documented, with a `README.md` file that provides a comprehensive overview, an API reference, a wiki, and a demo. It also includes a detailed example application that showcases the usage of different plugins.

### Building and Running

To use the `janus_client` package in a Flutter project, add it as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  janus_client: ^2.3.13
```

Then, run `flutter pub get` to install the package.

The example application can be run by navigating to the `example` directory and executing `flutter run`. The `example/lib/main.dart` file serves as the entry point for the example app, with different routes for various features.

### Development Conventions

The project follows standard Dart and Flutter conventions. It uses `flutter_webrtc` for WebRTC functionality, `http` for REST API communication, and `web_socket_channel` for WebSocket communication. The code is organized into several files, with a main `janus_client.dart` file that serves as the entry point for the library. The project also includes a comprehensive test suite in the `test` directory.

The library uses a `JanusClient` class to manage the connection to the Janus server and a `JanusSession` class to handle sessions. Each Janus plugin is wrapped in its own class, providing a clean and organized API for developers. The project also uses typed events for handling messages from the Janus server, which allows for better IDE support and a more robust development experience.
