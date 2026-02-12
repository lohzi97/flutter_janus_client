## 1. Implementation
- [ ] 1.1 Add `JanusSipPlugin.subscribe(...)` that sends Janus SIP `{"request":"subscribe"}` with the documented fields (see `janus-server-requirements.md`).
- [ ] 1.2 Add `JanusSipPlugin.unsubscribe(...)` that sends Janus SIP `{"request":"unsubscribe"}` (implemented by Janus as a SUBSCRIBE with `Expires: 0`; see `janus-server-requirements.md`).
- [ ] 1.3 Add typed event models:
  - `SipSubscribingEvent`, `SipSubscribeSucceededEvent`, `SipSubscribeFailedEvent`
  - `SipUnsubscribingEvent`
  - `SipNotifyEvent`
- [ ] 1.4 Update `JanusSipPlugin.onCreate()` mapping to detect `result.event` values `subscribing`, `subscribe_succeeded`, `subscribe_failed`, `unsubscribing`, and `notify`.
- [ ] 1.5 Wire new `part` files in `lib/janus_client.dart`.

## 2. Tests
- [ ] 2.1 Add unit tests that verify JSON payload generation for `subscribe`/`unsubscribe` (null fields removed; required fields present; `headers` is a JSON object).
- [ ] 2.2 Add tests for typed event parsing of `notify` (maps `content-type` -> `contentType`, etc.).

## 3. Examples / Docs
- [ ] 3.1 Update `example/lib/typed_examples/sip.dart` to demonstrate subscribing and handling `SipNotifyEvent`.
- [ ] 3.2 Document the expected Janus server messages (subscribe request + notify event shape) in the example comments.

## 4. Validation
- [ ] 4.1 Run `openspec validate add-sip-subscribe-notify --strict`.
- [ ] 4.2 Run `flutter analyze` and a focused `flutter test` selection for the added tests.
