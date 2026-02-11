# Plugin Handle Re-attachment Documentation

## Overview

The plugin handle re-attachment feature enables the "abandon and reclaim" flow where applications can disconnect from Janus sessions and later reclaim both the session AND existing plugin handles to control ongoing operations (like active SIP calls). This capability is critical for mobile apps that need to handle incoming calls in background isolates then transfer control to the main UI isolate.

## API Documentation

### JanusSession.attach<T>() Method

The `attach<T>()` method has been extended to support an optional `existingHandleId` parameter:

```dart
Future<T> attach<T extends JanusPlugin>({
  String? opaqueId,
  int? existingHandleId,
}) async
```

#### Parameters

- **`opaqueId`** (optional, `String?`): Opaque ID is an optional string identifier used for client side correlations in event handlers or admin API.
- **`existingHandleId`** (optional, `int?`): Existing handle ID for re-attaching to a previously created plugin handle without sending a new "attach" request to Janus.

#### Return Value

- Returns a `Future<T>` that resolves to the plugin instance of the specified type.

#### Behavior

- **When `existingHandleId` is `null` or not provided**: Normal plugin attachment flow. Sends an "attach" request to Janus and creates a new plugin handle.
- **When `existingHandleId` is provided**: Re-attachment flow. Skips the "attach" request to Janus and creates a plugin instance that controls the existing handle.

#### Validation

- Throws `StateError` if the session is not active when attempting any attachment (normal or re-attachment).

## Usage Examples

### Basic Re-attachment

```dart
// Create a session and plugin handle (e.g., in background isolate)
final session = await janusClient.createSession();
final sipPlugin = await session.attach<JanusSipPlugin>();
final handleId = sipPlugin.handleId; // Save this for later

// Later (e.g., in main isolate), reclaim the session and re-attach
final reclaimedSession = await janusClient.createSession(sessionId: session.sessionId);
final reattachedSipPlugin = await reclaimedSession.attach<JanusSipPlugin>(
  existingHandleId: handleId,
);

// Continue using the plugin (e.g., answer an incoming call)
await reattachedSipPlugin.accept();
```

### Session Reclamation + Plugin Re-attachment Complete Flow

```dart
import 'dart:isolate';
import 'package:janus_client/janus_client.dart';

// Background isolate - handles incoming calls
void backgroundIsolate(SendPort sendPort) async {
  final janusClient = JanusClient(
    transport: WebSocketJanusTransport(url: 'ws://localhost:8188'),
  );

  try {
    // Create session and SIP plugin for handling incoming calls
    final session = await janusClient.createSession();
    final sipPlugin = await session.attach<JanusSipPlugin>();

    // Register for incoming calls
    sipPlugin.events!.listen((event) {
      if (event is IncomingcallEvent) {
        // Send session and handle info to main isolate
        sendPort.send({
          'sessionId': session.sessionId,
          'handleId': sipPlugin.handleId,
          'callerId': event.callerId,
        });
      }
    });

    // Start SIP registration to receive calls
    await sipPlugin.register(
      username: 'sip-user',
      password: 'sip-password',
      proxy: 'sip.provider.com',
    );

  } catch (e) {
    sendPort.send({'error': e.toString()});
  }
}

// Main isolate - UI application
void main() async {
  final receivePort = ReceivePort();
  await Isolate.spawn(backgroundIsolate, receivePort.sendPort);

  receivePort.listen((message) async {
    if (message.containsKey('error')) {
      print('Background isolate error: ${message['error']}');
      return;
    }

    if (message.containsKey('sessionId')) {
      // Reclaim session and re-attach to existing SIP handle
      final janusClient = JanusClient(
        transport: WebSocketJanusTransport(url: 'ws://localhost:8188'),
      );

      try {
        // Reclaim existing session
        final session = await janusClient.createSession(
          sessionId: message['sessionId'],
        );

        // Re-attach to existing SIP plugin handle
        final sipPlugin = await session.attach<JanusSipPlugin>(
          existingHandleId: message['handleId'],
        );

        // Show incoming call UI
        await _showIncomingCallUI(
          callerId: message['callerId'],
          sipPlugin: sipPlugin,
        );

      } catch (e) {
        print('Failed to reclaim session: $e');
      }
    }
  });
}

Future<void> _showIncomingCallUI({
  required String callerId,
  required JanusSipPlugin sipPlugin,
}) async {
  // UI logic to show incoming call dialog
  // User can choose to accept or decline

  // Accept the call using re-attached plugin
  await sipPlugin.accept();

  // When call ends, clean up
  await sipPlugin.hangup();
}
```

