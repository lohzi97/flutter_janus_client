# Session Reclamation Support

## Problem Statement

The Flutter Janus client currently lacks support for session reclamation functionality provided by the Janus WebRTC Server. When network connections are interrupted (common in mobile VoIP applications), users lose their active sessions and must restart entire communication flows, creating poor user experience.

Current limitations:
- No way to reclaim existing Janus sessions after connection loss
- Applications must recreate sessions and re-attach all plugin handles after disconnection
- No built-in support for handling network interruptions gracefully
- VoIP calls are permanently dropped on temporary connection issues

## Scope

This change adds session reclamation capability to allow applications to:
- Reclaim existing Janus sessions using a stored session ID
- Maintain session state across connection interruptions
- Automatically restart keep-alive mechanisms for reclaimed sessions
- Support both WebSocket and REST transport protocols

## Out of Scope

- Automatic session ID persistence (applications handle storage)
- Network connection management (applications handle reconnection logic)
- Automatic plugin handle restoration (applications re-attach to known handles)
- Server-side session timeout configuration changes

## Success Criteria

1. Applications can successfully reclaim Janus sessions using existing session IDs
2. Reclaimed sessions automatically restart keep-alive timers
3. Error handling provides clear feedback when reclamation fails
4. Both WebSocket and REST transports support session reclamation
5. Existing createSession API remains backward compatible
6. Reclaimed sessions can be used normally for all plugin operations

## Dependencies

- Janus server with `reclaim_session_timeout` configured
- Applications must store session ID before potential disconnection
- Applications must handle network reconnection before attempting reclamation

## Implementation Approach

Modify `JanusSession.create()` to accept an optional `sessionId` parameter:
- When provided: send `claim` request instead of `create` request
- When not provided: use existing `create` request behavior
- Automatically restart keep-alive timers for successful reclamation
- Return full Janus response for application error handling

## Risk Analysis

**Low Risk**: Changes are additive and maintain backward compatibility.
- Existing `createSession()` calls continue to work unchanged
- New functionality is opt-in via optional parameter
- Clear error messages for failed reclamation attempts
- No changes to plugin or transport interfaces beyond session creation