import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:janus_client/janus_client.dart';

class _StubSipPlugin extends JanusSipPlugin {
  _StubSipPlugin(
      {required JanusClient client,
      required JanusTransport transport,
      required JanusSession session})
      : super(
            context: client,
            transport: transport,
            session: session,
            handleId: 1);

  Map<String, dynamic>? lastPayload;

  @override
  Future<dynamic> send({dynamic data, RTCSessionDescription? jsep}) async {
    lastPayload = Map<String, dynamic>.from(data as Map<String, dynamic>);
    return {
      'janus': 'event',
      'plugindata': {'plugin': 'janus.plugin.sip', 'data': {}}
    };
  }
}

_StubSipPlugin _createPlugin() {
  final transport = RestJanusTransport(url: 'https://example.com/janus');
  final client = JanusClient(transport: transport);
  final session = JanusSession(transport: transport, context: client);
  return _StubSipPlugin(client: client, transport: transport, session: session);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JanusSipPlugin subscribe/unsubscribe payloads', () {
    test('subscribe builds payload with mandatory event and removes nulls',
        () async {
      final plugin = _createPlugin();

      await plugin.subscribe(
        event: 'message-summary',
        accept: 'application/simple-message-summary',
        subscribeTtl: 300,
        headers: {'X-Foo': 'bar'},
      );

      expect(plugin.lastPayload, isNotNull);
      expect(plugin.lastPayload?['request'], 'subscribe');
      expect(plugin.lastPayload?['event'], 'message-summary');
      expect(
          plugin.lastPayload?['accept'], 'application/simple-message-summary');
      expect(plugin.lastPayload?['subscribe_ttl'], 300);
      expect(plugin.lastPayload?.containsKey('call_id'), isFalse);
      expect(plugin.lastPayload?['headers'], {'X-Foo': 'bar'});
    });

    test('subscribe throws ArgumentError when event is blank', () {
      final plugin = _createPlugin();

      expect(() => plugin.subscribe(event: ''), throwsArgumentError);
    });

    test('unsubscribe sends unsubscribe request and preserves headers map',
        () async {
      final plugin = _createPlugin();

      await plugin.unsubscribe(
        event: 'message-summary',
        to: 'sip:alice@example.com',
        headers: {'X-Bar': 'baz'},
      );

      expect(plugin.lastPayload, isNotNull);
      expect(plugin.lastPayload?['request'], 'unsubscribe');
      expect(plugin.lastPayload?['event'], 'message-summary');
      expect(plugin.lastPayload?['to'], 'sip:alice@example.com');
      expect(plugin.lastPayload?['headers'], isA<Map<String, dynamic>>());
      expect(plugin.lastPayload?['headers'], containsPair('X-Bar', 'baz'));
    });
  });

  group('SipNotifyEvent parsing', () {
    test('maps wire keys to dart fields', () {
      final event = SipNotifyEvent.fromJson({
        'sip': 'event',
        'call_id': 'sub-123',
        'result': {
          'event': 'notify',
          'notify': 'message-summary',
          'substate': 'active',
          'content-type': 'application/simple-message-summary',
          'content': '{ "messages": 1 }',
          'headers': {'X-Baz': 'qux'},
        }
      });

      expect(event.sip, 'event');
      expect(event.callId, 'sub-123');
      expect(event.result?.event, 'notify');
      expect(event.result?.notify, 'message-summary');
      expect(event.result?.substate, 'active');
      expect(event.result?.contentType, 'application/simple-message-summary');
      expect(event.result?.content, '{ "messages": 1 }');
      expect(event.result?.headers, containsPair('X-Baz', 'qux'));
    });
  });
}