### VideoRoom Plugin Re-attachment

```dart
// In background service - handle room monitoring
Future<void> monitorVideoRoom() async {
  final janusClient = JanusClient(
    transport: WebSocketJanusTransport(url: 'ws://localhost:8188'),
  );

  final session = await janusClient.createSession();
  final videoRoomPlugin = await session.attach<JanusVideoRoomPlugin>();

  // Monitor room participants
  videoRoomPlugin.events!.listen((event) {
    if (event is ParticipantJoinedEvent) {
      // Save session and handle for UI takeover
      _saveSessionInfo(session.sessionId!, videoRoomPlugin.handleId!);
    }
  });
}

// In UI foreground - take over control
Future<void> takeOverVideoRoom(int sessionId, int handleId) async {
  final janusClient = JanusClient(
    transport: WebSocketJanusTransport(url: 'ws://localhost:8188'),
  );

  // Reclaim session
  final session = await janusClient.createSession(sessionId: sessionId);

  // Re-attach to existing VideoRoom handle
  final videoRoomPlugin = await session.attach<JanusVideoRoomPlugin>(
    existingHandleId: handleId,
  );

  // Continue room operations (e.g., publish/subscribe)
  await videoRoomPlugin.join(roomId: 1234);
}
```

## Error Handling Patterns

### Session Not Active

```dart
try {
  final plugin = await session.attach<JanusSipPlugin>(
    existingHandleId: 123456,
  );
} on StateError catch (e) {
  print('Session validation failed: ${e.message}');
  // Handle session not active scenario
  // Consider creating a new session or handling the error gracefully
}
```

### Invalid Handle ID

```dart
try {
  final plugin = await session.attach<JanusSipPlugin>(
    existingHandleId: invalidHandleId,
  );
  // Use plugin...

} catch (e) {
  // Handle potential invalid handle ID errors
  // These would typically come from Janus server during plugin operations
  print('Plugin operation failed: $e');
}
```

### Transport Errors

```dart
try {
  final session = await janusClient.createSession(sessionId: sessionId);
  final plugin = await session.attach<JanusSipPlugin>(
    existingHandleId: handleId,
  );
} catch (e) {
  // Handle transport-level errors (connection issues, timeouts, etc.)
  print('Transport error during re-attachment: $e');
  // Consider retry logic or fallback to normal attachment
}
```

## When to Use Re-attachment vs Normal Attachment

### Use Re-attachment When:

1. **Background to Foreground Transfer**: Moving control from a background isolate to the main UI isolate
2. **Process Recovery**: Restarting an application and reconnecting to existing sessions
3. **Multi-Process Architecture**: Different processes or components need to share control of the same plugin
4. **State Preservation**: Maintaining ongoing operations (active calls, streaming, etc.) across application lifecycle changes

### Use Normal Attachment When:

1. **New Plugin Instances**: Creating fresh plugin handles for new operations
2. **Initial Setup**: First-time plugin creation for a session
3. **Plugin Replacement**: Replacing a failed or disposed plugin handle
4. **Standard Flow**: Normal application workflow without cross-process coordination

## Best Practices

### 1. Save Session and Handle Information

```dart
// When creating initial session and plugins
final session = await janusClient.createSession();
final sipPlugin = await session.attach<JanusSipPlugin>();

// Save for later re-attachment
final sessionInfo = {
  'sessionId': session.sessionId,
  'handleId': sipPlugin.handleId,
  'pluginType': 'JanusSipPlugin',
};
await _persistSessionInfo(sessionInfo);
```

### 2. Validate Session Before Re-attachment

