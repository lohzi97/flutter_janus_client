import 'package:flutter/material.dart';
import 'package:janus_client/janus_client.dart';
import 'conf.dart';

class SessionReclamationExample extends StatefulWidget {
  @override
  _SessionReclamationExampleState createState() => _SessionReclamationExampleState();
}

class _SessionReclamationExampleState extends State<SessionReclamationExample> {
  late WebSocketJanusTransport _transport;
  late JanusClient _janusClient;
  JanusSession? _session;
  int? _storedSessionId;
  bool _isConnected = false;
  bool _isReclaimed = false;
  String _status = 'Not connected';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initializeClient();
  }

  void _initializeClient() {
    _transport = WebSocketJanusTransport(
      url: 'ws://10.17.1.31:8188/ws',
      // Enable auto-reconnect for better testing
      autoReconnect: true,
    );
    _janusClient = JanusClient(transport: _transport, isUnifiedPlan: true);
    _addLog('Janus client initialized with local server');
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
      if (_logs.length > 20) _logs.removeAt(0);
    });
  }

  Future<void> _createNewSession() async {
    try {
      setState(() {
        _status = 'Creating new session...';
        _isReclaimed = false;
      });

      _session = JanusSession(transport: _transport, context: _janusClient);
      await _session!.create();

      _storedSessionId = _session!.sessionId;

      setState(() {
        _isConnected = true;
        _status = 'New session created (ID: ${_session!.sessionId})';
      });

      _addLog('New session created with ID: ${_session!.sessionId}');
    } catch (e) {
      setState(() {
        _status = 'Failed to create session';
      });
      _addLog('Error creating session: $e');
    }
  }

  Future<void> _reclaimSession() async {
    if (_storedSessionId == null) {
      _addLog('No stored session ID available. Create a session first.');
      return;
    }

    try {
      setState(() {
        _status = 'Reclaiming session...';
        _isReclaimed = false;
      });

      // Dispose current session if it exists
      if (_session != null) {
        _session!.dispose();
        _session = null;
      }

      // Create new session instance and reclaim
      _session = JanusSession(transport: _transport, context: _janusClient);
      await _session!.create(sessionId: _storedSessionId);

      setState(() {
        _isConnected = true;
        _isReclaimed = true;
        _status = 'Session reclaimed successfully (ID: ${_session!.sessionId})';
      });

      _addLog('Session reclaimed successfully! Original ID: $_storedSessionId, Current ID: ${_session!.sessionId}');
    } on SessionReclaimException catch (e) {
      setState(() {
        _status = 'Session reclamation failed';
      });
      _addLog('Session reclaim failed: $e');
      _addLog('Session may have expired. Try creating a new session.');
    } catch (e) {
      setState(() {
        _status = 'Reclamation error';
      });
      _addLog('Error during reclamation: $e');
    }
  }

  Future<void> _testSessionFunctionality() async {
    if (_session == null || _session!.sessionId == null) {
      _addLog('No active session to test');
      return;
    }

    try {
      _addLog('Testing session functionality by attaching EchoTest plugin...');

      // Try to attach a plugin to verify the session is working
      JanusEchoTestPlugin echoPlugin = await _session!.attach<JanusEchoTestPlugin>();

      _addLog('EchoTest plugin attached successfully! Handle ID: ${echoPlugin.handleId}');

      // Test a simple echo test call
      await echoPlugin.startEchoTest();
      _addLog('Echo test started successfully!');

      // Clean up
      await echoPlugin.detach();
      _addLog('Plugin detached successfully');

    } catch (e) {
      _addLog('Session functionality test failed: $e');
    }
  }

  void _simulateDisconnection() {
    _addLog('Simulating network disconnection...');

    // Dispose current session to simulate disconnection
    if (_session != null) {
      _session!.dispose();
      _session = null;
    }

    setState(() {
      _isConnected = false;
      _status = 'Disconnected - session stored for reclamation';
    });

    _addLog('Session disposed. Session ID $_storedSessionId stored for reclamation.');
  }

  void _resetAll() {
    _addLog('Resetting everything...');

    if (_session != null) {
      _session!.dispose();
      _session = null;
    }

    setState(() {
      _isConnected = false;
      _isReclaimed = false;
      _storedSessionId = null;
      _status = 'Not connected';
    });

    _addLog('Reset complete');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Session Reclamation Example'),
        backgroundColor: Colors.blue[700],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.wifi : Icons.wifi_off,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _status,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isConnected ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_storedSessionId != null)
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Stored Session ID: $_storedSessionId',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    if (_isReclaimed)
                      Padding(
                        padding: EdgeInsets.only(top: 4.0),
                        child: Text(
                          '✓ This is a reclaimed session',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Action Buttons
            Text(
              'Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _createNewSession,
                  icon: Icon(Icons.add),
                  label: Text('Create New Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _reclaimSession,
                  icon: Icon(Icons.refresh),
                  label: Text('Reclaim Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  disabled: _storedSessionId == null,
                ),
                ElevatedButton.icon(
                  onPressed: _simulateDisconnection,
                  icon: Icon(Icons.wifi_off),
                  label: Text('Simulate Disconnect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  disabled: !_isConnected,
                ),
                ElevatedButton.icon(
                  onPressed: _testSessionFunctionality,
                  icon: Icon(Icons.check_circle),
                  label: Text('Test Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                  disabled: !_isConnected,
                ),
                ElevatedButton.icon(
                  onPressed: _resetAll,
                  icon: Icon(Icons.refresh),
                  label: Text('Reset All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Instructions
            Text(
              'Instructions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  '1. Click "Create New Session" to establish a connection\n'
                  '2. Click "Test Session" to verify the session works\n'
                  '3. Click "Simulate Disconnect" to simulate network loss\n'
                  '4. Click "Reclaim Session" to restore the previous session\n'
                  '5. Click "Test Session" again to verify reclamation worked\n\n'
                  'This demonstrates how session reclamation allows recovery '
                  'from network interruptions without losing session state.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Logs
            Expanded(
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity Log:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _logs.clear();
                              });
                            },
                            child: Text('Clear'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            return Text(
                              _logs[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'monospace',
                                color: index % 2 == 0 ? Colors.black87 : Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }
}