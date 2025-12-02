part of janus_client;

class JanusSession {
  late JanusTransport? _transport;
  late JanusClient _context;
  int? _sessionId;
  Timer? _keepAliveTimer;
  Map<int?, JanusPlugin> _pluginHandles = {};

  int? get sessionId => _sessionId;

  JanusSession({int? refreshInterval, required JanusTransport transport, required JanusClient context}) {
    _context = context;
    _transport = transport;
  }

  Future<Map<String, dynamic>?> create({int? sessionIdToClaim}) async {
    try {
      String transaction = getUuid().v4();
      Map<String, dynamic> request;

      if (sessionIdToClaim != null) {
        request = {"janus": "claim", "session_id": sessionIdToClaim, "transaction": transaction, ..._context._tokenMap, ..._context._apiMap}..removeWhere((key, value) => value == null);
      } else {
        request = {"janus": "create", "transaction": transaction, ..._context._tokenMap, ..._context._apiMap}..removeWhere((key, value) => value == null);
      }

      Map<String, dynamic>? response;
      if (_transport is RestJanusTransport) {
        RestJanusTransport rest = (_transport as RestJanusTransport);
        response = (await rest.post(request)) as Map<String, dynamic>?;
        if (response != null) {
          if (response.containsKey('janus') && response.containsKey('data')) {
            _sessionId = response['data']['id'];
            rest.sessionId = sessionId;
          }
        } else {
          throw "Janus Server not live or incorrect url/path specified";
        }
      } else if (_transport is WebSocketJanusTransport) {
        WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
        if (!ws.isConnected) {
          ws.connect();
        }
        response = await ws.send(request, optSessionId: sessionIdToClaim, handleId: null);
        if (response!.containsKey('janus') && response.containsKey('data')) {
          // create session response
          _sessionId = response['data']['id'] as int?;
          ws.sessionId = sessionId;
        } else if (response.containsKey('session_id')) {
          // claim session response
          _sessionId = response['session_id'] as int?;
          ws.sessionId = sessionId;
        } else {
        }
      }
      _startKeepAliveTimer();
      return response;
    } on WebSocketChannelException catch (e) {
      throw "Connection to given url can't be established\n reason:-" + e.message!;
    } catch (e) {
      throw "Connection to given url can't be established\n reason:-" + e.toString();
    }
  }

  /// This can be used to attach plugin handle to the session.
  /// [opaqueId] : opaque id is an optional string identifier used for client side correlations in event handlers or admin API.
  /// [existingHandleId] : optional existing handle ID for re-attaching to a previously created plugin handle without sending a new "attach" request to Janus.<br>
  Future<T> attach<T extends JanusPlugin>({String? opaqueId, int? existingHandleId}) async {
    // Validate session is active for any attachment operation
    if (sessionId == null) {
      throw StateError('Cannot attach plugin: session is not active or has been destroyed');
    }

    // If existingHandleId is provided, use re-attachment flow
    if (existingHandleId != null) {
      return _reattachPlugin<T>(existingHandleId);
    }

    // Otherwise, create new plugin handle (existing behavior)
    return _createNewPluginHandle<T>(opaqueId: opaqueId);
  }

  /// Re-attach to an existing plugin handle without sending "attach" request to Janus
  Future<T> _reattachPlugin<T extends JanusPlugin>(int existingHandleId) async {
    _context._logger.info('Re-attaching to existing plugin handle: $existingHandleId');

    // Create plugin instance based on type
    JanusPlugin plugin = _createPluginInstance<T>(existingHandleId);

    // Register the plugin in the handles registry
    plugin.handleId = existingHandleId;
    _pluginHandles[existingHandleId] = plugin;

    // Initialize plugin (WebRTC setup, event handlers, etc.)
    try {
      await plugin._init();
    } on MissingPluginException {
      _context._logger.info('Platform exception: i believe you are trying in unit tests, platform specific api not accessible');
    }

    // Call plugin's onCreate callback
    plugin.onCreate();

    _context._logger.info('Successfully re-attached to plugin handle: $existingHandleId');
    return plugin as T;
  }

