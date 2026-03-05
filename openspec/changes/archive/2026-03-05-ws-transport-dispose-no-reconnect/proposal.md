## Why

When Janus (or the network) is unhealthy, clients can enter a reconnect storm that worsens server overload. In the current WebSocket transport, calling `dispose()` can still trigger the internal auto-reconnect loop (via stream `onDone`/`onError`), so higher-level code cannot reliably stop reconnection attempts.

This change makes transport shutdown deterministic: once disposed, the transport must never reconnect or emit network traffic.

## What Changes

- `WebSocketJanusTransport.dispose()` becomes a terminal state: it prevents any scheduled/automatic reconnect attempts and stops heartbeats.
- Disconnect handling (`_handleDisconnect`) becomes disposal-aware and exits immediately when the transport is disposed.
- Any pending reconnect delay is cancellable so a previously scheduled reconnect cannot run after disposal.
- When `dispose()` occurs, in-flight and future `send()` calls fail deterministically (pending transactions are completed with an error and cleared).
- Add a small amount of state/telemetry (internal flags/logs) to clarify whether a disconnect is intentional (dispose) vs. unintentional.

## Capabilities

### New Capabilities
- `ws-transport-lifecycle`: Defines lifecycle requirements for WebSocket transport (connect/disconnect/reconnect/heartbeat) with a strict guarantee that `dispose()` is final and suppresses auto-reconnect.

### Modified Capabilities

## Impact

- Affected code: `lib/janus_transport.dart` (`WebSocketJanusTransport` reconnect/heartbeat/dispose paths).
- Runtime behavior: fewer reconnection attempts during app-driven teardown; reduced risk of reconnect storms during server overload.
- API surface: no breaking API required; behavior change is in lifecycle semantics (dispose becomes reliably final).
