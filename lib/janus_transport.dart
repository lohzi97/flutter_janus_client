part of janus_client;

abstract class JanusTransport {
  String? url;
  int? sessionId;

  JanusTransport({this.url});

  Future<dynamic> getInfo();

  /// this is called internally whenever [JanusSession] or [JanusPlugin] is disposed for cleaning up of active connections either polling or websocket connection.
  void dispose();
}

///
/// This transport class is provided to [JanusClient] instances in transport property in order to <br>
/// inform the plugin that we need to use Rest as a transport mechanism for communicating with Janus Server.<br>
/// therefore for events sent by Janus server is received with the help of polling.
class RestJanusTransport extends JanusTransport {
  RestJanusTransport({String? url}) : super(url: url);

  /*
  * method for posting data to janus by using http client
  * */
  Future<dynamic> post(body, {int? handleId, int? optSessionId}) async {
    var suffixUrl = '';
    if (optSessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$optSessionId";
    } else if (optSessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$optSessionId/$handleId";
    } else if (sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$sessionId";
    } else if (sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$sessionId/$handleId";
    }
    try {
      var response = (await http.post(Uri.parse(url! + suffixUrl), body: stringify(body))).body;
      return parse(response);
    } on JsonCyclicError {
      return null;
    } on JsonUnsupportedObjectError {
      return null;
    } catch (e) {
      return null;
    }
  }

  /*
  * private method for get data to janus by using http client
  * */
  Future<dynamic> get({handleId}) async {
    var suffixUrl = '';
    if (sessionId != null && handleId == null) {
      suffixUrl = suffixUrl + "/$sessionId";
    } else if (sessionId != null && handleId != null) {
      suffixUrl = suffixUrl + "/$sessionId/$handleId";
    }
    return parse((await http.get(Uri.parse(url! + suffixUrl))).body);
  }

  @override
  void dispose() {}

  @override
  Future<dynamic> getInfo() async {
    return parse((await http.get(Uri.parse(url! + "/info"))).body);
  }
}

///
/// This transport class is provided to [JanusClient] instances in transport property in order to <br>
/// inform the plugin that we need to use WebSockets as a transport mechanism for communicating with Janus Server.<br>
/// sendCompleterTimeout is used to set timeout duration for each send request to Janus server resolving against transaction.
class WebSocketJanusTransport extends JanusTransport {
  WebSocketJanusTransport({
    String? url,
    this.sendCompleterTimeout = const Duration(seconds: 20),
    this.autoReconnect = true,
    this.heartbeatInterval = const Duration(seconds: 10),
    this.maxMessageMissedRetries = 3,
    this.maxReconnectAttempts = 5,
    WebSocketChannel Function(Uri uri, {Iterable<String>? protocols})? channelFactory,
  })  : _channelFactory =
            channelFactory ?? ((uri, {protocols}) => WebSocketChannel.connect(uri, protocols: protocols)),
        super(url: url);

  WebSocketChannel? channel;
  WebSocketSink? sink;
  late Stream stream;
  bool isConnected = false;

  final WebSocketChannel Function(Uri uri, {Iterable<String>? protocols}) _channelFactory;
  bool _disposed = false;

  Duration sendCompleterTimeout;
  bool autoReconnect;
  Duration heartbeatInterval;
  int maxReconnectAttempts;
  int maxMessageMissedRetries;

  final Map<String, Completer<dynamic>> _pendingTransactions = {};
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  StreamSubscription? _streamSubscription;
  int _reconnectAttempts = 0;

  /// Dispose WebSocket connection
  ///
  /// Lifecycle guarantee: once `dispose()` is called, this transport enters a
  /// terminal state and will not reconnect or emit heartbeat traffic.
  /// Any in-flight and future `send()` calls fail with `StateError('Transport disposed')`.
  @override
  void dispose() {
    _disposed = true;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    final error = StateError('Transport disposed');
    final pending = _pendingTransactions.values.toList(growable: false);
    for (final completer in pending) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingTransactions.clear();

    sink?.close();
    sink = null;
    channel = null;
    isConnected = false;

    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

  /// Establish WebSocket connection
  void connect() {
    if (_disposed) return;

    try {
      _reconnectTimer?.cancel();
      _reconnectTimer = null;

      channel = _channelFactory(
        Uri.parse(url!),
        protocols: const ['janus-protocol'],
      );

      sink = channel!.sink;
      stream = channel!.stream.asBroadcastStream();
      isConnected = true;
      _reconnectAttempts = 0;

      // Start heartbeat
      _startHeartbeat();

      // Listen to incoming messages
      _streamSubscription?.cancel();
      _streamSubscription = stream.listen(
        (event) {
          final msg = parse(event);
          final transaction = msg['transaction'];
          if (transaction != null && _pendingTransactions.containsKey(transaction)) {
            _pendingTransactions[transaction]!.complete(msg);
            _pendingTransactions.remove(transaction);
          }
        },
        onDone: _handleDisconnect,
        onError: (_) => _handleDisconnect(),
      );
    } catch (e) {
      print('WebSocket connect failed: $e');
      _handleDisconnect();
    }
  }

  /// Heartbeat to keep connection alive
  void _startHeartbeat() {
    if (_disposed) return;

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (!_disposed && isConnected && sink != null) {
        final ping = {
          'janus': 'ping',
          'transaction': getUuid().v4(),
        };
        sink!.add(stringify(ping));
      }
    });
  }

  /// Handle disconnect and auto-reconnect
  void _handleDisconnect() async {
    if (_disposed) return;

    isConnected = false;
    sink = null;
    channel = null;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;

    if (autoReconnect && _reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      final delay = Duration(seconds: 2 * _reconnectAttempts); // exponential backoff
      print('Reconnecting in ${delay.inSeconds}s...');
      _reconnectTimer = Timer(delay, () {
        if (_disposed) return;
        connect();
      });
    } else if (_reconnectAttempts >= maxReconnectAttempts) {
      print('Max reconnect attempts reached.');
    }
  }

  /// Send JSON to Janus safely with 3 retries
  Future<dynamic> send(Map<String, dynamic> data, {int? optSessionId, int? handleId}) async {
    if (_disposed) {
      throw StateError('Transport disposed');
    }
    if (!isConnected || sink == null) {
      throw StateError("WebSocket is not connected");
    }

    final original = Map<String, dynamic>.from(data);

    for (int attempt = 1; attempt <= maxMessageMissedRetries; attempt++) {
      final Map<String, dynamic> payload = Map<String, dynamic>.from(original);
      final String transaction = getUuid().v4();
      payload['transaction'] = transaction;

      // Support for optional session ID parameter (for session reclamation)
      if (optSessionId != null) {
        payload['session_id'] = optSessionId;
      } else {
        payload['session_id'] = sessionId;
      }

      if (handleId != null) payload['handle_id'] = handleId;

      final completer = Completer<dynamic>();
      _pendingTransactions[transaction] = completer;

      sink!.add(stringify(payload));

      try {
        final response = await completer.future.timeout(sendCompleterTimeout);
        _pendingTransactions.remove(transaction);
        return response;
      } on TimeoutException {
        _pendingTransactions.remove(transaction);
        if (attempt == maxMessageMissedRetries) {
          throw TimeoutException("Janus transaction timed out after $maxMessageMissedRetries attempts");
        }
      }
    }

    throw TimeoutException("Unexpected send() failure");
  }

  @override
  Future<dynamic> getInfo() async {
    if (!isConnected) connect();
    final payload = {
      'janus': 'info',
    };
    return send(payload);
  }
}