  /// Create a new plugin handle by sending "attach" request to Janus (existing behavior)
  Future<T> _createNewPluginHandle<T extends JanusPlugin>({String? opaqueId}) async {
    _context._logger.info('Creating new plugin handle for type: $T');

    JanusPlugin plugin;
    int? handleId;
    String transaction = getUuid().v4();
    Map<String, dynamic> request = {"janus": "attach", "transaction": transaction, ..._context._apiMap, ..._context._tokenMap};

    if (opaqueId != null) {
      request["opaque_id"] = opaqueId;
    }
    request["session_id"] = sessionId;

    // Create plugin instance with null handleId initially
    plugin = _createPluginInstance<T>(null);
    request.putIfAbsent("plugin", () => plugin.plugin);

    _context._logger.fine(request);
    Map<String, dynamic>? response;

    if (_transport is RestJanusTransport) {
      _context._logger.info('using rest transport for creating plugin handle');
      RestJanusTransport rest = (_transport as RestJanusTransport);
      response = (await rest.post(request)) as Map<String, dynamic>?;
      _context._logger.fine(response);
      if (response != null && response.containsKey('janus') && response.containsKey('data')) {
        handleId = response['data']['id'];
        rest.sessionId = sessionId;
      } else {
        throw "Network error or janus server not running";
      }
    } else if (_transport is WebSocketJanusTransport) {
      _context._logger.info('using web socket transport for creating plugin handle');
      WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
      if (!ws.isConnected) {
        ws.connect();
      }
      response = await ws.send(request, handleId: null);
      if (response!.containsKey('janus') && response.containsKey('data')) {
        handleId = response['data']['id'] as int?;
        _context._logger.fine(response);
      }
    }

    // Update plugin with the assigned handle ID
    plugin.handleId = handleId;
    _pluginHandles[handleId] = plugin;

    try {
      await plugin._init();
    } on MissingPluginException {
      _context._logger.info('Platform exception: i believe you are trying in unit tests, platform specific api not accessible');
    }

    plugin.onCreate();
    return plugin as T;
  }

  /// Create plugin instance based on type parameter
  JanusPlugin _createPluginInstance<T extends JanusPlugin>(int? handleId) {
    if (T == JanusVideoRoomPlugin) {
      return JanusVideoRoomPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusVideoCallPlugin) {
      return JanusVideoCallPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusStreamingPlugin) {
      return JanusStreamingPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusAudioBridgePlugin) {
      return JanusAudioBridgePlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusTextRoomPlugin) {
      return JanusTextRoomPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusEchoTestPlugin) {
      return JanusEchoTestPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else if (T == JanusSipPlugin) {
      return JanusSipPlugin(transport: _transport, context: _context, handleId: handleId, session: this);
    } else {
      throw UnimplementedError('''This Plugin is not defined kindly refer to Janus Server Docs
      make sure you specify the type of plugin you want to attach like session.attach<JanusVideoRoomPlugin>();
      ''');
    }
  }

  void dispose() {
    if (_keepAliveTimer != null) {
      _keepAliveTimer!.cancel();
    }
    if (_transport != null) {
      _transport?.dispose();
    }
  }

  _startKeepAliveTimer() {
    // Cancel any existing timer before starting a new one
    if (_keepAliveTimer != null) {
      _keepAliveTimer!.cancel();
    }

    if (sessionId != null) {
      this._keepAliveTimer = Timer.periodic(Duration(seconds: _context._refreshInterval), (timer) async {
        try {
          String transaction = getUuid().v4();
          Map<String, dynamic>? response;
          if (_transport is RestJanusTransport) {
            RestJanusTransport rest = (_transport as RestJanusTransport);
            _context._logger.finer("keep alive using RestTransport");
            response =
                (await rest.post({"janus": "keepalive", "session_id": sessionId, "transaction": transaction, ..._context._apiMap, ..._context._tokenMap})) as Map<String, dynamic>;
            _context._logger.finest(response);
          } else if (_transport is WebSocketJanusTransport) {
            _context._logger.finest("keep alive using WebSocketTransport");
            WebSocketJanusTransport ws = (_transport as WebSocketJanusTransport);
            if (!ws.isConnected) {
              _context._logger.finest("not connected trying to establish connection to webSocket");
              ws.connect();
            }
            response = await ws.send({"janus": "keepalive", "session_id": sessionId, "transaction": transaction, ..._context._apiMap, ..._context._tokenMap}, handleId: null);
            _context._logger.finest("keepalive request sent to webSocket");
            _context._logger.finest(response);
          }
        } catch (e) {
          timer.cancel();
        }
      });
    }
  }
}
