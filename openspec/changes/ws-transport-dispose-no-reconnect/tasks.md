## 1. Transport Lifecycle Fix

- [x] 1.1 Add a disposal state (`_disposed`) to `WebSocketJanusTransport` and set it at the start of `dispose()`
- [x] 1.2 Replace reconnect `Future.delayed(...)` with a cancellable `Timer` stored on the transport
- [x] 1.3 Cancel heartbeat timer and reconnect timer in `dispose()`; ensure dispose clears connection references deterministically
- [x] 1.4 Guard `connect()`, `_startHeartbeat()`, and `_handleDisconnect()` so they no-op when disposed

## 2. Pending Work Cleanup

- [x] 2.1 On `dispose()`, complete all in-flight `send()` transactions with a deterministic error (e.g. `StateError("Transport disposed")`), clear `_pendingTransactions`, and reject future `send()` calls with the same error
- [x] 2.2 Ensure `_pendingTransactions` does not leak entries on `dispose()` (for non-dispose disconnects, keep the existing timeout behavior unless explicitly changed)

## 3. Tests

- [x] 3.1 Add a unit test that calls `dispose()` and asserts no reconnect attempt occurs (no new channel created) even if stream emits `onDone`
- [x] 3.2 Add a unit test that schedules reconnect, then calls `dispose()` and asserts the reconnect timer is canceled
- [x] 3.3 Add a unit test that verifies heartbeat stops after dispose (no more ping writes)
- [x] 3.4 Implement tests using the dev Janus endpoint `ws://10.17.1.31:8188/ws` and always run them (network-dependent; expect failures outside the dev network)

## 4. Documentation

- [x] 4.1 Document the new lifecycle guarantee: `dispose()` is terminal and suppresses auto-reconnect
- [x] 4.2 Add a short note at the top of `CHANGELOG.md` (next version section) describing the behavior change and recommended app-level reconnect policy
