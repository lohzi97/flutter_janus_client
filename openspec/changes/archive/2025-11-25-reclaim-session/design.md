# Session Reclamation Design

## Architectural Overview

Session reclamation leverages Janus Server's built-in session persistence mechanism to provide seamless recovery from network interruptions. The design maintains backward compatibility while adding reclamation capabilities through existing session creation interfaces.

## Key Design Decisions

### 1. API Design: Optional Parameter Approach
**Decision**: Extend `JanusSession.create()` with optional `sessionId` parameter rather than creating separate `claim()` method.

**Rationale**:
- Cleaner API surface - single method handles both creation and reclamation
- Backward compatible - existing code unchanged
- Intuitive - reclamation is conceptually "creating" a session instance
- Consistent with Janus protocol flow

### 2. Transport Layer Abstraction
**Decision**: Handle reclamation logic at session level, not transport level.

**Rationale**:
- Session reclamation is a session-level concern
- Transport layer focuses on protocol communication
- Maintains clean separation of concerns
- Works with both WebSocket and REST transports transparently

### 3. Client-Side State Management
**Decision**: Application handles session ID persistence and plugin handle restoration.

**Rationale**:
- Application knows best how/where to persist session state
- Different applications have different persistence requirements
- Plugin handles are application-managed objects
- Avoids making assumptions about application architecture

## Implementation Architecture

### Session Reclamation Flow
```
Application detects disconnection
    ↓
Application stores session ID (before disconnect)
    ↓
Application handles network reconnection
    ↓
Application calls: session.create(sessionId: storedId)
    ↓
Session layer sends claim request to server
    ↓
Server responds with success/error
    ↓
Session layer restarts keep-alive timers
    ↓
Application re-attaches to known plugin handles
    ↓
Normal operation resumes
```

### Error Handling Strategy
- **Success**: Return full Janus response, restart keep-alive
- **Session Not Found**: Throw `SessionReclaimException`
- **Invalid Session ID**: Throw `SessionReclaimException`
- **Network Errors**: Propagate existing transport exceptions
- **Server Errors**: Include Janus error details in exception

### State Management
**Session Layer Responsibility**:
- Send claim/create requests based on sessionId parameter
- Restart keep-alive timers after successful reclamation
- Maintain session ID in existing `_sessionId` field
- Clear error handling and exception propagation

**Application Responsibility**:
- Store session ID before potential disconnection
- Handle network reconnection logic
- Re-attach to plugin handles after reclamation
- Handle reclamation failures gracefully

## Technical Considerations

### WebSocket Transport
- Claim requests use existing WebSocket connection
- Transaction management handles claim responses
- Connection state managed by application

### REST Transport
- Claim requests sent to existing REST endpoints
- Uses same HTTP POST mechanism as other requests
- Session ID included in request path like normal operations

### Keep-Alive Management
- Automatic restart after successful claim
- Uses existing `_keepAlive()` method
- Respects existing refresh interval settings
- Handles claim session ID correctly

### Backward Compatibility
- Existing `createSession()` calls unchanged
- No breaking changes to public APIs
- New functionality is entirely opt-in
- No changes to plugin interfaces

## Security Considerations

### Session ID Protection
- Applications must protect stored session IDs
- Session IDs are sensitive authentication tokens
- Recommend secure storage mechanisms
- Consider session ID expiration policies

### Claim Request Validation
- Server validates session ID authenticity
- Invalid session IDs are rejected appropriately
- Rate limiting considerations for repeated claim attempts

### Error Information Exposure
- Error messages from server propagated appropriately
- No sensitive server configuration leaked
- Clear distinction between client and server errors

## Performance Impact

### Minimal Overhead
- Single additional request for reclamation vs creation
- No additional persistent state management
- Keep-alive timer restart uses existing mechanism
- No memory or performance penalties for existing flows

### Network Efficiency
- Eliminates need for full session recreation
- Reduces plugin handle re-attachment overhead
- Faster recovery from temporary disconnections
- Better user experience in unstable network conditions

## Future Extensibility

### Extension Points
- Session reclamation callback mechanisms
- Automatic reconnection strategies
- Enhanced error recovery workflows
- Session state synchronization utilities

### Compatibility with Future Features
- Works with existing plugin ecosystem
- Compatible with future transport protocols
- Extensible to additional session management features
- No conflicts with planned enhancements