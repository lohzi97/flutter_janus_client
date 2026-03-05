import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:janus_client/janus_client.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const _devJanusWsUrl = 'ws://10.17.1.31:8188/ws';

class _RecordingWebSocketSink implements WebSocketSink {
  _RecordingWebSocketSink({required void Function() onClose}) : _onClose = onClose;

  final void Function() _onClose;
  final Completer<void> _doneCompleter = Completer<void>();
  final List<dynamic> added = <dynamic>[];

  bool _isClosed = false;

  @override
  Future<void> get done => _doneCompleter.future;

  @override
  void add(dynamic data) {
    if (_isClosed) throw StateError('sink closed');
    added.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_isClosed) throw StateError('sink closed');
  }

  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final value in stream) {
      add(value);
    }
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (_isClosed) return;
    _isClosed = true;
    _onClose();
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete();
    }
  }
}

class _TestWebSocketChannel extends StreamChannelMixin<dynamic> implements WebSocketChannel {
  _TestWebSocketChannel({required this.stream, required this.sink});

  @override
  final Stream<dynamic> stream;

  @override
  final WebSocketSink sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  Future<void> get ready => Future<void>.value();
}

class _ChannelHarness {
  _ChannelHarness() {
    sink = _RecordingWebSocketSink(onClose: () {
      incomingController.close();
    });
    channel = _TestWebSocketChannel(stream: incomingController.stream, sink: sink);
  }

  final StreamController<dynamic> incomingController = StreamController<dynamic>(sync: true);
  late final _RecordingWebSocketSink sink;
  late final WebSocketChannel channel;
}

void main() {
  group('WebSocketJanusTransport.dispose() terminal lifecycle', () {
    test('dispose suppresses reconnect even if stream closes (onDone)', () {
      fakeAsync((async) {
        final created = <_ChannelHarness>[];
        final ws = WebSocketJanusTransport(
          url: _devJanusWsUrl,
          autoReconnect: true,
          channelFactory: (uri, {protocols}) {
            final harness = _ChannelHarness();
            created.add(harness);
            return harness.channel;
          },
        );

        ws.connect();
        expect(created.length, 1);

        ws.dispose();

        async.elapse(const Duration(seconds: 30));
        expect(created.length, 1);
      });
    });

    test('dispose cancels a pending reconnect timer', () {
      fakeAsync((async) {
        final created = <_ChannelHarness>[];
        final ws = WebSocketJanusTransport(
          url: _devJanusWsUrl,
          autoReconnect: true,
          channelFactory: (uri, {protocols}) {
            final harness = _ChannelHarness();
            created.add(harness);
            return harness.channel;
          },
        );

        ws.connect();
        expect(created.length, 1);

        created.single.incomingController.close();
        async.flushMicrotasks();

        ws.dispose();
        async.elapse(const Duration(seconds: 30));
        expect(created.length, 1);
      });
    });

    test('heartbeat stops after dispose (no more ping writes)', () {
      fakeAsync((async) {
        final created = <_ChannelHarness>[];
        final ws = WebSocketJanusTransport(
          url: _devJanusWsUrl,
          autoReconnect: false,
          heartbeatInterval: const Duration(milliseconds: 100),
          channelFactory: (uri, {protocols}) {
            final harness = _ChannelHarness();
            created.add(harness);
            return harness.channel;
          },
        );

        ws.connect();
        final sink = created.single.sink;

        async.elapse(const Duration(milliseconds: 350));
        final beforeDispose = sink.added.length;
        expect(beforeDispose, greaterThan(0));

        ws.dispose();

        async.elapse(const Duration(seconds: 2));
        expect(sink.added.length, beforeDispose);
      });
    });
  });
}
