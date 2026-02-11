Based on the detailed technical analysis of the Janus SIP plugin and session management, here is the definitive guide on how to implement the "Background Wake-up to Foreground Call" flow.

### The Core Problem
If you create a session in a background isolate and then explicitly **dispose** or **detach** it when transferring to the main app, **Janus will automatically decline the call.**
*   **Why:** When a handle is destroyed, the SIP plugin cleans up resources. If a call is ringing, it sends a SIP `486 Busy Here` or `603 Decline` to the caller.
*   **Result:** The call is terminated before your main app opens.

---

### The Solution: "Abandon and Reclaim"
Instead of properly closing the session in the background, you must let it "timeout" on the server while keeping it alive long enough for the main app to reconnect.

#### Prerequisites
1.  **Janus Configuration:** In your `janus.jcfg`, ensure `reclaim_session_timeout` is set (e.g., `10` or `15` seconds). This tells Janus not to destroy a session immediately if the transport (WebSocket) disconnects.
2.  **SIP Plugin Configuration:** Ensure the plugin is configured to send `180 Ringing` automatically (this is usually the default), which keeps the SIP transaction active on the provider side.

---

### Step-by-Step Implementation Flow

#### 1. Background Isolate (Receiving the Push)
When the FCM push arrives, perform the following:
1.  **Create Session:** Connect to Janus and create a session. **Save the `session_id`.**
2.  **Attach Plugin:** Attach to `janus.plugin.sip`. **Save the `handle_id`.**
3.  **Register:** Send your SIP `register` message.
4.  **Wait for Event:** (Optional but recommended) Wait for the registration success.
5.  **Persist Data:** Save the `session_id`, `handle_id`, and a boolean flag (e.g., `incoming_call_pending = true`) to a shared storage (SharedPreferences, local DB) that the main isolate can access.
6.  **CRITICAL STEP - "Abandon" the Session:**
    *   **DO NOT** send a `detach` or `destroy` request.
    *   Simply close the WebSocket connection or let the background isolate execution finish.
    *   *Result:* The Janus server sees the transport vanish but keeps the session and SIP handle (and the ringing call) alive for the duration of `reclaim_session_timeout`.

#### 2. The "Handoff" (User Interaction)
1.  The user sees the notification and taps "Accept" or "Open".
2.  The main application (Isolate) launches.

#### 3. Main Isolate (Resuming the Call)
1.  **Retrieve Data:** Read the saved `session_id`, `handle_id`, and `incoming_call_pending` flag.
2.  **Connect:** Open a new WebSocket connection to Janus.
3.  **Claim the Session:**
    *   Send a `claim` request using the saved `session_id`.
    *   *Janus Response:* Confirmation that the session is now attached to this new WebSocket.
4.  **Re-attach to the Handle:**
    *   **Do not** create a generic new plugin handle.
    *   Use the client library's feature to attach to an **existing** handle by providing the saved `handle_id`.
    *   *Why:* You need control over the specific C-level plugin instance that holds the SIP socket and the ringing call.

#### 4. Handling the "Blind" State
*   **The Issue:** When you re-connect, you will **not** receive the `incomingcall` event again (it was already sent to the background isolate). There is no API to query the plugin for "current call status."
*   **The Fix:** You must rely on your local data.
    *   Check your saved flag: `if (incoming_call_pending == true)`
    *   Assume the call is ringing.
    *   Show the Incoming Call UI immediately.

#### 5. Answering/Declining
Since you are attached to the original handle, you can now send standard SIP commands:
*   **To Answer:** Send the `accept` request (with JSEP offer/answer). The plugin will process this because the server-side state is still "Invited".
*   **To Decline:** Send the `decline` request.

---

### Summary Checklist

| Phase | Action | Why? |
| :--- | :--- | :--- |
| **Config** | Set `reclaim_session_timeout = 10` | Keeps session alive when background isolate dies. |
| **Background** | Connect, Register, **Save IDs**. | Establishes the call path. |
| **Background** | **Close Socket only.** (No `detach`) | Prevents Janus from sending "Decline" to the caller. |
| **Foreground** | `claim` session + `attach` to **saved handle**. | Regains control of the specific active SIP resource. |
| **Foreground** | **Assume** Incoming Call state. | The server won't re-send the event; rely on local flags. |