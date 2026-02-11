## 1. Implementation
- [x] 1.1 Modify JanusSession.create() Method Signature
- [x] 1.2 Implement Session Reclamation Logic
- [x] 1.3 Update WebSocket Transport for Claim Support
- [x] 1.4 Update REST Transport for Claim Support
- [x] 1.5 Implement Keep-Alive Timer Restart
- [x] 1.6 Add Error Handling and Exceptions
- [x] 1.7 Update JanusClient Documentation
- [x] 1.8 Create Integration Tests
- [x] 1.9 Create Usage Examples
- [x] 1.10 Final Validation and Testing

## Task Details

### 1.1 Modify JanusSession.create() Method Signature
Add optional `sessionId` parameter to support session reclamation
- **Files**: `lib/janus_session.dart`
- **Verification**: Method signature is backward compatible

### 1.2 Implement Session Reclamation Logic
Add claim request logic when sessionId parameter is provided
- **Files**: `lib/janus_session.dart`
- **Details**:
  - Check if sessionId parameter is provided
  - Send `{"janus": "claim", "session_id": sessionId}` request
  - Handle success and error responses appropriately
- **Verification**: Reclamation works with valid existing session IDs

### 1.3 Update WebSocket Transport for Claim Support
Ensure WebSocket transport can handle claim requests properly
- **Files**: `lib/janus_transport.dart`
- **Details**:
  - Verify claim requests work with WebSocket connection management
  - Ensure proper transaction handling for claim responses
- **Verification**: Claim requests work over WebSocket transport

### 1.4 Update REST Transport for Claim Support
Ensure REST transport can handle claim requests properly
- **Files**: `lib/janus_transport.dart`
- **Details**:
  - Verify claim requests work with HTTP POST endpoints
  - Ensure proper error handling for claim responses
- **Verification**: Claim requests work over REST transport

### 1.5 Implement Keep-Alive Timer Restart
Automatically restart keep-alive timers after successful session reclamation
- **Files**: `lib/janus_session.dart`
- **Details**:
  - Call `_keepAlive()` method after successful claim
  - Ensure timer uses correct session ID
- **Verification**: Keep-alive requests continue after reclamation

### 1.6 Add Error Handling and Exceptions
Create specific exceptions for session reclamation failures
- **Files**: `lib/janus_session.dart` (and potentially new exception file)
- **Details**:
  - Create `SessionReclaimException` for failed reclamation attempts
  - Provide clear error messages from Janus server responses
- **Verification**: Clear exceptions thrown when reclamation fails

### 1.7 Update JanusClient Documentation
Document new session reclamation functionality
- **Files**: `README.md`, inline documentation
- **Details**:
  - Add session reclamation usage examples
  - Document error handling patterns
  - Explain server requirements (reclaim_session_timeout)
- **Verification**: Documentation is clear and complete

### 1.8 Create Integration Tests
Add tests to verify session reclamation functionality
- **Files**: `test/` directory
- **Details**:
  - Test successful session reclamation
  - Test reclamation failure scenarios
  - Test keep-alive timer restart
  - Test with both WebSocket and REST transports
- **Verification**: All tests pass and cover reclamation scenarios

### 1.9 Create Usage Examples
Add practical examples showing session reclamation usage
- **Files**: `example/` directory
- **Details**:
  - VoIP call reconnection example
  - Video room session recovery example
  - Error handling best practices example
- **Verification**: Examples work and demonstrate reclamation clearly

### 1.10 Final Validation and Testing
Complete integration testing and validation
- **Files**: All modified files for final polish
- **Details**:
  - End-to-end testing with real Janus server
  - Performance impact assessment
  - Backward compatibility verification
- **Verification**: Feature works as specified without breaking existing functionality