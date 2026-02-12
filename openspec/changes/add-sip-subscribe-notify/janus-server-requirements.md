Here’s what the Janus SIP plugin expects/produces for `SUBSCRIBE` / `unSUBSCRIBE` / incoming `NOTIFY`.

Client -> Janus (subscribe)
- This is a normal Janus plugin message to `janus.plugin.sip`:

```json
{
  "janus": "message",
  "session_id": 1234567890,
  "handle_id": 2345678901,
  "transaction": "sub-1",
  "body": {
    "request": "subscribe",
    "event": "ddone-dekstop-notify",
    "to": "sip:5853@10.17.1.82",
    "accept": "application/json",
    "subscribe_ttl": 300,
    "call_id": "optional-user-defined-callid",
    "headers": {
      "X-Foo": "bar"
    }
  }
}
```

Fields (from `src/plugins/janus_sip.c`)
- `request`: `"subscribe"` (required)
- `event`: SIP Event package name (required). This becomes the SIP `Event:` header (e.g. `ddone-dekstop-notify`)
- `to`: SIP URI to address the SUBSCRIBE to (optional; if omitted Janus uses the registered identity)
- `accept`: SIP `Accept:` header value (optional)
- `subscribe_ttl`: seconds (optional; becomes SIP `Expires:`)
- `call_id`: sets the SIP `Call-ID` for the subscription (optional; normally let Janus generate this)
- `headers`: extra SIP headers to add (optional). Note: despite some older docs mentioning an “array”, current code validates `headers` as a JSON object (key/value map).

What you’ll get back (Janus -> client) for subscribe
1) Immediate plugin event: `result.event = "subscribing"`
2) Then, when the SIP side replies to the SUBSCRIBE:
- `result.event = "subscribe_succeeded"` (status 200/202), includes `call_id`, and maybe `expires`
- or `result.event = "subscribe_failed"` (status >= 400)

Example (shape; outer Janus envelope included):
```json
{
  "janus": "event",
  "session_id": 1234567890,
  "sender": 2345678901,
  "transaction": "sub-1",
  "plugindata": {
    "plugin": "janus.plugin.sip",
    "data": {
      "sip": "event",
      "call_id": "the-sip-call-id",
      "result": {
        "event": "subscribe_succeeded",
        "code": 200,
        "reason": "OK",
        "expires": 300
      }
    }
  }
}
```

Client -> Janus (unsubscribe)
- Unsubscribe is implemented as “SUBSCRIBE with Expires: 0”. Syntax is the same parameter set; practically you only need `event` (and optionally `to`):

```json
{
  "janus": "message",
  "session_id": 1234567890,
  "handle_id": 2345678901,
  "transaction": "unsub-1",
  "body": {
    "request": "unsubscribe",
    "event": "ddone-dekstop-notify",
    "to": "sip:5853@10.17.1.82"
  }
}
```

What you’ll get back for unsubscribe
- Immediate plugin event: `result.event = "unsubscribing"`
- Then the SIP response to that SUBSCRIBE(Expires:0) is still reported as `subscribe_succeeded` / `subscribe_failed` (there is no separate `unsubscribe_succeeded` event in this plugin).

Janus -> client (incoming NOTIFY forwarded as a plugin event)
- When Janus receives a SIP NOTIFY that matches an existing subscription dialog, it forwards it as:

```json
{
  "janus": "event",
  "session_id": 1234567890,
  "sender": 2345678901,
  "plugindata": {
    "plugin": "janus.plugin.sip",
    "data": {
      "sip": "event",
      "call_id": "call-id-of-the-subscription",
      "result": {
        "event": "notify",
        "notify": "ddone-dekstop-notify",
        "substate": "active",
        "content-type": "application/json",
        "content": "{ ...raw SIP body as a string... }",
        "headers": {
          "X-...": "..."
        }
      }
    }
  }
}
```

Important for your case (why you saw `481 Subscription Does Not Exist`)
- Janus will only forward NOTIFYs that belong to a subscription it knows about (i.e., created by the Janus-side `subscribe` request). An unsolicited NOTIFY (or one with mismatching dialog identifiers) gets rejected (commonly 481) and won’t reach the WebRTC client.
