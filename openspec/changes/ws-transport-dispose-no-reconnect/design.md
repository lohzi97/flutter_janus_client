## Context

`WebSocketJanusTransport` currently supports auto-reconnect and a periodic heartbeat ping. The transport listens to the WebSocket stream and calls `_handleDisconnect()` from `onDone`/`onError`. When application code calls `dispose()`, the transport closes the underlying sink, which can still trigger `onDone` and therefore `_handleDisconnect()`. Because `_handleDisconnect()` does not distinguish between an intentional shutdown and an unintentional network loss, the transport may schedule reconnection attempts even after disposal.

This makes it hard for higher-level code to implement its own reconnect policy and can contribute to reconnect storms during server overload.

## Goals / Non-Goals

**Goals:**
- Make `WebSocketJanusTransport.dispose()` a terminal, deterministic shutdown.
- After `dispose()` is called, the transport MUST NOT:
  - attempt to reconnect (immediately or via delayed retry)
  - emit heartbeat traffic
  - create new WebSocket channels
- Ensure a reconnect that was already scheduled cannot run after disposal.
- Preserve existing public API and defaults (behavior change only in disposal semantics).

**Non-Goals:**
- Redesigning the overall reconnect strategy (backoff/jitter/circuit breaker) beyond preventing reconnect-after-dispose.
- Changing message-level retry semantics (`send()` timeouts/retries), except to deterministically fail/clear in-flight transactions during `dispose()`.
- Implementing app-level reconnect policies (handled by downstream apps).

## Decisions

1) Add an internal disposal state
- Introduce an internal `_disposed` boolean on `WebSocketJanusTransport`.
- Set `_disposed = true` at the start of `dispose()`.
- Guard these entry points with `if (_disposed) return`:
  - `connect()`
  - `_startHeartbeat()`
  - `_handleDisconnect()`

Rationale: a single state gate is the simplest way to prevent post-dispose network activity across multiple asynchronous paths.

Alternative considered: set `autoReconnect = false` inside `dispose()` only. Rejected because it does not prevent a previously scheduled `Future.delayed(...).then(connect)` from firing, and it does not prevent other call sites from calling `connect()`.

2) Make reconnection scheduling cancellable
- Replace bare `await Future.delayed(delay)` inside `_handleDisconnect()` with a stored `Timer` (e.g. `_reconnectTimer`).
- On disconnect, schedule `_reconnectTimer = Timer(delay, () { if (!_disposed) connect(); })`.
- In `dispose()`, cancel `_reconnectTimer` if present.

Rationale: cancellation is required to prevent reconnect attempts after disposal.

Alternative considered: keep `Future.delayed` and rely on `_disposed` checks in `connect()`. This still consumes resources and can create noisy logs; explicit cancellation is clearer and cheaper.

3) Treat disposal-driven close as intentional
- Ensure `dispose()` cancels heartbeat before closing the sink.
- Ensure `_handleDisconnect()` exits early when `_disposed` is true.

Rationale: closing the socket is expected during disposal; it should not be interpreted as a failure requiring recovery.

4) Define `send()` behavior during/after disposal
- When `dispose()` is called, any in-flight transactions tracked in `_pendingTransactions` are completed with a deterministic error (e.g. `StateError("Transport disposed")`) and removed.
- After `dispose()`, calling `send()` fails immediately with the same deterministic error.
- On non-dispose disconnects, do not proactively fail/clear `_pendingTransactions` (retain current timeout-driven behavior).

Rationale: disposal is an application-driven terminal shutdown; callers should not wait for timeouts and retries once teardown begins.

## Risks / Trade-offs

- [Behavior change] Apps that previously relied on calling `dispose()` as a way to “reset and auto-reconnect” will stop reconnecting automatically.
  → Mitigation: document this as a lifecycle guarantee; apps should call `connect()` (or recreate transport/session) explicitly.

- [Edge case] A reconnect attempt could already be executing when `dispose()` is called.
  → Mitigation: `_disposed` checks in `connect()` and in the reconnect timer callback prevent creating a new channel after disposal.
