# Change: Add SIP Subscribe/Notify Support

## Why
Janus SIP supports SIP event subscriptions via SUBSCRIBE/NOTIFY (e.g. MWI `message-summary`). This package currently exposes several SIP call lifecycle events, but provides no API to send `subscribe`/`unsubscribe` requests and no typed mapping for incoming `notify` events.

## What Changes
- Add `JanusSipPlugin.subscribe(...)` and `JanusSipPlugin.unsubscribe(...)` wrapper methods for the Janus SIP Plugin API.
- Add typed events for subscription lifecycle and NOTIFY payloads (e.g. `SipNotifyEvent`).
- Extend `JanusSipPlugin.onCreate()` typed-event mapping to emit typed subscription/notify events on `typedMessages`.

## Impact
- **Affected specs**: `sip-subscriptions` (new capability)
- **Affected code**: `lib/wrapper_plugins/janus_sip_plugin.dart`, `lib/interfaces/sip/events/*`, `lib/janus_client.dart`
- **Breaking changes**: None (additive API only)
