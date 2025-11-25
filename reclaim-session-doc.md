  Implementing Janus Session Reclaiming on the Client-Side

  This document outlines the client-side responsibilities and workflow for implementing the session reclaiming feature in a Janus-based application. This feature is critical for building robust applications that can survive network interruptions and page reloads, providing a seamless user experience.

  1. Introduction

  Janus’s session reclaiming allows a client to re-establish control over a previous session after a transport-level disconnection (e.g., a lost WebSocket connection). When configured on the server (via reclaim_session_timeout in janus.jcfg), Janus will keep a "detached" session alive in memory for a specified
  number of seconds, waiting for the client to return and "claim" it.

  If the client successfully reclaims the session within the timeout window, all its associated handles (e.g., to the SIP or VideoRoom plugin) and their internal states are preserved.

  2. The Core Workflow

  The entire process hinges on the client detecting a disconnection, establishing a new connection, and sending a claim request before the server's timeout expires.

  Step 1: Create Session and Store the session_id

  Upon initial connection, your client sends a create request to Janus. The successful response will contain the session_id.

  Your client MUST parse and store this `session_id` immediately.

   * Request: {"janus": "create", "transaction": "abc"}
   * Response:

   1     {
   2       "janus": "success",
   3       "transaction": "abc",
   4       "data": {
   5         "id": 1234567890
   6       }
   7     }
   * Action: Store the session_id (in this case, 1234567890). For web clients, sessionStorage is an excellent choice as it persists across page reloads but is cleared when the tab is closed.

  Step 2: Detect Disconnection

  The trigger for the reclaim process is the closure of the transport connection. For WebSockets, this is handled by the onclose and/or onerror event listeners.

   1 websocket.onclose = (event) => {
   2   console.log("WebSocket disconnected:", event.reason);
   3   // Do not immediately clear the session ID.
   4   // Instead, initiate the reconnection process.
   5   attemptReconnection();
   6 };

  Step 3: Reconnect with a Backoff Strategy

  Upon disconnection, the client should attempt to establish a new WebSocket connection to the same Janus URL.

  It is crucial to implement an exponential backoff strategy to avoid overwhelming the server. Do not attempt to reconnect in a tight, aggressive loop.

   * 1st attempt: Immediately or after 1 second.
   * 2nd attempt: After 2 seconds.
   * 3rd attempt: After 4 seconds, and so on.
   * Cap the delay at a reasonable maximum (e.g., 30 seconds).

  Step 4: Send the claim Request

  As soon as the new WebSocket connection is successfully opened (the onopen event fires), the very first message your client sends MUST be the claim request.

   * Request Format:
   1     {
   2       "janus": "claim",
   3       "session_id": <the_stored_session_id>,
   4       "transaction": "<a_new_unique_transaction_id>"
   5     }
   * Example:

    1     const newWebSocket = new WebSocket("ws://your-janus-server");
    2
    3     newWebSocket.onopen = () => {
    4       console.log("New WebSocket connection established. Attempting to reclaim session.");
    5       const claimRequest = {
    6         janus: "claim",
    7         session_id: storedSessionId, // e.g., 1234567890
    8         transaction: "reclaim-" + Date.now()
    9       };
   10       newWebSocket.send(JSON.stringify(claimRequest));
   11     };

  Step 5: Handle the claim Response

  The client must listen for the Janus response corresponding to the claim request's transaction ID.

   * On Success:
       * Response: {"janus": "success", "session_id": 1234567890, ...}
       * Action: The session has been successfully reclaimed. The new WebSocket connection is now bound to the old session. Your application can resume normal operations, sending messages to its existing handles as if no disconnection occurred.

   * On Failure:
       * Response: {"janus": "error", "error": {"code": 458, "reason": "Session not found"}, ...}
       * Reason: This most likely means the reclaim_session_timeout on the server expired before your claim request was processed.
       * Action: The old session is gone forever. Your client must discard the stored session_id and start the entire process from scratch by sending a new create request (Step 1).

  3. Nuances & Best Practices

   * Persistence: Use sessionStorage to store the session_id. This makes your application resilient to accidental page reloads, which is a common cause of disconnection. localStorage is not recommended as it persists indefinitely and can lead to stale, invalid session IDs.

   * The Timeout Race: The entire cycle—disconnection detection, establishing a new TCP connection, WebSocket handshake, and sending the claim request—must complete within the server's reclaim_session_timeout. Factor in network latency. A 10-15 second timeout on the server is often a reasonable starting point.

   * IP Address Changes: A successful reclaim restores the Janus session and handles. However, if the client's IP address has changed (e.g., switching from WiFi to cellular), the underlying WebRTC PeerConnection for media may fail. Your application should monitor the WebRTC connection state (iceConnectionState) and
     be prepared to trigger an ICE restart on the relevant handle if media does not resume.

   * State Management: Reclaiming a session reclaims all of its handles. Your client does not need to send attach requests again for plugins it was already using. It can immediately resume sending message requests to its existing handles.

   * Cleanup: If reconnection attempts repeatedly fail and you decide to abandon the reclaim effort, or if the claim request returns an error, ensure you clean up your local state and stored session_id before starting a new session.