## Session Reclamation

The Flutter Janus client now supports session reclamation functionality, allowing applications to recover from network interruptions by reclaiming existing Janus sessions instead of creating new ones.

### Features
- **Session Persistence**: Maintain session state across network interruptions
- **Automatic Keep-Alive**: Reclaimed sessions automatically restart keep-alive timers
- **Transport Agnostic**: Works with both WebSocket and REST transports
- **Backward Compatible**: Existing `createSession()` calls continue to work unchanged

### Usage

```dart
// Store session ID before potential disconnection
int? storedSessionId;

// Create a new session
await session.create();
storedSessionId = session.sessionId;

// Later, after network reconnection, reclaim the session
try {
  await session.create(sessionId: storedSessionId);
  print('Session reclaimed successfully!');
} on SessionReclaimException catch (e) {
  print('Failed to reclaim session: $e');
  // Fallback to creating a new session
  await session.create();
}
```

### Server Requirements

Session reclamation requires a Janus server with `reclaim_session_timeout` configured. This timeout determines how long the server will keep a session available for reclamation after disconnection.

### Error Handling

```dart
try {
  await session.create(sessionId: sessionId);
} on SessionReclaimException catch (e) {
  // Handle reclamation failure
  if (e.message.contains('458')) {
    // Session not found - may have expired
    print('Session expired, creating new session');
  } else {
    // Other reclamation errors
    print('Reclamation failed: ${e.message}');
  }
}
```