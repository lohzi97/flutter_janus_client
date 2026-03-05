# ws-transport-lifecycle Specification

## Purpose
This specification defines the lifecycle behavior of WebSocketJanusTransport, including connection management, auto-reconnect, heartbeat, and terminal disposal semantics.

## Requirements

### Requirement: Dispose is terminal
After `WebSocketJanusTransport.dispose()` is called, the transport SHALL enter a terminal disposed state.

#### Scenario: Dispose prevents reconnect scheduling
- **WHEN** the transport is connected and `dispose()` is called
- **THEN** the transport SHALL NOT schedule any auto-reconnect attempt

#### Scenario: Dispose cancels a pending reconnect
- **WHEN** an auto-reconnect attempt has been scheduled but not yet executed
- **THEN** calling `dispose()` SHALL cancel the pending reconnect attempt

#### Scenario: Dispose prevents future connect calls
- **WHEN** `dispose()` has been called
- **THEN** calling `connect()` SHALL NOT create a new WebSocket connection

### Requirement: Dispose suppresses heartbeat traffic
After `dispose()` is called, the transport SHALL NOT emit heartbeat ping messages.

#### Scenario: Heartbeat stops after dispose
- **WHEN** heartbeat is running and `dispose()` is called
- **THEN** no further heartbeat pings SHALL be sent

### Requirement: Intentional close does not trigger recovery
An intentional shutdown caused by `dispose()` SHALL NOT be treated as a disconnect requiring recovery.

#### Scenario: Stream onDone after dispose does not reconnect
- **WHEN** `dispose()` closes the WebSocket and the stream reports `onDone`
- **THEN** the transport SHALL NOT attempt to reconnect

#### Scenario: Stream onError after dispose does not reconnect
- **WHEN** `dispose()` is called and the stream later reports `onError`
- **THEN** the transport SHALL NOT attempt to reconnect

### Requirement: Dispose fails pending transactions
After `dispose()` is called, any in-flight transactions created by `send()` SHALL be failed deterministically and removed from the transport's pending transaction tracking.

#### Scenario: Pending send completes with error on dispose
- **GIVEN** one or more `send()` calls are in-flight (awaiting a response)
- **WHEN** `dispose()` is called
- **THEN** those `send()` futures SHALL complete with an error (not wait for `sendCompleterTimeout`)

#### Scenario: Send after dispose fails immediately
- **WHEN** `dispose()` has been called
- **THEN** calling `send()` SHALL fail immediately with a deterministic error
