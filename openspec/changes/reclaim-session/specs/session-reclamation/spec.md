# Session Reclamation Capability Specification

## ADDED Requirements

### Requirement: Session Reclamation Support
The package SHALL support reclaiming existing Janus sessions using stored session IDs to enable recovery from network interruptions.

#### Scenario: Successful Session Reclamation
**Given** an application has a stored Janus session ID from a previous session
**When** the application calls `session.create(sessionId: storedSessionId)`
**Then** the package SHALL send a claim request to the Janus server
**And** SHALL return the server response if the reclamation is successful
**And** SHALL automatically restart keep-alive timers for the reclaimed session

#### Scenario: Session Reclamation Failure - Session Not Found
**Given** an application provides a session ID that no longer exists on the server
**When** the application calls `session.create(sessionId: invalidSessionId)`
**Then** the package SHALL throw a `SessionReclaimException`
**And** the exception SHALL contain the error details from the Janus server

#### Scenario: Session Reclamation Failure - Server Error
**Given** the Janus server returns an error response during session reclamation
**When** the application calls `session.create(sessionId: validSessionId)`
**Then** the package SHALL throw a `SessionReclaimException`
**And** the exception SHALL include the server error code and message

### Requirement: Backward Compatible Session Creation
The package SHALL maintain full backward compatibility with existing session creation functionality.

#### Scenario: Existing Session Creation Unchanged
**Given** an application calls `session.create()` without a sessionId parameter
**When** the method executes
**Then** it SHALL behave exactly as before the reclamation feature was added
**And** SHALL send a create request to the Janus server
**And** SHALL not attempt session reclamation

#### Scenario: Optional Session ID Parameter
**Given** an application calls `session.create(sessionId: optionalSessionId)`
**When** `optionalSessionId` is null
**Then** the method SHALL treat it as a normal session creation request
**And** SHALL not attempt session reclamation

### Requirement: Transport Protocol Support
Session reclamation SHALL work with both WebSocket and REST transport protocols.

#### Scenario: WebSocket Transport Reclamation
**Given** an application uses WebSocketJanusTransport
**When** the application calls `session.create(sessionId: storedSessionId)`
**Then** the claim request SHALL be sent over the WebSocket connection
**And** the response SHALL be handled through WebSocket message processing

#### Scenario: REST Transport Reclamation
**Given** an application uses RestJanusTransport
**When** the application calls `session.create(sessionId: storedSessionId)`
**Then** the claim request SHALL be sent as an HTTP POST request
**And** the response SHALL be processed through the existing HTTP response handling

### Requirement: Keep-Alive Timer Management
The package SHALL automatically manage keep-alive timers for reclaimed sessions.

#### Scenario: Keep-Alive Timer Restart
**Given** a session is successfully reclaimed
**When** the reclamation succeeds
**Then** the package SHALL automatically restart the keep-alive timer
**And** the timer SHALL use the existing refresh interval configuration
**And** the timer SHALL send keep-alive requests using the reclaimed session ID

#### Scenario: Keep-Alive Timer Configuration
**Given** an application has configured a custom refresh interval
**When** a session is reclaimed
**Then** the keep-alive timer SHALL use the application's configured interval
**And** SHALL respect all existing keep-alive configuration settings

### Requirement: Error Handling and Exceptions
The package SHALL provide clear error handling for session reclamation scenarios.

#### Scenario: Session Reclaim Exception Creation
**Given** a session reclamation attempt fails
**When** handling the failure
**Then** the package SHALL create a `SessionReclaimException`
**And** the exception SHALL contain the original error message from the server
**And** the exception SHALL include the session ID that failed to reclaim

#### Scenario: Network Error Propagation
**Given** a network error occurs during session reclamation
**When** the error happens
**Then** the package SHALL propagate the underlying transport exception
**And** SHALL not wrap transport errors in `SessionReclaimException`

### Requirement: API Documentation and Examples
The package SHALL provide clear documentation and examples for session reclamation usage.

#### Scenario: Documentation Coverage
**Given** the session reclamation feature is implemented
**When** developers consult the package documentation
**Then** it SHALL include session reclamation usage examples
**And** SHALL document error handling patterns
**And** SHALL explain server-side requirements (reclaim_session_timeout)

#### Scenario: Usage Example Integration
**Given** the package examples are updated
**When** developers review the example applications
**Then** at least one example SHALL demonstrate session reclamation
**And** SHALL show proper error handling
**And** SHALL include best practices for session ID management

## MODIFIED Requirements

### Requirement: JanusSession.create() Method Signature
The `JanusSession.create()` method signature SHALL be modified to support optional session ID parameter.

**Current Signature**: `Future<void> create()`
**New Signature**: `Future<void> create({int? sessionId})`

#### Scenario: Method Signature Compatibility
**Given** existing code calls `session.create()`
**When** the code is compiled with the new version
**Then** it SHALL compile without changes
**And** SHALL maintain the same behavior

## REMOVED Requirements

No requirements are removed as this is a purely additive change that maintains backward compatibility.