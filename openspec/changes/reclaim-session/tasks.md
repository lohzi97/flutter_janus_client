# Session Reclamation Implementation Tasks

## Ordered Implementation Tasks

### 1. Modify JanusSession.create() Method Signature
- **Description**: Add optional `sessionId` parameter to support session reclamation
- **Files to modify**: `lib/janus_session.dart`
- **Verification**: Method signature is backward compatible
- **Dependencies**: None

### 2. Implement Session Reclamation Logic
- **Description**: Add claim request logic when sessionId parameter is provided
- **Files to modify**: `lib/janus_session.dart`
- **Details**:
  - Check if sessionId parameter is provided
  - Send `{"janus": "claim", "session_id": sessionId}` request
  - Handle success and error responses appropriately
- **Verification**: Reclamation works with valid existing session IDs
- **Dependencies**: Task 1

### 3. Update WebSocket Transport for Claim Support
- **Description**: Ensure WebSocket transport can handle claim requests properly
- **Files to modify**: `lib/janus_transport.dart`
- **Details**:
  - Verify claim requests work with WebSocket connection management
  - Ensure proper transaction handling for claim responses
- **Verification**: Claim requests work over WebSocket transport
- **Dependencies**: Task 2

### 4. Update REST Transport for Claim Support
- **Description**: Ensure REST transport can handle claim requests properly
- **Files to modify**: `lib/janus_transport.dart`
- **Details**:
  - Verify claim requests work with HTTP POST endpoints
  - Ensure proper error handling for claim responses
- **Verification**: Claim requests work over REST transport
- **Dependencies**: Task 2

### 5. Implement Keep-Alive Timer Restart
- **Description**: Automatically restart keep-alive timers after successful session reclamation
- **Files to modify**: `lib/janus_session.dart`
- **Details**:
  - Call `_keepAlive()` method after successful claim
  - Ensure timer uses correct session ID
- **Verification**: Keep-alive requests continue after reclamation
- **Dependencies**: Task 2

### 6. Add Error Handling and Exceptions
- **Description**: Create specific exceptions for session reclamation failures
- **Files to modify**: `lib/janus_session.dart` (and potentially new exception file)
- **Details**:
  - Create `SessionReclaimException` for failed reclamation attempts
  - Provide clear error messages from Janus server responses
- **Verification**: Clear exceptions thrown when reclamation fails
- **Dependencies**: Task 2

### 7. Update JanusClient Documentation
- **Description**: Document new session reclamation functionality
- **Files to modify**: `README.md`, inline documentation
- **Details**:
  - Add session reclamation usage examples
  - Document error handling patterns
  - Explain server requirements (reclaim_session_timeout)
- **Verification**: Documentation is clear and complete
- **Dependencies**: Task 6

### 8. Create Integration Tests
- **Description**: Add tests to verify session reclamation functionality
- **Files to modify**: `test/` directory
- **Details**:
  - Test successful session reclamation
  - Test reclamation failure scenarios
  - Test keep-alive timer restart
  - Test with both WebSocket and REST transports
- **Verification**: All tests pass and cover reclamation scenarios
- **Dependencies**: Task 6

### 9. Create Usage Examples
- **Description**: Add practical examples showing session reclamation usage
- **Files to modify**: `example/` directory
- **Details**:
  - VoIP call reconnection example
  - Video room session recovery example
  - Error handling best practices example
- **Verification**: Examples work and demonstrate reclamation clearly
- **Dependencies**: Task 6

### 10. Final Validation and Testing
- **Description**: Complete integration testing and validation
- **Files to modify**: All modified files for final polish
- **Details**:
  - End-to-end testing with real Janus server
  - Performance impact assessment
  - Backward compatibility verification
- **Verification**: Feature works as specified without breaking existing functionality
- **Dependencies**: Task 9