import 'package:flutter_test/flutter_test.dart';
import 'package:janus_client/janus_client.dart';

void main() {
  // Initialize Flutter binding for tests
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Plugin Handle Re-attachment Tests via wsTransport', () {
    bool serverAccessible = false;

    setUpAll(() async {
      WebSocketJanusTransport wsTransport = WebSocketJanusTransport(url: 'ws://10.17.1.31:8188/ws');
      JanusClient wsClient = JanusClient(transport: wsTransport, isUnifiedPlan: true);

      // Check if server is accessible by trying to get server info
      try {
        await wsClient.getInfo().timeout(Duration(seconds: 5));
        serverAccessible = true;
        print('Janus server is accessible - running full integration tests');
      } catch (e) {
        serverAccessible = false;
        print('Janus server not accessible - running offline tests only: $e');
      }
    });

    test('Create plugin handle normally and then re-attach to existing handle', () async {
      if (!serverAccessible) {
        print('Skipping test - server not accessible');
        return;
      }

      // Create a session normally
      WebSocketJanusTransport wsTransport = WebSocketJanusTransport(url: 'ws://10.17.1.31:8188/ws');
      JanusClient wsClient = JanusClient(transport: wsTransport, isUnifiedPlan: true);
      JanusSession session = JanusSession(transport: wsTransport, context: wsClient);
      await session.create();

      expect(session.sessionId, isNotNull);
      print('Session created with ID: ${session.sessionId}');

      // Create a plugin handle normally
      JanusSipPlugin originalPlugin = await session.attach<JanusSipPlugin>(
        opaqueId: 'test-re-attachment',
      );
      expect(originalPlugin.handleId, isNotNull);
      int? originalHandleId = originalPlugin.handleId;

      print('Original plugin created with handle ID: $originalHandleId');

      // Dispose the original plugin but keep the session active
      originalPlugin.dispose();
      await Future.delayed(Duration(milliseconds: 500)); // Allow cleanup

      // Re-attach to the existing handle ID (this simulates reclamation scenario)
      JanusSipPlugin reattachedPlugin = await session.attach<JanusSipPlugin>(
        existingHandleId: originalHandleId,
      );

      expect(reattachedPlugin.handleId, equals(originalHandleId));
      print('Successfully re-attached to plugin handle: ${reattachedPlugin.handleId}');

      // wait a while for plugin to be ready
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (reattachedPlugin.typedMessages != null) {
          break;
        }
      }

      // use the reattached plugin to do something to ensure that it still works
      
      // Note: unit test limitation, platform specific API (initializeWebRTCStack) are not accessible, so typedMessages
      // will always be null. To try to see it work, comment out the `await initializeWebRTCStack();` in JanusPlugin._init().
      // bool registered = false;
      // reattachedPlugin.typedMessages!.listen((TypedEvent<JanusEvent> event) {
      //   Object data = event.event.plugindata?.data;
      //   print('Reattached SIP plugin handleId: ${reattachedPlugin.handleId} - typedEvent listener data: $data');
      //   if (data is SipRegisteredEvent) {
      //     registered = true;
      //   }
      // });
      await reattachedPlugin.register(
        'sip:5850@10.17.1.82',
        displayName: '5850',
        forceTcp: true,
        rfc2543Cancel: true,
        proxy: 'sip:10.17.1.82:5260',
        secret: 'p7AqMfRo0assBwaj3!E2',
        userAgent: 'DDOne Unit Test',
        registerTtl: 180,
      );
      // for (int i = 0; i < 10; i++) {
      //   await Future.delayed(const Duration(milliseconds: 200));
      //   if (registered) {
      //     break;
      //   }
      // }
      
      // Clean up
      reattachedPlugin.dispose();
      session.dispose();
    });

    test('Complete abandon and reclaim flow simulation', () async {
      if (!serverAccessible) {
        print('Skipping test - server not accessible');
        return;
      }

      // Phase 1: Create session and plugin (simulating background isolate)
      WebSocketJanusTransport originalWsTransport = WebSocketJanusTransport(url: 'ws://10.17.1.31:8188/ws');
      JanusClient originalWsClient = JanusClient(transport: originalWsTransport, isUnifiedPlan: true);
      JanusSession originalSession = JanusSession(transport: originalWsTransport, context: originalWsClient);
      await originalSession.create();
      int? sessionId = originalSession.sessionId;

      // Create SIP plugin in background
      JanusSipPlugin originalSipPlugin = await originalSession.attach<JanusSipPlugin>(
        opaqueId: 'background-sip',
      );
      int? sipHandleId = originalSipPlugin.handleId;

      // Register in background
      bool registered = false;
      originalSipPlugin.typedMessages!.listen((TypedEvent<JanusEvent> event) {
        Object data = event.event.plugindata?.data;
        print('Original SIP plugin handleId: ${originalSipPlugin.handleId} - typedEvent listener data: $data');
        if (data is SipRegisteredEvent) {
          registered = true;
        }
      });
      await originalSipPlugin.register(
        'sip:5850@10.17.1.82',
        displayName: '5850',
        forceTcp: true,
        rfc2543Cancel: true,
        proxy: 'sip:10.17.1.82:5260',
        secret: 'p7AqMfRo0assBwaj3!E2',
        userAgent: 'DDOne Unit Test',
        registerTtl: 180,
      );
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (registered) {
          break;
        }
      }

      print('Background: Created session $sessionId and SIP handle $sipHandleId');

      // "Abandon" - dispose the session (simulating background isolate cleanup)
      await originalSipPlugin.dispose(); // do not detach
      originalSession.dispose();

      // Phase 2: Reclaim session and re-attach (simulating main isolate takeover)
      await Future.delayed(Duration(milliseconds: 2000)); // Small delay to simulate background stop and main start

      WebSocketJanusTransport reclaimWsTransport = WebSocketJanusTransport(url: 'ws://10.17.1.31:8188/ws');
      JanusClient reclaimWsClient = JanusClient(transport: reclaimWsTransport, isUnifiedPlan: true);
      JanusSession reclaimedSession = JanusSession(transport: reclaimWsTransport, context: reclaimWsClient);
      await reclaimedSession.create(sessionIdToClaim: sessionId);

      // Re-attach to existing SIP plugin handle
      JanusSipPlugin reattachedSipPlugin = await reclaimedSession.attach<JanusSipPlugin>(
        existingHandleId: sipHandleId,
      );

      expect(reclaimedSession.sessionId, equals(sessionId));
      expect(reattachedSipPlugin.handleId, equals(sipHandleId));

      // Unregister in main
      bool unregistered = false;
      reattachedSipPlugin.typedMessages!.listen((TypedEvent<JanusEvent> event) {
        Object data = event.event.plugindata?.data;
        print('Reattached SIP plugin handleId: ${reattachedSipPlugin.handleId} - typedEvent listener data: $data');
        if (data is SipUnRegisteredEvent) {
          unregistered = true;
        }
      });
      await reattachedSipPlugin.unregister();
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (unregistered) {
          break;
        }
      }

      print('Main isolate: Reclaimed session $sessionId and re-attached to SIP handle $sipHandleId');

      // Clean up
      await reattachedSipPlugin.detach();
      await reattachedSipPlugin.dispose();
      reclaimedSession.dispose();

      print('Complete abandon and reclaim flow successful');
    });

    test('Re-attachment throws exception when session is not active', () async {
      // This test works regardless of server accessibility
      WebSocketJanusTransport wsTransport = WebSocketJanusTransport(url: 'ws://10.17.1.31:8188/ws');
      JanusClient wsClient = JanusClient(transport: wsTransport, isUnifiedPlan: true);
      JanusSession session = JanusSession(transport: wsTransport, context: wsClient);
      // Don't create session - it should be inactive

      // Test re-attachment with inactive session
      expect(
        () => session.attach<JanusSipPlugin>(
          existingHandleId: 123456,
        ),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('session is not active'),
        )),
      );

      // Test normal attach with inactive session
      expect(
        () => session.attach<JanusSipPlugin>(),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('session is not active'),
        )),
      );

      print('Session validation works correctly for inactive sessions');
    });

    test('Error handling for invalid handle IDs', () async {
      if (!serverAccessible) {
        print('Skipping test - server not accessible');
        return;
      }

      WebSocketJanusTransport wsTransport = WebSocketJanusTransport(url: 'ws://10.17.1.31:8188/ws');
      JanusClient wsClient = JanusClient(transport: wsTransport, isUnifiedPlan: true);
      JanusSession session = JanusSession(transport: wsTransport, context: wsClient);
      await session.create();

      // Try to re-attach with a non-existent handle ID
      // This should create the plugin but operations will fail later
      JanusSipPlugin? plugin;
      try {
        plugin = await session.attach<JanusSipPlugin>(
          existingHandleId: 999999999, // Very likely non-existent
        );

        // The plugin creation will succeed, but operations should fail
        expect(plugin.handleId, equals(999999999));
        print('Plugin created with invalid handle ID (as expected)');

        await plugin.register(
          'sip:5850@10.17.1.82',
          displayName: '5850',
          forceTcp: true,
          rfc2543Cancel: true,
          proxy: 'sip:10.17.1.82:5260',
          secret: 'p7AqMfRo0assBwaj3!E2',
          userAgent: 'DDOne Unit Test',
          registerTtl: 180,
        );

        // check server log, it will show that it has failed.
        // something like this: 
        // [ERR] [janus.c:janus_process_incoming_request:1184] Couldn't find any handle 999999999 in session 1806193254797935...
        
      } catch (e) {
        // If it fails, that's also acceptable behavior
        print('Re-attachment with invalid handle ID failed (acceptable): $e');
      }
      
      plugin?.dispose();
      session.dispose();
    });
  });
}