```dart
Future<bool> _isSessionStillActive(int sessionId) async {
  try {
    // Try to ping the session
    await janusClient.getInfo();
    return true;
  } catch (e) {
    return false;
  }
}
```

### 3. Handle Re-attachment Failures Gracefully

```dart
Future<JanusSipPlugin?> reattachSipPlugin(int sessionId, int handleId) async {
  try {
    final session = await janusClient.createSession(sessionId: sessionId);
    return await session.attach<JanusSipPlugin>(
      existingHandleId: handleId,
    );
  } catch (e) {
    print('Re-attachment failed: $e');

    // Fallback: create new session and plugin
    try {
      final newSession = await janusClient.createSession();
      return await newSession.attach<JanusSipPlugin>();
    } catch (fallbackError) {
      print('Fallback also failed: $fallbackError');
      return null;
    }
  }
}
```

### 4. Clean Up Resources Appropriately

```dart
// When done with re-attached plugins
await reattachedPlugin.dispose();
await session.dispose();
```

## Plugin-Specific Considerations

### SIP Plugin
- **Call Continuity**: Re-attachment preserves ongoing calls
- **Registration Status**: SIP registration remains active
- **Media Streams**: Audio/video streams continue seamlessly

### VideoRoom Plugin
- **Publisher State**: Publishing status is maintained
- **Subscription State**: Active subscriptions continue
- **Participant Lists**: Room participant tracking persists

### Streaming Plugin
- **Mount Points**: Active streaming sessions continue
- **Media State**: Audio/video streaming is uninterrupted
- **Watch State**: Watching/reading status is preserved

### AudioBridge Plugin
- **Room Membership**: Active room participation continues
- **Audio State**: Audio conferencing state is maintained
- **Participant Status**: Active participant role persists

## Testing Re-attachment

The feature includes comprehensive tests that verify:

1. **Method Signature Compatibility**: All plugin types accept the `existingHandleId` parameter
2. **Session Validation**: Proper error handling when session is inactive
3. **Backward Compatibility**: Existing code continues to work without changes
4. **Null Handling**: `existingHandleId: null` behaves identically to omitting the parameter

Example test structure:
```dart
test('Re-attachment method signatures', () {
  final session = createMockSession();

  // All plugin types should accept existingHandleId
  Future<JanusSipPlugin> Function() sipFunc =
    () => session.attach<JanusSipPlugin>(existingHandleId: 123456);

  expect(sipFunc, isA<Function>());
});
```

## Migration Guide

### Existing Applications
No changes required - the feature is fully backward compatible.

### Adding Re-attachment Support
1. Save session IDs and handle IDs when creating plugins
2. Implement re-attachment logic in the target component/isolate
3. Add error handling for re-attachment failures
4. Test the complete flow with real Janus server

### Performance Considerations
- Re-attachment is more efficient than creating new plugins
- No additional network requests to Janus server
- Minimal memory overhead for plugin recreation
- Faster recovery times in background/foreground scenarios

## Troubleshooting

### Common Issues

1. **"Session is not active" Error**
   - Cause: Session was destroyed or never properly created
   - Solution: Create a new session or verify session ID is correct

2. **Invalid Handle ID**
   - Cause: Handle ID doesn't exist or has been disposed
   - Solution: Verify handle ID was saved correctly and handle still exists

3. **Plugin Operations Fail After Re-attachment**
   - Cause: Handle may have been cleaned up by Janus server
   - Solution: Implement fallback to normal plugin creation

### Debugging Tips

1. **Enable Logging**: Set appropriate log levels to monitor attachment flows
2. **Verify Session State**: Use `session.sessionId` to confirm session is active
3. **Check Handle Validity**: Verify handle IDs correspond to existing plugins
4. **Network Connectivity**: Ensure transport layer is functional before re-attachment

## Conclusion

The plugin handle re-attachment feature provides a powerful mechanism for maintaining continuous control over Janus plugin handles across application lifecycle changes. It enables sophisticated mobile app architectures, seamless background processing, and robust session recovery while maintaining full backward compatibility with existing applications.