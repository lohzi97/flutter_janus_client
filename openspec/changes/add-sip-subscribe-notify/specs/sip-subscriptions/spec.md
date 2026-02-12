## ADDED Requirements

### Requirement: Send SIP SUBSCRIBE
The system SHALL provide a `JanusSipPlugin.subscribe(...)` API that sends a Janus SIP plugin `subscribe` request as documented in `https://janus.conf.meetecho.com/docs/sip.html`.

The request payload MUST support the following fields:
- `request: "subscribe"`
- `call_id` (optional)
- `event` (mandatory; the SIP event package name, e.g. `message-summary`)
- `accept` (optional)
- `to` (optional)
- `subscribe_ttl` (optional)
- `content` (optional)
- `content_type` (optional)
- `headers` (optional; object map of header name -> value)

#### Scenario: Subscribe request is sent
- **WHEN** the application calls `JanusSipPlugin.subscribe(event: "message-summary")`
- **THEN** the system sends a plugin message with `{"request":"subscribe","event":"message-summary"}` (plus any provided optional fields)

#### Scenario: Subscribe request rejects missing event
- **WHEN** the application calls `JanusSipPlugin.subscribe(...)` without an `event`
- **THEN** the system throws an `ArgumentError` before sending any request

### Requirement: Send SIP UNSUBSCRIBE
The system SHALL provide a `JanusSipPlugin.unsubscribe(...)` API that sends a Janus SIP plugin `unsubscribe` request.

The request payload MUST support the following fields:
- `request: "unsubscribe"`
- `call_id` (optional)
- `event` (mandatory; the SIP event package name, e.g. `message-summary`)
- `accept` (optional)
- `to` (optional)
- `subscribe_ttl` (optional)
- `content` (optional)
- `content_type` (optional)
- `headers` (optional; object map of header name -> value)

#### Scenario: Unsubscribe request is sent
- **WHEN** the application calls `JanusSipPlugin.unsubscribe(event: "message-summary")`
- **THEN** the system sends a plugin message with `{"request":"unsubscribe","event":"message-summary"}` (plus any provided optional fields)

#### Scenario: Unsubscribe request rejects missing event
- **WHEN** the application calls `JanusSipPlugin.unsubscribe(...)` without an `event`
- **THEN** the system throws an `ArgumentError` before sending any request

### Requirement: Parse SIP subscription lifecycle events
The system SHALL parse incoming Janus SIP plugin events where `plugindata.data.sip == "event"` and `plugindata.data.result.event` is one of:
- `subscribing`
- `unsubscribing`
- `subscribe_succeeded`
- `subscribe_failed`

into typed events emitted on `JanusSipPlugin.typedMessages`.

The typed lifecycle event models MUST expose (where present in the payload):
- `sip` (string)
- `callId` (string; from `call_id`)
- `result.event` (string)
- `result.code` (int)
- `result.reason` (string)
- `result.expires` (int; optional)

#### Scenario: Subscribing is emitted as a typed event
- **WHEN** Janus sends a SIP plugin message with `result.event == "subscribing"`
- **THEN** `JanusSipPlugin.typedMessages` emits a `TypedEvent` whose `plugindata.data` is a `SipSubscribingEvent`

#### Scenario: Subscribe success is emitted as a typed event
- **WHEN** Janus sends a SIP plugin message with `result.event == "subscribe_succeeded"`
- **THEN** `JanusSipPlugin.typedMessages` emits a `TypedEvent` whose `plugindata.data` is a `SipSubscribeSucceededEvent`

### Requirement: Parse SIP NOTIFY events
The system SHALL parse incoming Janus SIP plugin events where `plugindata.data.sip == "event"` and `plugindata.data.result.event == "notify"` into a typed `SipNotifyEvent`.

`SipNotifyEvent` MUST expose:
- `sip` (string)
- `callId` (string; from `call_id`)
- `result.notify` (string)
- `result.substate` (string)
- `result.contentType` (string; from `content-type`)
- `result.content` (string)
- `result.headers` (object; optional)

#### Scenario: Notify is emitted as a typed event
- **WHEN** Janus sends a SIP plugin message with `result.event == "notify"`
- **THEN** `JanusSipPlugin.typedMessages` emits a `TypedEvent` whose `plugindata.data` is a `SipNotifyEvent`

### Requirement: Preserve existing SIP typed events
The system SHALL preserve existing typed event behavior for currently supported SIP events (e.g. `registered`, `unregistered`, `ringing`, `incomingcall`, `hangup`).

#### Scenario: Existing SIP event mapping remains unchanged
- **WHEN** Janus sends a SIP plugin message with `result.event == "registered"`
- **THEN** `JanusSipPlugin.typedMessages` emits a typed `SipRegisteredEvent` as before
