import 'dart:async';

import 'package:surrealdb_client/src/emitter.dart';
import 'package:surrealdb_client/src/pinger.dart';
import 'package:universal_io/io.dart';

enum SocketState { opened, closed }

/// WebSocket wrapper with connection persistance
/// mechanism.
class Socket extends Emitter {
  final String _url;
  bool _closed = false;
  SocketState _socketState = SocketState.closed;
  WebSocket? _ws;
  StreamSubscription? _wsSub;
  Reviver? _reviver;

  late Completer _readyCompleter;
  Future<void> get ready => _readyCompleter.future;

  Socket(String url)
      : _url = url
            .replaceFirst('http://', 'ws://')
            .replaceFirst('https://', 'ws://') {
    _init();
  }

  void _init() {
    _readyCompleter = Completer();
  }

  Future<void> open() async {
    try {
      _ws = await WebSocket.connect(_url);
      _reviver?.stop();
    } catch (_) {
      return;
    }
    _socketState = SocketState.opened;
    emit('open', null);

    _wsSub = _ws!.listen((event) {
      emit('message', event);
    }, onError: (event) {
      emit('error', event);
    }, onDone: () {
      emit('close', null);

      // If the WebSocket connection with the
      // database was disconnected, then we need
      // to reset the ready promise.
      if (_socketState == SocketState.opened) {
        _init();
      }

      // When the WebSocket is opened or closed
      // then we need to store the connection
      // status within the status property.
      _socketState = SocketState.closed;

      // If the connection is closed, then we
      // need to attempt to reconnect on a
      // regular basis until we are successful.
      if (!_closed) {
        _reviver?.stop();
        _reviver = Reviver();
        _reviver?.start(() => open());
      }
    });

    _readyCompleter.complete();
  }

  void send(dynamic data) {
    _ws?.add(data);
  }

  Future<void> close({
    int code = 1000,
    String reason = '',
  }) async {
    _closed = true;
    _reviver?.stop();
    _wsSub?.cancel();
    await _ws?.close(code, reason);
  }
}
