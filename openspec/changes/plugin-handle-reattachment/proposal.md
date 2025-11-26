# Change: Add Plugin Handle Re-attachment Support

## Why
Enable the "abandon and reclaim" flow where applications can disconnect from Janus sessions and later reclaim both the session AND existing plugin handles to control ongoing operations (like active SIP calls). This capability is critical for mobile apps that need to handle incoming calls in background isolates then transfer control to the main UI isolate.

## What Changes
- Extend `JanusSession.attach<T>()` method to support optional `existingHandleId` parameter
- Add plugin re-attachment capability without sending new "attach" requests to Janus
- Maintain full backward compatibility with existing plugin attachment behavior
- Enable control over existing plugin handles after session reclamation

## Impact
- **Affected specs**: session-reclamation (extension)
- **Affected code**: `lib/janus_session.dart` (primary), plugin wrapper classes
- **Key benefit**: Completes the "abandon and reclaim" flow for background/foreground isolate communication
- **Breaking changes**: None (fully backward compatible)